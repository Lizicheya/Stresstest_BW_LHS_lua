-- 沙盘(世界地图)场景业务处理
-- 对应 Python PressureTest_BW_LHS/pythonTest1/modules/scene/scene_task.py 的 SceneTask
--
-- ============================ 与 Python 版的关系 ============================
-- Python 版是「同步一问一答」模型:每个方法内部 SendAndRecv,拿到结果继续往下走。
-- 本项目 wrk 是「事件驱动」模型:一次只能产出一个请求,响应回来后再推进。
-- 因此本文件的移植策略是:
--   1) 每个动作函数只构造一个请求,返回 (协议名, 参数字表);
--      由上层状态机 sproto_client.writeable() 编码发送,契约与
--      pressure/task_manager.lua 的 generate_request 完全一致;
--   2) 响应由 on_response(proto, result, err) 消费,更新场景状态
--      (进场景标记、findSceneObj 命中缓存、部队登记、迁城成功坐标等);
--   3) Python 里的 while 循环流程(addMonsterTroopTimes / addResTroopTimes 等)
--      拆成 step_xxx 单步函数,由任务调度或 xlsx 用例反复驱动,
--      不在状态机里阻塞睡眠;
--   4) 状态按连接隔离:每个 sync_data 一个 SceneTask 实例(弱引用表登记),
--      多账号并发互不干扰。
--
-- ============================ 数据结构来源 ============================
-- world.scenes / castleX / castleY、armys、heros、buildings、troops、
-- lordKillNormalMonsterStat 均来自 s2c 推送(syncLoginData 全量 + syncPlayerInfo 增量),
-- 由 sync/sync_data.lua 落地;本文件取值时统一走兜底函数,字段缺失不报错,
-- 而是退回 scene_def.DEFAULT 的默认值。

local def = require "scene.scene_def"
local util = require "util"

local ERR          = def.ERR
local OBJ_TYPE     = def.OBJ_TYPE
local STATUS       = def.SceneObjStatusType
local ADD_TROOP    = def.AddTroopType
local DEFAULT      = def.DEFAULT

local M = {}

-- 详细日志开关:压测正式跑时保持 false,排障时置 true
M.verbose = false

local function logf(fmt, ...)
    if not M.verbose then return end
    print("[scene] " .. string.format(fmt, ...))
end

----------------------------------------------------------------------
-- 内部工具
----------------------------------------------------------------------

-- 安全取整:nil / 数字字符串 / 浮点 都归一成 Lua 整数
local function as_int(v, default)
    if v == nil then return default end
    if type(v) == "string" then v = tonumber(v) end
    if type(v) ~= "number" then return default end
    return math.floor(v + 0.5)
end

-- 安全取布尔(容忍 "true"/1 之类的 xlsx 写法)
local function as_bool(v, default)
    if v == nil then return default end
    if type(v) == "boolean" then return v end
    if type(v) == "number" then return v ~= 0 end
    if type(v) == "string" then
        local s = string.lower(v)
        if s == "true" or s == "1" then return true end
        if s == "false" or s == "0" then return false end
    end
    return default
end

-- 随机区间取整(lo > hi 时自动交换,避免 math.random 抛错)
local function rand_between(lo, hi)
    lo, hi = as_int(lo, 0), as_int(hi, 0)
    if lo > hi then lo, hi = hi, lo end
    return util.rand_int(lo, hi)
end

-- 取世界信息(优先 sync_data.world,退化到登录全量数据)
local function get_world(sync_data)
    if not sync_data then return nil end
    if type(sync_data.world) == "table" and next(sync_data.world) then
        return sync_data.world
    end
    local login = sync_data.login_info
    if type(login) == "table" and type(login.world) == "table" then
        return login.world
    end
    return sync_data.world
end

-- 取建筑等级:对应 Python sync_data.get_building_info(build_id, sub_index)
-- buildId 规则:buildCfgId * 10 + subIndex,例如主堡 100 -> 1001
local function building_lv(sync_data, build_id, sub_index)
    build_id = as_int(build_id, DEFAULT.castle_build_id)
    sub_index = as_int(sub_index, 1)
    if build_id == 158 then build_id = 118 end

    if sync_data and type(sync_data.get_building_lv) == "function" then
        return sync_data:get_building_lv(build_id, sub_index)
    end

    local buildings = (sync_data and sync_data.buildings) or {}
    local idx = tonumber(tostring(build_id) .. tostring(sub_index))
    local b = idx and buildings[idx] or nil
    if not b and type(buildings) == "table" then
        for _, item in pairs(buildings) do
            if type(item) == "table" and item.buildCfgId == build_id then
                b = item
                break
            end
        end
    end
    if type(b) ~= "table" then return -1 end
    return as_int(b.lv or b.level, -1)
end

-- 取当前可打怪最高等级:对应 Python sync_data.get_max_kill_monster()
-- 规则:已击杀最高等级 + 1,上限 30;无数据时为 1
local function max_kill_monster_lv(sync_data)
    if sync_data and type(sync_data.get_max_kill_monster) == "function" then
        return sync_data:get_max_kill_monster()
    end
    local stat = (sync_data and sync_data.lord_kill_monster_stat) or {}
    local max_lv = 0
    for k in pairs(stat) do
        local lv = as_int(k, 0)
        if lv > max_lv then max_lv = lv end
    end
    if max_lv <= 0 then return 1 end
    max_lv = max_lv + 1
    if max_lv > 30 then max_lv = 30 end
    return max_lv
end

-- 取服务器开服天数:对应 Python sync_data.cur_server_day
local function server_day(sync_data)
    if sync_data and type(sync_data.get_server_day) == "function" then
        return sync_data:get_server_day()
    end
    return 1
end

----------------------------------------------------------------------
-- 构造与实例登记
----------------------------------------------------------------------

local SceneTask = {}
SceneTask.__index = SceneTask
M.SceneTask = SceneTask

-- 按 sync_data 登记实例(弱引用 key:sync_data 被回收时实例随之释放)
local ctx_by_sync = setmetatable({}, { __mode = "k" })

----------------------------------------------------------------------
-- 构造一个场景上下文
-- sync_data: 连接级数据缓存(sync.sync_data 实例)
-- opts: 可选
--   castle_x / castle_y    初始主堡坐标
--   on_wait                触达服务器等级上限时的回调(可接 cheat 改时间)
--   resolve_target_by_uid  uid -> 场景对象id 的解析函数(Python lord_task.get_target_id_by_uid)
----------------------------------------------------------------------
function M.new(sync_data, opts)
    opts = opts or {}
    local self = setmetatable({}, SceneTask)

    self.sync_data = sync_data
    self.opts = opts

    -- ===== 以下字段与 Python SceneTask.__init__ 一一对应 =====
    self.monster_obj_id = def.MONSTER_CFG_BASE      -- 当前要打的怪配置 id
    self.boss_obj_id = DEFAULT.boss_obj_id          -- BOSS 配置 id
    self.res_obj_id = DEFAULT.res_obj_id            -- 资源点配置 id
    self.local_troop_can_speed_up = {}              -- 可加速队列
    self.enter_scene = false                        -- 是否已进入场景
    self.set_auto_rally = false                     -- 是否已设置自动集结
    self.monster_max_lv = 0                         -- 自身可打最高怪等级
    self.server_max_monster = 0                     -- 服务器开放的最高怪等级
    self.scenes = 0                                 -- 场景 id(每个王国不同)
    self.troop_max_queue = false                    -- 行军队列是否已满
    self.set_global_spro = false                    -- 是否已登记全局推送
    self.alliance_build_target_id = DEFAULT.alliance_build_target_id
    self.last_check_time = 0                        -- 上次部队校验时间
    self.check_interval_time = DEFAULT.check_interval_time
    self.set_aoi = false                            -- 是否已设置 aoi(真正进了场景)
    self.move_medium_pos = false                    -- 是否已迁到中级资源区
    self.move_high_pos = false                      -- 是否已迁到高级资源区

    -- ===== 事件驱动补充状态 =====
    self.castle_x = as_int(opts.castle_x, 0)
    self.castle_y = as_int(opts.castle_y, 0)
    self.found = nil                -- 最近一次 findSceneObj 命中对象
    self.flow_target = nil          -- 当前出征流程的目标
    self.speed_up_queue = {}        -- 待加速部队 id 队列
    self.move_times_left = 0        -- 迁城剩余次数
    self.pending_move = nil         -- 在途迁城坐标(用于回包成功后更新本地坐标)
    self.pending_move_purpose = nil -- 在途迁城用途:"medium"/"high"/"normal"
    self.wait_until = 0             -- 等待解锁时间戳
    self.global_sync_pro_list = {}  -- 期望的全局推送协议名(登记/排障用)
    self.global_sync_key_list = {}  -- 期望的全局推送键
    self.stats = {                  -- 业务统计(便于压测后对账)
        find = 0, attack = 0, collect = 0,
        speed_up = 0, move = 0, fail = 0,
    }

    -- 初始主堡坐标:同步数据里没有时用 world.castleX/Y 补齐
    self:refresh_castle_pos()
    return self
end

----------------------------------------------------------------------
-- 取(或创建)某个连接的场景上下文
----------------------------------------------------------------------
function M.get(sync_data, opts)
    if not sync_data then return nil end
    local ctx = ctx_by_sync[sync_data]
    if not ctx then
        ctx = M.new(sync_data, opts)
        ctx_by_sync[sync_data] = ctx
    end
    return ctx
end

-- 丢弃某连接的场景上下文(重新登录/账号轮换时调用)
function M.reset(sync_data)
    if sync_data then ctx_by_sync[sync_data] = nil end
end

----------------------------------------------------------------------
-- 等待控制
----------------------------------------------------------------------

-- 是否处于等待中(打怪等级超过服务器开放上限时置位)
function SceneTask:is_waiting()
    return self.wait_until > 0 and os.time() < self.wait_until
end

-- 等待到次日:对应 Python findSceneObjMonster 里的
-- heart_task.change_server_time(86400) + "please wait"
-- 本项目不在此处阻塞发 HTTP:通过 opts.on_wait 交给上层决定(可接 cheat),
-- 未提供回调时仅本地等待,继续贡献连接层流量。
function SceneTask:wait_next_day(reason)
    self.wait_until = os.time() + DEFAULT.wait_next_day
    self.last_wait_reason = reason
    if self.opts.on_wait then
        pcall(self.opts.on_wait, self, reason)
    end
    logf("wait next day: %s", tostring(reason))
    return nil, { err = ERR.CAN_NOT_FIND_OBJ, reason = reason or "wait next day" }
end

----------------------------------------------------------------------
-- 场景进出
----------------------------------------------------------------------

-- 取 world.scenes
-- s2c 里是 `scenes 4: *ComIntInt()`(sproto map),解码结果为 { [sceneId] = sceneCfgId };
-- Python 侧的列表形态 [{key=,value=}] 也一并兼容
function SceneTask:scene_list()
    local world = get_world(self.sync_data)
    if not world then return {} end
    return world.scenes or {}
end

-- 取第一个场景 id(sceneId 是服务端场景 id,用于 enterScene)
function SceneTask:first_scene_id()
    local scenes = self:scene_list()
    for _, item in ipairs(scenes) do
        if type(item) == "table" and item.key then return item.key end
    end
    -- map 形态:scenes[sceneId] = sceneCfgId
    for k in pairs(scenes) do
        if type(k) == "number" and k > 0 then return k end
    end
    return nil
end

-- 由场景配置 id(sceneCfgId)反查场景 id,对应 Python get_scene_id
function SceneTask:get_scene_id(target_map)
    local scenes = self:scene_list()
    for _, item in ipairs(scenes) do
        if type(item) == "table" and item.value == target_map then return item.key end
    end
    for k, v in pairs(scenes) do
        if v == target_map then return k end
    end
    logf("scene cfg %s not found in world.scenes", tostring(target_map))
    return 0
end

-- 进入场景:enterScene 46
-- 注意:方法名不能叫 enter_scene —— 与本类字段 self.enter_scene(是否已进场景)冲突,
-- 会被字段值(boolean)遮蔽导致调用报错,故命名为 do_enter_scene
-- 注意:进入结果由 on_response 判定,失败时下一轮会重新取场景 id
function SceneTask:do_enter_scene()
    if self.enter_scene then return nil end
    if self.scenes == 0 then
        local scene_id = self:first_scene_id()
        if not scene_id then
            return nil, { err = ERR.NOT_FOUND, reason = "world.scenes 为空,登录同步未就绪" }
        end
        self.scenes = scene_id
    end
    logf("enterScene sceneId=%s", tostring(self.scenes))
    return "enterScene", { sceneId = self.scenes }
end

-- 退出场景:quitScene 47
function SceneTask:quit_scene()
    return "quitScene", {}
end

-- 设置 aoi 位置:setAoiPos 43
-- 与 Python 一致:请求里 x/y 固定传 0,主堡坐标只用于本地缓存
function SceneTask:set_aoi_pos(x, y)
    self.castle_x = as_int(x, self.castle_x)
    self.castle_y = as_int(y, self.castle_y)
    return "setAoiPos", {
        x = 0,
        y = 0,
        lod = 1,
        sceneId = self.scenes or 0,
    }
end

-- 首次设置 aoi(Python setAoiPosFirst):
-- 未进场景 -> 先 enterScene;已进场景 -> 发 setAoiPos
-- 主堡等级不足时跳过(等级取不到 -1 时不拦,对应 Python 注释掉的主堡等级判断)
function SceneTask:set_aoi_pos_first()
    if self.set_aoi then return nil end
    if self:is_waiting() then return nil end

    local castle_lv = building_lv(self.sync_data, DEFAULT.castle_build_id)
    if castle_lv >= 0 and castle_lv < DEFAULT.castle_lv_min then
        logf("castle_lv %d < %d, skip scene", castle_lv, DEFAULT.castle_lv_min)
        return nil, { err = ERR.LOWER_CASTLE_LV, reason = "castle level too low" }
    end

    if not self.enter_scene then
        local proto, args = self:do_enter_scene()
        if proto then return proto, args end
        if args and args.err then return nil, args end
    end

    self:refresh_castle_pos()
    return self:set_aoi_pos(self.castle_x, self.castle_y)
end

-- 场景动作统一前置:未进场景(或 aoi 未就绪)时先补 enterScene / setAoiPos
-- 返回 (nil) 表示已在场景内,可继续发业务请求;
-- 返回 (proto, args) 表示本步应发这个前置请求;
-- 返回 (nil, {err=..}) 表示前置条件不满足(如主堡等级不足),本步跳过。
function SceneTask:ensure_scene()
    if self.set_aoi then return nil end
    return self:set_aoi_pos_first()
end

-- 刷新主堡坐标(world.castleX / castleY)
function SceneTask:refresh_castle_pos()
    local world = get_world(self.sync_data)
    if type(world) == "table" then
        self.castle_x = as_int(world.castleX, self.castle_x or 0)
        self.castle_y = as_int(world.castleY, self.castle_y or 0)
    end
    return self.castle_x, self.castle_y
end

----------------------------------------------------------------------
-- 服务器开放怪等级(对应 Python get_max_monster_lv)
----------------------------------------------------------------------
function SceneTask:get_max_monster_lv()
    local day = server_day(self.sync_data)
    local map = def.SERVER_MAX_MONSTER
    for _, need_day in ipairs(def.server_max_monster_keys) do
        if day >= need_day then return map[need_day] end
    end
    return nil
end

----------------------------------------------------------------------
-- 场景对象搜索
----------------------------------------------------------------------

-- 搜索普通怪:findSceneObj 48,objType 131
-- monster_lv 传 0/nil 表示「打当前可打的最高等级」
function SceneTask:find_scene_obj_monster(monster_lv, obj_ids)
    if self:is_waiting() then return nil end

    monster_lv = as_int(monster_lv, 0)
    self.server_max_monster = self:get_max_monster_lv() or 0
    self.monster_max_lv = max_kill_monster_lv(self.sync_data)

    local lv
    if monster_lv > 0 then
        -- 目标等级不超过自身可打等级
        lv = (monster_lv <= self.monster_max_lv) and monster_lv or self.monster_max_lv
    else
        lv = self.monster_max_lv
    end
    if lv < 1 then lv = 1 end
    self.monster_obj_id = def.MONSTER_CFG_BASE + lv - 1

    -- 目标等级超过服务器开放上限:不是错误,等服务器开放
    if monster_lv > 0 and monster_lv > self.server_max_monster then
        return self:wait_next_day(string.format(
            "monster_lv %d > server_max %d", monster_lv, self.server_max_monster))
    end

    logf("findSceneObj monster cfg=%d (lv=%d, self_max=%d, server_max=%d)",
        self.monster_obj_id, lv, self.monster_max_lv, self.server_max_monster)

    return "findSceneObj", {
        objType = OBJ_TYPE.MONSTER,
        objCfgId = self.monster_obj_id,
        isFullRes = false,
        isIncludeOccupyRes = false,
        isRadar = false,
        objIds = obj_ids or {},
    }
end

-- 搜索 pvp 目标(个人 pvp 副本),对应 Python findSceneObjMonsterPvp
-- pvp_type: 1 积分怪 2 侦察 3 城堡(按积分等级) 4 其他城堡
function SceneTask:find_scene_obj_monster_pvp(pvp_type)
    pvp_type = as_int(pvp_type, 0)
    if pvp_type <= 0 then pvp_type = util.rand_int(1, 4) end

    local score_lv = util.rand_int(1, 3)
    local obj_id, obj_type
    if pvp_type == 1 then
        obj_id, obj_type = 13001 + score_lv - 1, OBJ_TYPE.MONSTER
    elseif pvp_type == 2 then
        obj_id, obj_type = 13, OBJ_TYPE.BUILDING
    elseif pvp_type == 3 then
        if score_lv == 1 then
            obj_id, obj_type = 11, OBJ_TYPE.PVP_BUILD
        elseif score_lv == 2 then
            obj_id, obj_type = 7, OBJ_TYPE.PVP_BUILD
        else
            obj_id, obj_type = 2, OBJ_TYPE.PVP_BUILD
        end
    else
        obj_id, obj_type, score_lv = 12, OBJ_TYPE.PVP_BUILD, 4
    end

    return "findSceneObj", {
        objType = obj_type,
        objCfgId = obj_id,
        isFullRes = false,
        isIncludeOccupyRes = false,
        isRadar = false,
        objIds = {},
        scoreResourceLv = score_lv,
    }
end

-- 搜索 BOSS:findSceneObj 48,objType 132
function SceneTask:find_scene_obj_boss(boss_obj_id, obj_ids)
    if boss_obj_id then
        self.boss_obj_id = as_int(boss_obj_id, self.boss_obj_id)
    end
    return "findSceneObj", {
        objType = OBJ_TYPE.BOSS,
        objCfgId = self.boss_obj_id,
        isFullRes = false,
        isIncludeOccupyRes = false,
        isRadar = false,
        objIds = obj_ids or {},
    }
end

-- 搜索资源点:findSceneObj 48,objType 2
-- 30001农场 30011伐木场 30021岩石矿 30031金币矿
function SceneTask:find_scene_obj_res(res_obj_id)
    if res_obj_id then
        self.res_obj_id = as_int(res_obj_id, self.res_obj_id)
    end
    return "findSceneObj", {
        objType = OBJ_TYPE.RES,
        objCfgId = self.res_obj_id,
        isIncludeOccupyRes = false,
        isRadar = false,
        objIds = {},
    }
end

-- 对象详情:getObjDetailInfo 55(主要用于查询建筑类对象)
function SceneTask:get_obj_detail_info(obj_id)
    return "getObjDetailInfo", { objId = obj_id }
end

-- 据点列表:getBuffHoldList 60
function SceneTask:get_buff_hold_list()
    return "getBuffHoldList", {}
end

-- 设置自动加入集结:setAutoRallyInfo 59
function SceneTask:set_auto_rally_info(is_open)
    is_open = as_bool(is_open, true)
    self.set_auto_rally = true
    return "setAutoRallyInfo", {
        isOpen = is_open,
        addTroopType = 0,
        selectedBoss = DEFAULT.auto_rally_boss,
    }
end

----------------------------------------------------------------------
-- 出征部队组建
-- 对应 Python army_task.set_troop_army_random_info / hero_task.set_troop_hero_info
----------------------------------------------------------------------

-- 取兵种表:cfgId -> 数量
local function army_table(sync_data)
    local out = {}
    local armys = (sync_data and sync_data.armys) or {}
    if type(armys) ~= "table" then return out end
    for k, v in pairs(armys) do
        local cfg_id = as_int(k, 0)
        local num = 0
        if type(v) == "table" then
            num = as_int(v.num or v.value, 0)
        else
            num = as_int(v, 0)
        end
        if cfg_id > 0 and num > 0 then out[cfg_id] = num end
    end
    return out
end

-- 带兵上限:优先属性表(attribute key -> value),取不到用默认值
function SceneTask:get_troop_capacity(troop_type)
    local is_collect = (troop_type == ADD_TROOP.COLLECT)
    local attr_id = is_collect and DEFAULT.attr_capacity_res or DEFAULT.attr_capacity_battle

    if attr_id and attr_id > 0 then
        local attr = self.sync_data and self.sync_data.attributes
        local v = as_int(type(attr) == "table" and attr[attr_id] or nil, 0)
        if v > 0 then return v end
    end

    if is_collect then return DEFAULT.capacity_res end
    return DEFAULT.capacity_battle
end

-- 随机组兵:按兵种数量从多到少取若干种,各按上限三等分带兵
-- 对应 Python set_troop_army_random_info
--
-- ⚠ 编码形态:c2s.sproto 里 army 是 `*ComArmyIdAndNum()`,空括号 = sproto 的
-- 「map」声明(sprotoparser 把 key=="" 的数组字段标成 map,key 取最小 tag 的字段),
-- 因此 Lua 侧必须是 { [armyCfgId] = num } 这种纯映射表;写成 {{id=..,num=..}}
-- 会被 C 编码器当成 map 的 entry 表,报 ".num[0] is not an integer (Is a table)"。
function SceneTask:build_army_info(troop_type, opts)
    opts = opts or {}
    troop_type = troop_type or ADD_TROOP.BATTLE

    local armys = army_table(self.sync_data)
    local list = {}
    for cfg_id, num in pairs(armys) do
        list[#list + 1] = { id = cfg_id, num = num }
    end
    table.sort(list, function(a, b) return a.num > b.num end)

    local kind = as_int(opts.army_kind, DEFAULT.army_kind)
    if kind < 1 then kind = 1 end
    local capacity = as_int(opts.total_capacity, self:get_troop_capacity(troop_type))

    local out = {}
    for i = 1, math.min(kind, #list) do
        local item = list[i]
        local quota = math.floor(capacity / kind)
        -- 士兵数应为带兵上限三等分后数量与玩家拥有数量取最小
        local num = math.min(quota, item.num)
        -- 了避免把配额用满，给后续逻辑留缓冲  -- 与 Python 一致:留 5 个余量,至少 1
        num = math.max(num - 5, 1)
        -- 以物品 id 为键，把最终分配数量写入结果表 out
        -- 最终 out 形如 { [id1] = 328, [id2] = 328, [id3] = 328 }
        out[item.id] = num
    end

    if next(out) == nil then
        -- 无兵种数据(登录同步未就绪):退回 Python addTroop_monster 的固定兵种
        out = util.deepcopy(DEFAULT.fallback_army)
        logf("build_army_info fallback to default army")
    end
    return out
end

-- 随机取英雄出征:c2s.sproto 中 heros 同样是 map 形态 `*ComUint32Uint32()`
-- 语义:[出征槽位(1 起)] = 英雄配置 id → Lua 侧写 { [slot] = heroCfgId }
function SceneTask:build_hero_info(troop_type, count)
    local heros = (self.sync_data and self.sync_data.heros) or {}
    local ids = {}
    -- 构造英雄列表
    for cfg_id in pairs(heros) do
        local v = as_int(cfg_id, 0)
        -- 只保留正整数 ID，追加到 ids 末尾。#ids + 1 是 Lua 标准的数组追加写法
        if v > 0 then ids[#ids + 1] = v end
    end
    if #ids == 0 then return nil end

    -- 洗牌后取前 N 个(等价 Python random.sample 不重复)
    for i = #ids, 2, -1 do
        local j = util.rand_int(1, i)
        ids[i], ids[j] = ids[j], ids[i]
    end
    -- 设置出征英雄数
    count = as_int(count, DEFAULT.hero_count)

    -- 保底，防止玩家拥有英雄数量小于默认出征英雄数量
    if count > #ids then count = #ids end
    if count < 1 then count = 1 end

    local out = {}
    --设置每个英雄的出征槽位
    --把 ids 第 i 个元素赋给 out 第 i 个元素
    for i = 1, count do
        out[i] = ids[i]
    end
    return out
end

----------------------------------------------------------------------
-- 出征:addTroop 41
----------------------------------------------------------------------

-- 组装 addTroop 请求
-- opts:
--   army        出征兵种列表 *ComArmyIdAndNum
--   heros       英雄列表 *ComUint32Uint32(可为 nil)
--   target_id   目标场景对象 id
--   target_x/y  目标坐标(可选,double)
--   is_rally    是否发起集结
--   rally_index 集结准备时间索引
--   is_radar    是否雷达部队
--   formation_id 编队 id(默认 1)
function SceneTask:add_all_troop(opts)
    opts = opts or {}

    -- 主堡等级门槛:等级取不到(-1)时不拦,避免登录同步不全导致场景任务全废
    local castle_lv = building_lv(self.sync_data, DEFAULT.castle_build_id)
    if castle_lv >= 0 and castle_lv < DEFAULT.castle_lv_min then
        return nil, { err = ERR.LOWER_CASTLE_LV,
                      reason = "castle_lv " .. tostring(castle_lv) }
    end

    self:set_scene_global_sync()

    local is_rally = as_bool(opts.is_rally, false)
    local is_radar = as_bool(opts.is_radar, false)
    local target_id = opts.target_id
    local target_x = opts.target_x
    local target_y = opts.target_y

    local msg = {
        army = opts.army,
        heros = opts.heros,
        isAutoBack = true,
        formationId = as_int(opts.formation_id, 1),
    }

    if target_id then msg.targetId = target_id end
    if is_rally then
        msg.isRally = true
        msg.rallyReadyMinutesIndex = as_int(opts.rally_index, DEFAULT.rally_index)
    end
    if is_radar then msg.isRadar = true end
    if target_x and target_y then
        -- targetX/targetY 在 sproto 中是 double,显式转浮点避免整数编码歧义
        msg.targetX = target_x + 0.0
        msg.targetY = target_y + 0.0
    end

    -- 空表不下发:sproto 对空 *Type 编码无意义且增大报文
    if type(msg.army) ~= "table" or next(msg.army) == nil then msg.army = nil end
    if type(msg.heros) ~= "table" or next(msg.heros) == nil then msg.heros = nil end

    return "addTroop", msg
end

-- 派兵打怪:对应 Python addMonsterTroop
-- 无目标时自动先搜索(与 Python 内部先 findSceneObjMonster 一致)
function SceneTask:add_monster_troop(opts)
    opts = opts or {}

    local target_id = opts.target_id
    local target_x, target_y = opts.target_x, opts.target_y

    if not target_id then
        local f = self.found
        if f and f.obj_type == OBJ_TYPE.MONSTER then
            target_id, target_x, target_y = f.id, f.x, f.y
        end
    end
    if not target_id then
        return self:find_scene_obj_monster(opts.monster_lv, opts.obj_ids)
    end

    local troop_type = as_int(opts.troop_type, ADD_TROOP.BATTLE)
    --设置出征编队的士兵，如果有传入数则使用传入数据；
    --若没有传入数据，则使用随机组合士兵逻辑
    local army = opts.army or self:build_army_info(troop_type, opts)
    local heros = opts.heros
    if heros == nil then
        -- 雷达部队不带英雄(对应 Python is_radar -> hero_info = {})
        if not as_bool(opts.is_radar, false) then
            --设置出征编队的英雄组合，如果有传入数则使用传入数据；
            --若没有传入数据，则使用随机组合英雄逻辑
            heros = self:build_hero_info(troop_type)
        end
    end

    self.flow_target = { id = target_id, x = target_x, y = target_y, kind = "monster" }
    logf("addMonsterTroop target=%s", tostring(target_id))

    return self:add_all_troop({
        army = army,
        heros = heros,
        target_id = target_id,
        target_x = target_x,
        target_y = target_y,
        is_rally = opts.is_rally,
        rally_index = opts.rally_index,
        is_radar = opts.is_radar,
        formation_id = opts.formation_id,
    })
end

-- 采集资源:对应 Python addResTroop(troop_type = 2)
-- 无目标时自动先搜索资源点
function SceneTask:add_res_troop(res_obj_id, opts)
    opts = opts or {}

    local target_id = opts.target_id
    local target_x, target_y = opts.target_x, opts.target_y

    if not target_id then
        local f = self.found
        if f and f.obj_type == OBJ_TYPE.RES then
            target_id, target_x, target_y = f.id, f.x, f.y
        end
    end
    if not target_id then
        return self:find_scene_obj_res(res_obj_id)
    end

    local army = opts.army or self:build_army_info(ADD_TROOP.COLLECT, opts)
    local heros = opts.heros
    if heros == nil then heros = self:build_hero_info(ADD_TROOP.COLLECT) end

    self.flow_target = { id = target_id, x = target_x, y = target_y, kind = "res" }
    self.stats.collect = self.stats.collect + 1
    logf("addResTroop target=%s", tostring(target_id))

    -- 采集不集结、不走雷达
    return self:add_all_troop({
        army = army,
        heros = heros,
        target_id = target_id,
        target_x = target_x,
        target_y = target_y,
    })
end

-- 攻打玩家城堡:对应 Python addCastleTroop
-- target_uid 需要 opts.resolve_target_by_uid 才能解析成场景对象 id
function SceneTask:add_castle_troop(opts)
    opts = opts or {}
    local target_id = opts.target_id

    if not target_id and opts.target_uid and self.opts.resolve_target_by_uid then
        target_id = self.opts.resolve_target_by_uid(self, opts.target_uid)
    end
    if not target_id then
        return nil, { err = ERR.NO_OBJ, reason = "target_id 缺失且无法由 uid 解析" }
    end

    local army = opts.army or self:build_army_info(ADD_TROOP.BATTLE, opts)
    local heros = opts.heros
    if heros == nil then heros = self:build_hero_info(ADD_TROOP.BATTLE) end

    self.flow_target = { id = target_id, kind = "castle" }
    return self:add_all_troop({
        army = army,
        heros = heros,
        target_id = target_id,
        is_rally = opts.is_rally,
        rally_index = opts.rally_index,
    })
end

-- 联盟目标派兵(据点/联盟矿):对应 Python addAllianceTroop
function SceneTask:add_alliance_troop(target_id, opts)
    opts = opts or {}
    target_id = target_id or opts.target_id
    if not target_id then
        return nil, { err = ERR.NO_OBJ, reason = "alliance target_id nil" }
    end

    local army = opts.army or self:build_army_info(ADD_TROOP.BATTLE, opts)
    local heros = opts.heros
    if heros == nil then heros = self:build_hero_info(ADD_TROOP.BATTLE) end

    self.flow_target = { id = target_id, kind = "alliance" }
    return self:add_all_troop({
        army = army,
        heros = heros,
        target_id = target_id,
        is_rally = opts.is_rally,
        rally_index = opts.rally_index,
    })
end

-- 侦察:addTroop 41,isScout = true
function SceneTask:add_scout_troop(target_id)
    if not target_id then
        return nil, { err = ERR.NO_OBJ, reason = "scout target nil" }
    end
    return "addTroop", { isScout = true, targetId = target_id }
end

----------------------------------------------------------------------
-- 部队加速:troopSpeedUp 50
----------------------------------------------------------------------

-- 刷新可加速部队列表(行军/回城/加入集结中的自家部队)
-- 对应 Python sync_data.troop_can_speed_up,本项目按 sync_data.troops 的状态现算
function SceneTask:refresh_speed_up_list()
    local list = {}
    local troops = (self.sync_data and self.sync_data.troops) or {}
    if type(troops) ~= "table" then
        self.local_troop_can_speed_up = list
        return list
    end

    for troop_id, info in pairs(troops) do
        if type(info) == "table" then
            local status = as_int(info.status or (info.troop and info.troop.status), 0)
            if status == STATUS.MARCHING
                or status == STATUS.BACK_CASTLE
                or status == STATUS.RALLY_JOINING then
                list[#list + 1] = as_int(info.id, as_int(troop_id, 0))
            end
        end
    end

    self.local_troop_can_speed_up = list
    return list
end

-- 入队一个待加速部队 id
function SceneTask:enqueue_speed_up(troop_id)
    troop_id = as_int(troop_id, 0)
    if troop_id > 0 then
        self.speed_up_queue[#self.speed_up_queue + 1] = troop_id
    end
end

-- 发一次加速请求;队列空时按可加速列表自动补充
-- 注意:Python troopSpeedUp(loop_times) 是同步循环 N 次,
-- 本项目每次只发一包,重复由任务调度驱动(避免在状态机里 sleep)
function SceneTask:next_speed_up()
    local troop_id = table.remove(self.speed_up_queue, 1)
    if not troop_id then
        local list = self:refresh_speed_up_list()
        troop_id = list[1]
    end
    if not troop_id then return nil end

    self.stats.speed_up = self.stats.speed_up + 1
    -- items2use 是 `*ComUint32Uint32()`(map 形态):[道具id] = 使用数量
    return "troopSpeedUp", {
        id = troop_id,
        items2use = { [DEFAULT.speed_up_item] = 1 },
    }
end

-- 加速指定部队(单包);troop_id 为空时用可加速列表第一个
function SceneTask:troop_speed_up(troop_id, loop_times)
    if troop_id then self:enqueue_speed_up(troop_id) end
    return self:next_speed_up()
end

-- 加速全部部队(队列满时的应急手段)
function SceneTask:speed_up_all_troop(loop_times)
    self:refresh_speed_up_list()
    for _, troop_id in ipairs(self.local_troop_can_speed_up) do
        self:enqueue_speed_up(troop_id)
    end
    return self:next_speed_up()
end

-- 随机加速一个部队
function SceneTask:speed_up_random_troop(loop_times)
    local list = self:refresh_speed_up_list()
    if #list == 0 then return nil end
    return self:troop_speed_up(list[util.rand_int(1, #list)])
end

-- 出征后顺手加速(对应 Python afterTroopSpeedUp)
function SceneTask:after_troop_speed_up()
    return self:speed_up_random_troop()
end

----------------------------------------------------------------------
-- 迁城:moveCastle 42
----------------------------------------------------------------------

-- 定点迁城,一次调用发一包
-- center_x/center_y 中心点,range_num 半径,move_times 剩余重试次数
function SceneTask:move_castle(center_x, center_y, range_num, move_times, purpose)
    center_x = as_int(center_x, DEFAULT.move_center_x)
    center_y = as_int(center_y, DEFAULT.move_center_y)
    range_num = as_int(range_num, DEFAULT.move_range)

    if self.move_times_left <= 0 then
        self.move_times_left = as_int(move_times, DEFAULT.move_times)
    end
    if self.move_times_left <= 0 then return nil end
    self.move_times_left = self.move_times_left - 1

    local pos_x = rand_between(center_x - range_num, center_x + range_num)
    local pos_y = rand_between(center_y - range_num, center_y + range_num)

    self.pending_move = { x = pos_x, y = pos_y }
    self.pending_move_purpose = purpose or "normal"
    self.stats.move = self.stats.move + 1

    return "moveCastle", {
        moveType = 1,
        x = pos_x,
        y = pos_y,
        -- resExchanges 同为 `*ComUint32Uint32()`(map):[道具id] = 数量
        resExchanges = { [DEFAULT.move_item] = 1 },
    }
end

----------------------------------------------------------------------
-- 部队校验(对应 Python troop_check)
-- 纯本地检查,不发协议:行军中的部队必须有 path,且未超时
----------------------------------------------------------------------
function SceneTask:troop_check()
    local now = os.time()
    if now - self.last_check_time < self.check_interval_time then return nil end
    self.last_check_time = now

    local problems = {}
    local troops = (self.sync_data and self.sync_data.troops) or {}
    local server_time = 0
    if self.sync_data and type(self.sync_data.get_server_time) == "function" then
        server_time = as_int(self.sync_data:get_server_time(), 0)
    end

    for troop_id, info in pairs(troops) do
        if type(info) == "table" then
            local status = as_int(info.status, 0)
            local troop = type(info.troop) == "table" and info.troop or {}
            if status == STATUS.MARCHING
                or status == STATUS.BACK_CASTLE
                or status == STATUS.RALLY_JOINING then
                local path = troop.path
                if type(path) ~= "table" or #path == 0 then
                    problems[#problems + 1] = string.format("troop_id:%s check path failed", tostring(troop_id))
                end
                local start_ts = as_int(troop.startWalkRateTS, 0)
                local total_ts = as_int(troop.initTotalTime, 0)
                if server_time > 0 and start_ts > 0 and (start_ts + total_ts) < server_time then
                    problems[#problems + 1] = string.format("troop_id:%s check time failed", tostring(troop_id))
                end
            end
        end
    end

    for _, p in ipairs(problems) do
        io.stderr:write("[scene] " .. p .. "\n")
    end
    if #problems > 0 then io.stderr:flush() end
    return problems
end

----------------------------------------------------------------------
-- 全局推送登记(对应 Python set_scene_global_sync)
-- 本项目 s2c 推送由服务端主动下发(sproto_client._handle_push 统一分发),
-- 无需向服务端声明订阅;此处仅保留登记,便于排障时核对期望的推送面
----------------------------------------------------------------------
function SceneTask:set_scene_global_sync()
    if self.set_global_spro then return end

    local pro_list, key_list = self.global_sync_pro_list, self.global_sync_key_list
    local function add_unique(list, value)
        for _, item in ipairs(list) do
            if item == value then return end
        end
        list[#list + 1] = value
    end

    add_unique(pro_list, "syncRemoveSelfTroop")
    add_unique(pro_list, "syncAddBattlePanelInfo")
    add_unique(pro_list, "syncAddSceneObj")
    add_unique(pro_list, "syncPlayerInfo")
    add_unique(key_list, "lordKillNormalMonsterStat")
    add_unique(key_list, "world")

    self.set_global_spro = true
end

----------------------------------------------------------------------
-- 响应处理:推进场景状态
-- proto_name 为本次请求的协议名,result 为解码后的响应体,err_code 为错误码
----------------------------------------------------------------------

-- 消费 findSceneObj 结果,缓存命中对象(供下一次 addTroop 使用)
function SceneTask:on_find_result(result, err_code)
    if err_code ~= ERR.SUCCESS then
        self.found = nil
        return
    end

    local objs = type(result) == "table" and result.objs or nil
    if type(objs) ~= "table" or #objs == 0 then
        self.found = nil
        logf("findSceneObj 命中 0 个对象")
        return
    end

    local obj = objs[1]
    self.found = {
        id = obj.id,
        x = obj.x,
        y = obj.y,
        cfg_id = obj.configId,
        obj_type = obj.type,
        status = obj.status,
        owner_id = obj.ownerId,
    }
    self.stats.find = self.stats.find + 1
    logf("findSceneObj 命中 id=%s type=%s cfg=%s (%s,%s)",
        tostring(obj.id), tostring(obj.type), tostring(obj.configId),
        tostring(obj.x), tostring(obj.y))
end

-- 消费 addTroop 结果
function SceneTask:on_add_troop_result(result, err_code)
    if err_code == ERR.SUCCESS then
        local troop_id = type(result) == "table" and (result.troopId or result.id) or nil
        if troop_id and self.sync_data and type(self.sync_data.add_check_troop) == "function" then
            -- 先登记一份最小部队信息,后续推送(syncAddSceneObj 等)会覆盖
            self.sync_data:add_check_troop(troop_id, {
                id = troop_id,
                status = STATUS.MARCHING,
            })
        end
        self.found, self.flow_target = nil, nil
        self.stats.attack = self.stats.attack + 1
        logf("addTroop ok troopId=%s", tostring(troop_id))

    elseif err_code == ERR.TROOP_MAX_QUEUE then
        -- 队列满:标记后由 step_attack_monster 优先加速腾队列
        self.troop_max_queue = true
        self.found, self.flow_target = nil, nil

    elseif err_code == ERR.NO_OBJ or err_code == ERR.CAN_NOT_FIND_OBJ
        or err_code == ERR.NOT_FOUND or err_code == ERR.CONDITION_NOT_MET then
        -- 目标无效/已被占:丢弃目标,下一轮重新搜索
        self.found, self.flow_target = nil, nil
    end
end

-- 统一响应入口
function SceneTask:on_response(proto_name, result, err_code)
    err_code = as_int(err_code, 0)
    local ok = (err_code == ERR.SUCCESS)

    if proto_name == "enterScene" then
        if ok then self.enter_scene = true end

    elseif proto_name == "quitScene" then
        if ok then
            self.enter_scene, self.set_aoi, self.scenes = false, false, 0
        end

    elseif proto_name == "setAoiPos" then
        if ok then
            self.set_aoi, self.enter_scene = true, true
            self:refresh_castle_pos()
        else
            self.set_aoi = false
        end

    elseif proto_name == "findSceneObj" then
        self:on_find_result(result, err_code)

    elseif proto_name == "addTroop" then
        self:on_add_troop_result(result, err_code)

    elseif proto_name == "troopSpeedUp" then
        if err_code == ERR.STATUS_ERROR or err_code == ERR.TROOP_ARRIVED then
            -- 部队已到达/状态已变:清空加速队列,下次按 sync_data 重新计算
            self.speed_up_queue = {}
        end

    elseif proto_name == "moveCastle" then
        if ok and self.pending_move then
            self.castle_x, self.castle_y = self.pending_move.x, self.pending_move.y
            if self.pending_move_purpose == "medium" then
                self.move_medium_pos = true
            elseif self.pending_move_purpose == "high" then
                self.move_high_pos = true
            end
        end
        self.pending_move, self.pending_move_purpose = nil, nil

    elseif proto_name == "setAutoRallyInfo" then
        if ok then self.set_auto_rally = true end

    elseif proto_name == "getBuffHoldList" then
        self.buff_hold_list = ok and result or nil
    end

    -- 兜底:任何场景协议返回「未进入场景」,都重置 aoi 状态,下一轮重新进场景
    -- (Python 各方法里分别处理 552,这里统一收口,避免遗漏导致长期空转)
    if err_code == ERR.NOT_ENTER_SCENE then
        self.set_aoi, self.enter_scene = false, false
        logf("NOT_ENTER_SCENE(552), 重置 aoi 状态待重进场景")
    end

    if not ok then
        self.stats.fail = self.stats.fail + 1
    end

    return err_code
end

----------------------------------------------------------------------
-- 单步业务流:供任务调度 / xlsx 用例反复驱动
----------------------------------------------------------------------

-- 统计采集中的部队数(对应 Python len(sync_data.all_res_troop))
function SceneTask:count_res_troops()
    local n = 0
    local troops = (self.sync_data and self.sync_data.troops) or {}
    for _, info in pairs(troops) do
        if type(info) == "table" then
            local status = as_int(info.status, 0)
            local collect = info.collect or (type(info.troop) == "table" and info.troop.collect)
            if status == STATUS.COLLECT or collect then n = n + 1 end
        end
    end
    return n
end

-- 单步打怪:确保 aoi -> 队列满则加速 -> 有目标则出征,否则搜索
function SceneTask:step_attack_monster(opts)
    opts = opts or {}
    if self:is_waiting() then return nil end

    if not self.set_aoi then
        local proto, args = self:set_aoi_pos_first()
        if proto then return proto, args end
    end

    if self.troop_max_queue then
        self.troop_max_queue = false
        local proto, args = self:speed_up_all_troop()
        if proto then return proto, args end
    end

    return self:add_monster_troop(opts)
end

-- 单步采集:确保 aoi -> 采集队列未满 -> 有目标则出征,否则搜索
function SceneTask:step_collect_res(opts)
    opts = opts or {}
    if self:is_waiting() then return nil end

    if not self.set_aoi then
        local proto, args = self:set_aoi_pos_first()
        if proto then return proto, args end
    end

    local max_res = as_bool(opts.day_task, false) and DEFAULT.max_res_troop_day
                                                   or DEFAULT.max_res_troop
    if self:count_res_troops() >= max_res then
        logf("采集队列已满(%d),跳过", max_res)
        return nil
    end

    local res_obj_id = as_int(opts.res_obj_id, 0)
    if res_obj_id <= 0 then
        -- 按资源类型 + 剩余量选小/大资源点(对应 Python addResTroopTimes)
        local res_type = as_int(opts.res_type, 0)
        if res_type <= 0 then res_type = def.pick_res_type() end
        local ids = def.RES_OBJ_ID_DEF[res_type]
        if ids then
            local res_count = as_int(opts.res_count, 0)
            res_obj_id = (res_count < DEFAULT.res_count_small) and ids[1] or (ids[2] or ids[1])
        else
            res_obj_id = DEFAULT.res_obj_id
        end
    end

    return self:add_res_troop(res_obj_id, opts)
end

-- 单步迁城:按打怪等级选择中级/高级资源区(对应 Python addMonsterTroopTimes 迁城段)
function SceneTask:step_move_castle(opts)
    opts = opts or {}
    if self:is_waiting() then return nil end

    if not self.set_aoi then
        local proto, args = self:set_aoi_pos_first()
        if proto then return proto, args end
    end

    local monster_lv = as_int(opts.monster_lv, 0)
    local center_x, center_y, purpose
    if monster_lv >= 13 and monster_lv < 20 then
        if self.move_medium_pos then return nil end
        center_x, center_y = def.pick_pos(def.res_medium_pos)
        purpose = "medium"
    elseif monster_lv > 21 then
        if self.move_high_pos then return nil end
        center_x, center_y = def.pick_pos(def.res_large_pos)
        purpose = "high"
    else
        center_x, center_y = def.pick_pos(def.move_pos_list)
        purpose = "normal"
    end

    if not center_x then return nil end
    return self:move_castle(center_x, center_y, opts.range_num, opts.move_times, purpose)
end

----------------------------------------------------------------------
-- xlsx 用例入口:SceneTask.<method>
-- pkt 为用例的 JSON 参数(xlsx 里习惯写 camelCase),统一转成内部 snake_case
----------------------------------------------------------------------

-- camelCase -> snake_case 字段别名
local PKT_ALIAS = {
    targetId = "target_id", targetX = "target_x", targetY = "target_y",
    targetUid = "target_uid", monsterLv = "monster_lv", resObjId = "res_obj_id",
    resType = "res_type", resCount = "res_count", troopId = "troop_id",
    troopType = "troop_type", isRally = "is_rally", rallyIndex = "rally_index",
    isRadar = "is_radar", formationId = "formation_id", objId = "obj_id",
    objIds = "obj_ids", bossObjId = "boss_obj_id", pvpType = "pvp_type",
    centerX = "center_x", centerY = "center_y", rangeNum = "range_num",
    moveTimes = "move_times", isOpen = "is_open", dayTask = "day_task",
    speedTimes = "speed_times", armyKind = "army_kind", totalCapacity = "total_capacity",
    castleX = "castle_x", castleY = "castle_y",
}

-- 需要按整数解析的字段:64 位 id 在 xlsx 里建议写成字符串,
-- 否则 JSON 解析成 double 会丢精度(与 Python 侧遇到的坐标/id 精度问题同源)
local INT_KEYS = {
    target_id = true, target_x = true, target_y = true, target_uid = true,
    monster_lv = true, res_obj_id = true, res_type = true, res_count = true,
    troop_id = true, troop_type = true, rally_index = true, formation_id = true,
    obj_id = true, boss_obj_id = true, pvp_type = true,
    center_x = true, center_y = true, range_num = true, move_times = true,
    speed_times = true, army_kind = true, total_capacity = true,
    castle_x = true, castle_y = true,
}

-- sproto map 字段(army / heros)的参数归一
-- xlsx 里允许三种写法,统一转成 { [整数键] = 整数值 }:
--   "230011:500,230012:300"            -- 字符串
--   { ["230011"] = 500, ["230012"] = 300 }  -- JSON 对象的键一定是字符串
--   { { id = 230011, num = 500 }, ... }     -- 老写法(元素带 id/num 或 key/value)
-- 之所以要转:JSON 的键是字符串,sproto 的 uint32 键必须是整数;
-- 而元素表写法会被 C 编码器当作 map 的 entry 表而报错。
local function normalize_pairs(v)
    if v == nil then return nil end
    local out = {}

    if type(v) == "string" then
        for pair in string.gmatch(v, "[^,;%s]+") do
            local id, num = string.match(pair, "^(%-?%d+)%s*[:=]%s*(%-?%d*)$")
            if not id then id = string.match(pair, "^(%-?%d+)$") end
            id = tonumber(id)
            num = tonumber(num) or 1
            if id and id > 0 then out[id] = (num > 0) and num or 1 end
        end
        if next(out) == nil then return nil end
        return out
    end

    if type(v) ~= "table" then return nil end

    for k, val in pairs(v) do
        local key = type(k) == "string" and tonumber(k) or k
        local num
        if type(val) == "table" then
            key = tonumber(val.id or val.key) or key
            num = tonumber(val.num or val.value)
        else
            num = tonumber(val)
        end
        if type(key) == "number" and key > 0 and num and num > 0 then
            out[key] = num
        end
    end
    if next(out) == nil then return nil end
    return out
end

-- 把用例参数归一成内部 opts 表
function M.from_pkt(pkt)
    local out = {}
    if type(pkt) ~= "table" then return out end
    for k, v in pairs(pkt) do
        local key = PKT_ALIAS[k] or k
        if type(v) == "string" and INT_KEYS[key] then
            local n = tonumber(v)
            if n then v = n end
        end
        out[key] = v
    end

    -- 出征编队参数统一成 sproto map 形态(nil 表示交给默认组队逻辑)
    if out.army ~= nil then
        out.army = normalize_pairs(out.army)
    end
    if out.heros ~= nil then
        out.heros = normalize_pairs(out.heros)
    end

    return out
end

-- 所有方法统一收成 (ctx, opts) 签名,供 xlsx 分发使用
function SceneTask:action_enter_scene(opts)
    self.scenes = 0
    self.enter_scene = false
    return self:do_enter_scene()
end

function SceneTask:action_quit_scene(opts)
    return self:quit_scene()
end

function SceneTask:action_set_aoi_pos(opts)
    opts = opts or {}
    self.set_aoi = false
    if not self.enter_scene then
        local proto, args = self:do_enter_scene()
        if proto then return proto, args end
    end
    return self:set_aoi_pos(opts.castle_x, opts.castle_y)
end

function SceneTask:action_find_monster(opts)
    opts = opts or {}
    return self:find_scene_obj_monster(opts.monster_lv, opts.obj_ids)
end

function SceneTask:action_find_boss(opts)
    opts = opts or {}
    return self:find_scene_obj_boss(opts.boss_obj_id, opts.obj_ids)
end

function SceneTask:action_find_res(opts)
    opts = opts or {}
    return self:find_scene_obj_res(opts.res_obj_id)
end

function SceneTask:action_find_pvp(opts)
    opts = opts or {}
    return self:find_scene_obj_monster_pvp(opts.pvp_type)
end

function SceneTask:action_attack_monster(opts)
    return self:add_monster_troop(opts)
end

function SceneTask:action_collect_res(opts)
    opts = opts or {}
    return self:add_res_troop(opts.res_obj_id, opts)
end

function SceneTask:action_attack_castle(opts)
    return self:add_castle_troop(opts)
end

function SceneTask:action_attack_alliance(opts)
    opts = opts or {}
    return self:add_alliance_troop(opts.target_id, opts)
end

function SceneTask:action_scout(opts)
    opts = opts or {}
    return self:add_scout_troop(opts.target_id)
end

function SceneTask:action_speed_up(opts)
    opts = opts or {}
    if opts.troop_id then
        return self:troop_speed_up(opts.troop_id, opts.speed_times)
    end
    return self:speed_up_random_troop(opts.speed_times)
end

function SceneTask:action_move_castle(opts)
    opts = opts or {}
    local purpose = "normal"
    local monster_lv = as_int(opts.monster_lv, 0)
    if monster_lv >= 13 and monster_lv < 20 then purpose = "medium"
    elseif monster_lv > 21 then purpose = "high" end
    return self:move_castle(opts.center_x, opts.center_y, opts.range_num, opts.move_times, purpose)
end

function SceneTask:action_set_auto_rally(opts)
    opts = opts or {}
    return self:set_auto_rally_info(opts.is_open)
end

function SceneTask:action_get_buff_hold(opts)
    return self:get_buff_hold_list()
end

function SceneTask:action_get_obj_detail(opts)
    opts = opts or {}
    if not opts.obj_id then
        local f = self.found
        opts.obj_id = f and f.id or nil
    end
    if not opts.obj_id then
        return nil, { err = ERR.NO_OBJ, reason = "obj_id nil" }
    end
    return self:get_obj_detail_info(opts.obj_id)
end

-- 纯本地检查,不发协议:由用例做巡检时使用
function SceneTask:action_troop_check(opts)
    self:troop_check()
    return nil, { err = ERR.SUCCESS, reason = "troop_check done" }
end

-- 返回当前场景状态快照(排障用,不发协议)
function SceneTask:action_status(opts)
    local reason = string.format(
        "scene=%s enter=%s aoi=%s found=%s target=%s queue=%d speedup=%d stats{find=%d,attack=%d,collect=%d,speed=%d,move=%d,fail=%d}",
        tostring(self.scenes), tostring(self.enter_scene), tostring(self.set_aoi),
        tostring(self.found and self.found.id), tostring(self.flow_target and self.flow_target.id),
        #self.speed_up_queue, #self.local_troop_can_speed_up,
        self.stats.find, self.stats.attack, self.stats.collect,
        self.stats.speed_up, self.stats.move, self.stats.fail)
    return nil, { err = ERR.SUCCESS, reason = reason }
end

-- xlsx 方法名 -> 统一入口
local DISPATCH = {
    enterScene          = "action_enter_scene",
    quitScene           = "action_quit_scene",
    setAoiPos           = "action_set_aoi_pos",
    findMonster         = "action_find_monster",
    findBoss            = "action_find_boss",
    findRes             = "action_find_res",
    findPvp             = "action_find_pvp",
    attackMonster       = "action_attack_monster",
    collectRes          = "action_collect_res",
    attackCastle        = "action_attack_castle",
    attackAlliance      = "action_attack_alliance",
    scout               = "action_scout",
    speedUp             = "action_speed_up",
    moveCastle          = "action_move_castle",
    setAutoRally        = "action_set_auto_rally",
    getBuffHoldList     = "action_get_buff_hold",
    getObjDetail        = "action_get_obj_detail",
    troopCheck          = "action_troop_check",
    status              = "action_status",
}

-- 供 protocol_task 分发调用:返回 (协议名, 参数字表)
-- 返回 nil + {err/ reason} 表示本次不产出请求
function M.call(method, sync_data, pkt)
    local ctx = M.get(sync_data)
    if not ctx then
        return nil, { err = -1, reason = "sync_data nil" }
    end

    local fn_name = DISPATCH[method]
    if not fn_name and string.sub(tostring(method), 1, 7) == "action_" then
        fn_name = tostring(method)
    end
    local fn = fn_name and SceneTask[fn_name]
    if type(fn) ~= "function" then
        return nil, { err = -1, reason = "scene method not found: " .. tostring(method) }
    end

    -- 沙盘业务请求的前置:先进场景、再设 aoi,否则服务端一律回 552(未进场景)。
    -- 进/退场景与纯本地动作本身不做该检查,避免自我递归。
    if fn_name ~= "action_enter_scene" and fn_name ~= "action_quit_scene"
        and fn_name ~= "action_status" and fn_name ~= "action_troop_check" then
        local pre_proto, pre_args = ctx:ensure_scene()
        if pre_proto or pre_args then return pre_proto, pre_args end
    end

    local opts = M.from_pkt(pkt)
    local ok, proto, args = pcall(fn, ctx, opts)
    if not ok then
        return nil, { err = -1, reason = "scene dispatch error: " .. tostring(proto) }
    end
    return proto, args
end

-- 供上层在响应到达时调用(便捷封装)
function M.on_response(sync_data, proto_name, result, err_code)
    local ctx = M.get(sync_data)
    if not ctx then return nil end
    return ctx:on_response(proto_name, result, err_code)
end

----------------------------------------------------------------------
-- 任务描述:供 pressure/task_manager.lua 按权重调度
-- 每个 task 每次只产出一个请求,由状态机反复驱动
----------------------------------------------------------------------
M.all_tasks = {
    -- 打怪:确保进场景 -> 搜怪 -> 出征(最高权重,场景主要流量)
    {
        name = "sceneAttackMonster",
        weight = 4,
        generate_request = function(sync_data)
            local ctx = M.get(sync_data)
            if not ctx then return nil end
            local proto, args = ctx:step_attack_monster()
            if proto then return proto, args end
            return nil
        end,
    },
    -- 采集资源
    {
        name = "sceneCollectRes",
        weight = 2,
        generate_request = function(sync_data)
            local ctx = M.get(sync_data)
            if not ctx then return nil end
            local proto, args = ctx:step_collect_res()
            if proto then return proto, args end
            return nil
        end,
    },
    -- 部队加速
    {
        name = "sceneSpeedUp",
        weight = 2,
        generate_request = function(sync_data)
            local ctx = M.get(sync_data)
            if not ctx then return nil end
            local proto, args = ctx:speed_up_random_troop()
            if proto then return proto, args end
            return nil
        end,
    },
    -- 迁城(低频:迁一次就置位,不会反复迁)
    {
        name = "sceneMoveCastle",
        weight = 1,
        generate_request = function(sync_data)
            local ctx = M.get(sync_data)
            if not ctx then return nil end
            local proto, args = ctx:step_move_castle()
            if proto then return proto, args end
            return nil
        end,
    },
}

return M
