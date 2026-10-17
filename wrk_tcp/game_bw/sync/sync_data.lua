-- game_bw 数据同步中心
-- 对应 Python PressureTest_BW_LHS/modules/syncData/sync_data.py 的 SyncData 类
-- 维护玩家全量缓存数据(领主/英雄/兵种/建筑/物品/雷达/科技/部队等)
-- 提供 update_xxx 系列同步入口、通用同步路由 update_sync_module_data、推送分发 PushHandler

local util = require "util"
local tinsert = table.insert
local M = {}

-- 增量合并的三种操作类型(供 update_sync_module_data 内部复用)
local NEW, MERGE, REMOVE = 1, 2, 3

----------------------------------------------------------------------
-- PushHandler:推送分发器
-- 对应 Python sync_data.py 的 PushHandler 类
-- methods: 推送名 -> 处理函数
-- controller: 主分发函数
----------------------------------------------------------------------
local PushHandler = {}
PushHandler.__index = PushHandler

-- 构造 PushHandler
function PushHandler.new(sync_data)
    local self = setmetatable({}, PushHandler)
    self.sync_data = sync_data
    -- 推送处理函数表:推送协议名 -> function(self, msg)
    self.methods = {
        -- 资源/物品/英雄等通用增删改推送
        dictUpdate = function(this, msg) this.sync_data:handle_dict_update(msg) end,
        -- 登录全量同步(列表形态:army/hero/city 都是完整数组)
        -- 场景逻辑依赖其中的 world.scenes / castleX / castleY / lordKillNormalMonsterStat
        syncLoginData = function(this, msg) this.sync_data:handle_sync_login_data(msg) end,
        -- 登录后增量同步(news/changes/removes 形态)
        syncPlayerInfo = function(this, msg) this.sync_data:handle_sync_player_info(msg) end,
        -- 通用:无匹配处理时仅记录
        default = function(this, msg)
            -- 默认无操作,真实实现按需扩展
        end,
    }
    return self
end

-- 主分发:按推送名路由
-- push_name: 推送协议名
-- msg: 解码后的字段表
function PushHandler:controller(push_name, msg)
    local fn = self.methods[push_name] or self.methods.default
    fn(self, msg)
end

----------------------------------------------------------------------
-- SyncData 类:玩家数据缓存与同步
----------------------------------------------------------------------
local SyncData = {}
SyncData.__index = SyncData

-- 构造 SyncData 实例
function SyncData.new()
    local self = setmetatable({}, SyncData)
    self.server_time = 0          -- 服务器时间(秒)
    self.server_open_time = 0     -- 服务器开服时间(秒,用于算开服天数)
    self.lord = {}                -- 领主信息
    self.heros = {}               -- 英雄表: heroCfgId -> ComHero
    self.armys = {}               -- 兵种表: armyCfgId -> num
    self.attributes = {}          -- 属性表: attrId -> value(带兵上限等)
    self.world = {}               -- 世界信息: scenes / castleX / castleY
    self.castle_x = 0             -- 主堡 X(冗余自 world,便于频繁读取)
    self.castle_y = 0             -- 主堡 Y
    self.lord_kill_monster_stat = {}  -- 杀怪统计: 怪等级 -> 击杀数
    self.wounded_armys = {}       -- 伤兵表
    self.buildings = {}           -- 建筑表: buildId -> info
    self.items = {}               -- 物品表: itemId -> info
    self.queues = {}              -- 队列表
    self.radar_events = {}        -- 雷达事件表
    self.techs = {}               -- 科技表
    self.alliance = {}            -- 联盟信息
    self.troops = {}              -- 自己的部队表: troopId -> info
    self.mass_troops = {}         -- 集结部队表
    self.task_table = {}          -- 任务表
    self.guide_table = {}         -- 引导表
    self.login_info = {}          -- 登录同步的全量数据
    self.push_handler = PushHandler.new(self)
    return self
end

-- 服务器时间设置(由心跳回包更新)
function SyncData:set_server_time(t)
    self.server_time = t
end

function SyncData:get_server_time()
    return self.server_time
end

----------------------------------------------------------------------
-- sproto 数组/map 形态判别
--
-- 本项目 sproto 有两类「多值」字段,解码出来的 Lua 形状完全不同:
--   1) `*Type(keyField)` / `*Type()`(空括号 = map) → 解码成 { [键] = 元素 } 或 { [键] = 标量 }
--      例:army 是 *ComArmyIdAndNum() → { [兵种id] = 数量 }
--          hero 是 *ComHero(heroCfgId) → { [heroCfgId] = ComHero 表 }
--          world.scenes 是 *ComIntInt() → { [sceneId] = sceneCfgId }
--   2) `*Type`(无括号,如 *uint32 / *integer) → 解码成 { 1, 2, 3 } 纯数组
-- 因此下面所有合并函数都不能假设 ipairs,必须对两种形态都成立。
----------------------------------------------------------------------

-- 取一条记录的键:优先用元素自身的 check_key / id,否则退回容器键
-- 注意:必须定义在所有使用它的函数之前(update_sync_module_data 就在下面),
-- 否则该名字会退化成全局查找(取到 nil),运行期报 attempt to call a nil value。
local function entry_key(item, fallback, check_key)
    if type(item) == "table" then
        local k = item[check_key]
        if k == nil then k = item.id end
        if k ~= nil then return k end
    end
    return fallback
end

----------------------------------------------------------------------
-- 通用同步入口:对应 Python 的 update_sync_module_data
-- sproto_name: 推送/响应中的类型名(如 "ComLord" / "ComHero")
-- source_dict: 推送的源数据表
-- target_key:  要同步到的目标字段名(如 "lord" / "heros")
-- check_key:   用于判定增删改的子键(如 "heroCfgId")
----------------------------------------------------------------------
function SyncData:update_sync_module_data(sproto_name, source_dict, target_key, check_key)
    if type(source_dict) ~= "table" then return end
    local target = self[target_key] or {}
    self[target_key] = target
    check_key = check_key or "id"

    -- 统一遍历:news/changes/removes 既可能是数组,也可能是 sproto map
    local function apply(container, mode)
        if type(container) ~= "table" then return end
        for k, item in pairs(container) do
            local key = entry_key(item, k, check_key)
            if key ~= nil then
                if mode == REMOVE then
                    target[key] = nil
                elseif mode == MERGE and type(item) == "table" then
                    local old = target[key]
                    if type(old) ~= "table" then old = {} end
                    for fk, fv in pairs(item) do old[fk] = fv end
                    target[key] = old
                else
                    target[key] = item
                end
            end
        end
    end

    apply(source_dict.news, NEW)
    apply(source_dict.changes, MERGE)
    apply(source_dict.removes, REMOVE)
end

-- 路由:根据 target_key 调用对应 update_xxx
function SyncData:update_module(target_key, sproto_name, source_dict, check_key)
    local fn = self["update_" .. target_key]
    if fn then
        fn(self, sproto_name, source_dict, check_key)
    else
        -- 无专用函数则走通用同步
        self:update_sync_module_data(sproto_name, source_dict, target_key, check_key or "id")
    end
end

----------------------------------------------------------------------
-- 操作类型分发:对应 Python handle_operation_type
-- op_type: 1=new 2=update 3=remove
-- target_key / item / check_key
----------------------------------------------------------------------
function SyncData:handle_operation_type(op_type, target_key, item, check_key)
    local target = self[target_key] or {}
    self[target_key] = target
    local k = item[check_key] or item.id
    if op_type == 1 then
        target[k] = item
    elseif op_type == 2 then
        local old = target[k] or {}
        for fk, fv in pairs(item) do old[fk] = fv end
        target[k] = old
    elseif op_type == 3 then
        target[k] = nil
    end
end

-- 通用异常/递归键提取(对应 Python extract_keys_recursive)
function SyncData:extract_keys_recursive(tbl, key_chain)
    key_chain = key_chain or {}
    if type(tbl) ~= "table" then return key_chain end
    for k, v in pairs(tbl) do
        tinsert(key_chain, k)
        if type(v) == "table" then
            self:extract_keys_recursive(v, key_chain)
        end
    end
    return key_chain
end

-- 通用 dict 更新推送入口(由 PushHandler 调用)
function SyncData:handle_dict_update(msg)
    -- msg 形如 { target_key = { news=..., changes=..., removes=... } }
    if type(msg) ~= "table" then return end
    for tk, payload in pairs(msg) do
        if type(payload) == "table" and (payload.news or payload.changes or payload.removes) then
            self:update_module(tk, nil, payload, payload.check_key or "id")
        end
    end
end

----------------------------------------------------------------------
-- 登录全量同步:syncLoginData 22
-- 与 syncPlayerInfo 不同,这里是完整数组(不是 news/changes/removes),
-- 因此直接重建映射表。场景逻辑(world.scenes / 主堡坐标 / 杀怪统计 / 兵种 /
-- 英雄)全部依赖这份数据,缺了会导致沙盘任务找不到场景和出征目标。
----------------------------------------------------------------------

-- 全量落地:按 check_key 作键重建映射表(兼容数组 / 映射 / 纯标量映射三种形态)
function SyncData:merge_snapshot(target_key, list, check_key)
    if type(list) ~= "table" then return end
    check_key = check_key or "id"

    local target = {}
    for k, item in pairs(list) do
        local key = entry_key(item, k, check_key)
        if key ~= nil then target[key] = item end
    end
    self[target_key] = target
end

-- key/value 统计表落地(ComIntInt):兼容 { [k]=v } 与 { {key=,value=}, ... }
function SyncData:merge_stat_map(target_key, list)
    if type(list) ~= "table" then return end
    local target = self[target_key] or {}

    for k, v in pairs(list) do
        local key, val
        if type(v) == "table" then
            key = v.key
            if key == nil then key = v.id end
            val = v.value
            if val == nil then val = v.num end
        else
            key = k
            val = v
        end

        if key ~= nil then
            key = tonumber(key) or key
            target[key] = tonumber(val) or 0
        end
    end
    self[target_key] = target
end

function SyncData:handle_sync_login_data(msg)
    if type(msg) ~= "table" then return end

    if msg.serverTime then
        self.server_time = math.floor(tonumber(msg.serverTime) or self.server_time)
    end
    if msg.serverOpenTime then
        self.server_open_time = tonumber(msg.serverOpenTime) or self.server_open_time
    end
    if type(msg.lord) == "table" then
        for k, v in pairs(msg.lord) do self.lord[k] = v end
    end
    if type(msg.world) == "table" then
        for k, v in pairs(msg.world) do self.world[k] = v end
        self.castle_x = tonumber(self.world.castleX) or self.castle_x
        self.castle_y = tonumber(self.world.castleY) or self.castle_y
    end

    -- 兵种 / 伤兵 / 英雄 / 建筑 / 物品 / 队列 / 科技 / 雷达
    self:merge_snapshot("armys",         msg.army,         "id")
    self:merge_snapshot("wounded_armys", msg.woundedArmy,  "id")
    self:merge_snapshot("heros",         msg.hero,         "heroCfgId")
    self:merge_snapshot("buildings",     msg.city,         "id")
    self:merge_snapshot("items",         msg.item,         "id")
    self:merge_snapshot("queues",        msg.queue,        "queueCfgId")
    self:merge_snapshot("techs",         msg.technology,   "id")
    self:merge_snapshot("radar_events",  msg.radarEvents,  "id")

    -- 属性表(*ComIntInt):带兵上限等场景出征参数来源
    self:merge_stat_map("attributes", msg.attribute)
    -- 杀怪统计(*ComIntInt: lv -> 击杀数),场景据此推算可打最高怪等级
    self:merge_stat_map("lord_kill_monster_stat", msg.lordKillNormalMonsterStat)

    self.login_info = msg
end

----------------------------------------------------------------------
-- 登录后增量同步:syncPlayerInfo 23
-- 结构为 ComSyncData*(news/changes/removes),直接复用通用合并逻辑
----------------------------------------------------------------------
function SyncData:handle_sync_player_info(msg)
    if type(msg) ~= "table" then return end

    if type(msg.lord) == "table" then
        for k, v in pairs(msg.lord) do self.lord[k] = v end
    end
    if type(msg.world) == "table" then
        for k, v in pairs(msg.world) do self.world[k] = v end
        self.castle_x = tonumber(self.world.castleX) or self.castle_x
        self.castle_y = tonumber(self.world.castleY) or self.castle_y
    end

    if msg.army then
        self:update_sync_module_data("ComSyncDataArmy", msg.army, "armys", "id")
    end
    if msg.woundedArmy then
        self:update_sync_module_data("ComSyncDataArmy", msg.woundedArmy, "wounded_armys", "id")
    end
    if msg.hero then
        self:update_sync_module_data("ComSyncDataHero", msg.hero, "heros", "heroCfgId")
    end
    if msg.city then
        self:update_sync_module_data("ComSyncDataCity", msg.city, "buildings", "id")
    end
    if msg.item then
        self:update_sync_module_data("ComSyncDataItem", msg.item, "items", "id")
    end
    if msg.queue then
        self:update_sync_module_data("ComSyncDataQueue", msg.queue, "queues", "queueCfgId")
    end
    if msg.technology then
        self:update_sync_module_data("ComSyncDataTechnology", msg.technology, "techs", "id")
    end
    if msg.radarEvents then
        self:update_sync_module_data("ComSyncRadarEvent", msg.radarEvents, "radar_events", "id")
    end

    if type(msg.attribute) == "table" then
        self:merge_stat_map("attributes", msg.attribute.news)
        self:merge_stat_map("attributes", msg.attribute.changes)
    end
    if type(msg.lordKillNormalMonsterStat) == "table" then
        self:merge_stat_map("lord_kill_monster_stat", msg.lordKillNormalMonsterStat.news)
        self:merge_stat_map("lord_kill_monster_stat", msg.lordKillNormalMonsterStat.changes)
    end

    -- 部队/场景对象推送:交给场景模块按需消费(状态机里也可直接读 self.troops)
    if type(msg.troop) == "table" then
        self:update_sync_module_data("ComTroop", msg.troop, "troops", "id")
    end
end

----------------------------------------------------------------------
-- 各业务 update_xxx 系列方法
-- 这里实现常用业务的高频同步入口,其余沿用通用 update_module
----------------------------------------------------------------------

-- 领主信息同步:对应 Python update_lord
function SyncData:update_lord(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.lord[k] = v
    end
end

-- 英雄同步:对应 Python update_heros,check_key = heroCfgId
function SyncData:update_heros(_, source_dict, check_key)
    self:update_sync_module_data("ComHero", source_dict, "heros", check_key or "heroCfgId")
end

-- 兵种同步:对应 Python update_armys
function SyncData:update_armys(_, source_dict, check_key)
    self:update_sync_module_data("ComArmyIdAndNum", source_dict, "armys", check_key or "id")
end

-- 伤兵同步
function SyncData:update_wounded_armys(_, source_dict, check_key)
    self:update_sync_module_data("ComArmyIdAndNum", source_dict, "wounded_armys", check_key or "id")
end

-- 建筑同步
function SyncData:update_buildings(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "buildings", check_key or "buildId")
end

-- 物品同步
function SyncData:update_items(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "items", check_key or "itemId")
end

-- 队列同步
function SyncData:update_queues(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "queues", check_key or "id")
end

-- 雷达事件同步
function SyncData:update_radar_events(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "radar_events", check_key or "id")
end

-- 科技同步
function SyncData:update_techs(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "techs", check_key or "id")
end

-- 联盟同步
function SyncData:update_alliance(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.alliance[k] = v
    end
end

-- 任务同步
function SyncData:update_tasks(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "task_table", check_key or "id")
end

-- 引导同步
function SyncData:update_guide(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.guide_table[k] = v
    end
end

----------------------------------------------------------------------
-- 查询接口
----------------------------------------------------------------------

-- 取领主信息
function SyncData:get_lord_info()
    return self.lord
end

-- 取领主等级
function SyncData:get_lord_lv()
    return self.lord.lv or 0
end

-- 取英雄列表
function SyncData:get_hero_info()
    return self.heros
end

-- 取指定英雄
function SyncData:get_hero(hero_cfg_id)
    return self.heros[hero_cfg_id]
end

-- 取兵种数量
function SyncData:get_army_num(army_cfg_id)
    return self.armys[army_cfg_id] or 0
end

-- 取全部兵种
function SyncData:get_all_armys()
    return self.armys
end

-- 取建筑列表
function SyncData:get_building_list()
    return self.buildings
end

-- 取指定建筑
function SyncData:get_building(build_id)
    return self.buildings[build_id]
end

-- 取物品列表
function SyncData:get_all_items()
    return self.items
end

-- 取指定物品
function SyncData:get_item(item_id)
    return self.items[item_id]
end

-- 取物品数量
function SyncData:get_item_count(item_id)
    local it = self.items[item_id]
    if not it then return 0 end
    return it.num or 0
end

-- 取队列
function SyncData:get_queue(qid)
    return self.queues[qid]
end

-- 取雷达事件
function SyncData:get_radar_events()
    return self.radar_events
end

-- 取科技等级
function SyncData:get_tech_lv(tech_id)
    local t = self.techs[tech_id]
    return t and t.lv or 0
end

-- 取部队
function SyncData:get_troop(troop_id)
    return self.troops[troop_id]
end

-- 取全部部队表
function SyncData:get_all_troops()
    return self.troops
end

-- 取全部部队数量
function SyncData:get_all_troop_num()
    local n = 0
    for _ in pairs(self.troops) do n = n + 1 end
    return n
end

-- 取联盟信息
function SyncData:get_alliance_info()
    return self.alliance
end

----------------------------------------------------------------------
-- 部队/英雄使用情况跟踪(对应 Python 的 add_check_troop 等)
----------------------------------------------------------------------

-- 添加部队到跟踪表
function SyncData:add_check_troop(troop_id, info)
    self.troops[troop_id] = info
end

-- 更新跟踪的部队
function SyncData:update_check_troop(troop_id, info)
    local old = self.troops[troop_id] or {}
    for k, v in pairs(info) do old[k] = v end
    self.troops[troop_id] = old
end

-- 移除跟踪的部队
function SyncData:remove_check_troop(troop_id)
    self.troops[troop_id] = nil
end

-- 添加集结部队
function SyncData:add_mass_troop(troop_id, info)
    self.mass_troops[troop_id] = info
end

-- 更新集结部队
function SyncData:update_mass_troop_info(troop_id, info)
    local old = self.mass_troops[troop_id] or {}
    for k, v in pairs(info) do old[k] = v end
    self.mass_troops[troop_id] = old
end

-- 移除集结部队
function SyncData:remove_mass_troop(troop_id)
    self.mass_troops[troop_id] = nil
end

-- 初始化所有自己部队(对应 init_all_self_troop)
function SyncData:init_all_self_troop(troop_list)
    self.troops = {}
    if not troop_list then return end
    for _, t in ipairs(troop_list) do
        self.troops[t.troopId or t.id] = t
    end
end

-- 更新所有自己部队
function SyncData:update_all_self_troop(troop_list)
    if not troop_list then return end
    for _, t in ipairs(troop_list) do
        local tid = t.troopId or t.id
        local old = self.troops[tid] or {}
        for k, v in pairs(t) do old[k] = v end
        self.troops[tid] = old
    end
end

-- 从全部部队表里移除
function SyncData:remove_from_all_self_troop(troop_id)
    self:remove_check_troop(troop_id)
end

----------------------------------------------------------------------
-- 登录同步:对应 Python set_login_global_sync / get_module_login_info
----------------------------------------------------------------------
function SyncData:set_login_global_sync(login_data)
    self.login_info = login_data or {}
    -- 把常用字段直接映射到对应缓存表
    if login_data.lord then self:update_lord(nil, login_data.lord) end
    if login_data.heros then self.heros = login_data.heros end
    if login_data.armys then self.armys = login_data.armys end
    if login_data.buildings then self.buildings = login_data.buildings end
    if login_data.items then self.items = login_data.items end
    if login_data.queues then self.queues = login_data.queues end
    if login_data.radarEvents then self.radar_events = login_data.radarEvents end
    if login_data.techs then self.techs = login_data.techs end
    if login_data.alliance then self.alliance = login_data.alliance end
    if login_data.troops then self:init_all_self_troop(login_data.troops) end
    if login_data.tasks then self.task_table = login_data.tasks end
    if login_data.guides then self.guide_table = login_data.guides end
end

function SyncData:get_module_login_info()
    return self.login_info
end

function SyncData:del_login_global_sync()
    self.login_info = {}
end

function SyncData:get_base_info()
    return self.login_info
end

function SyncData:get_server_time()
    return self.server_time
end

----------------------------------------------------------------------
-- 沙盘场景相关取值(对应 Python sync_data 的 get_building_info /
-- get_max_kill_monster / cur_server_day / hero_list 等)
----------------------------------------------------------------------

-- 取世界信息:scenes(场景 id 表) / castleX / castleY
function SyncData:get_world()
    return self.world
end

-- 取建筑等级:buildId 规则为 buildCfgId * 10 + subIndex(主堡 100 -> 1001)
-- 找不到时返回 -1(与 Python 一致,调用方需自行判断「等级未知」与「等级为 0」)
function SyncData:get_building_lv(build_id, sub_index)
    build_id = tonumber(build_id) or 0
    sub_index = tonumber(sub_index) or 1
    if build_id == 158 then build_id = 118 end

    local idx = tonumber(tostring(build_id) .. tostring(sub_index))
    local b = idx and self.buildings[idx] or nil
    if not b then b = self.buildings[build_id] end
    if not b then
        for _, item in pairs(self.buildings) do
            if type(item) == "table" and item.buildCfgId == build_id then
                b = item
                break
            end
        end
    end
    if type(b) ~= "table" then return -1 end
    return tonumber(b.lv) or -1
end

-- 取当前可打的普通怪最高等级:已击杀最高等级 + 1,上限 30
function SyncData:get_max_kill_monster()
    local max_lv = 0
    for k in pairs(self.lord_kill_monster_stat or {}) do
        local lv = tonumber(k) or 0
        if lv > max_lv then max_lv = lv end
    end
    if max_lv <= 0 then return 1 end
    max_lv = max_lv + 1
    if max_lv > 30 then max_lv = 30 end
    return max_lv
end

-- 取服务器开服天数:((服务器时间 - 开服时间) / 86400) + 1
function SyncData:get_server_day()
    local open = tonumber(self.server_open_time) or 0
    local now = tonumber(self.server_time) or 0
    if open <= 0 or now <= 0 then return 1 end
    return math.floor((now - open) / 86400) + 1
end

-- 取英雄配置 id 列表
function SyncData:get_hero_list()
    local list = {}
    for cfg_id in pairs(self.heros) do
        list[#list + 1] = cfg_id
    end
    return list
end

-- 取某个属性值(attribute 推送: attrId -> value)
function SyncData:get_attribute(attr_id)
    return tonumber(self.attributes[attr_id]) or 0
end

----------------------------------------------------------------------
-- 取本模块导出
----------------------------------------------------------------------
M.SyncData = SyncData
M.PushHandler = PushHandler

-- 工厂函数:快捷创建 SyncData 实例
function M.new()
    return SyncData.new()
end

return M
