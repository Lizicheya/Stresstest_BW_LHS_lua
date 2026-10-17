-- 单账号沙盘联调用例(wrk 主入口)
-- 目的:用「指定账号」走一遍真实登录,登录成功后按真实协议顺序执行
--   enterScene(进场景) -> setAoiPos(设置 AOI) -> findSceneObj(搜怪) -> addTroop(出征打怪)
-- 并逐步打印请求参数与服务器回包,用于上线前的单账号人工验证。
--
-- ============================ 运行方式 ============================
-- 不在正常压测链路上:本文件通过环境变量 WRK_MAIN_ENTRY 覆盖 main_entry 启动,
-- 同时把并发压到 1 连接 / 1 线程、关掉账号轮换(见 run_test_find_attack_monster.bat)。
-- 直接双击 run_test_find_attack_monster.bat 即可,也可手动:
--   cd /d e:\LuaYaCe\wrk_tcp
--   set WRK_MAIN_ENTRY=test.test_find_attack_monster
--   set WRK_TEST_ACCOUNT=A001          (可选:指定账号,缺省取账号文件第 1 条)
--   .\wrk.exe
--
-- ============================ 可调环境变量 ============================
--   WRK_TEST_ACCOUNT        指定账号名(对应账号文件里的 user 字段,如 A001)
--   WRK_TEST_ACCOUNT_INDEX  按序号选账号(1 起,WRK_TEST_ACCOUNT 优先)
--   WRK_TEST_ACCOUNT_FILE   账号文件(缺省 robot/ycf_a.txt,读取逻辑与压测一致)
--   WRK_TEST_MONSTER_LV     指定要打的怪等级(缺省 0 = 打自身可打最高等级)
--   WRK_TEST_ATTACK_TIMES   出征次数(缺省 1)
--   WRK_TEST_TIMEOUT        整个用例的超时秒数(缺省 120)
--   WRK_TEST_SYNC_TIMEOUT   等待登录同步的超时秒数(缺省 30)
--   WRK_TEST_VERBOSE        "0" 关闭 scene_task 明细日志(缺省开启)
--
-- ============================ 设计说明 ============================
-- 1) 登录逻辑完全复用 client/sproto_client.lua(reqlogin -> reconnect 网关 -> reqAuth),
--    本文件只负责建连接、装配协议、驱动收发,不复制登录代码。
-- 2) 登录成功后客户端进入 STATE_IDLE,会回调 task_mgr:next_request 取下一个请求。
--    这里把一个「单账号流程驱动器」伪装成 task_mgr 注入,按固定阶段推进:
--      wait_sync -> enterScene -> setAoiPos -> findSceneObj -> addTroop -> observe
--    响应到达时客户端回调 record_response,驱动器据此推进阶段并回灌 scene_task 状态机。
-- 3) 每个阶段的请求都由 scene/scene_task.lua 生成(与压测链路同一套组包逻辑),
--    因此这里验证通过 = 压测链路里对应的请求也是对的。

local proto_util = require "proto_util"
local netpack    = require "netpack"
local config     = require "config"
local cjson      = require "cjson"
local scene      = require "scene.scene_task"
local def        = require "scene.scene_def"

local M = {}

-- 客户端状态常量(与 client/sproto_client.lua 的 M.STATE_xxx 一致;此处仅做判定)
local STATE_IDLE = 6
local STATE_NONE = 8

local identify              -- 本线程 id(单线程用例,恒为 0)
local clients = {}          -- fd -> sproto_client
local queue                 -- netpack 拆包队列
local account               -- 选中的账号记录 { user=..., kingdomId=..., nickName=... }
local account_index         -- 选中账号在文件中的序号
local account_total = 0     -- 账号文件条目总数

----------------------------------------------------------------------
-- 日志:统一前缀,带上毫秒,便于对照服务器日志时间
----------------------------------------------------------------------
local function logf(fmt, ...)
    local ms = math.floor((os.clock() % 1) * 1000)
    local ok, msg = pcall(string.format, fmt, ...)
    print(string.format("[%s.%03d][test] %s",
        os.date("%H:%M:%S"), ms, ok and msg or tostring(fmt)))
end

-- 读整数环境变量
local function int_env(name, default)
    local v = tonumber(os.getenv(name) or "")
    if not v then return default end
    return math.floor(v)
end

-- 数字转文本:cjson 把 JSON 整数解成浮点(1 -> 1.0),日志里还原成整数形式
local function fmt_num(v)
    local n = tonumber(v)
    if not n then return tostring(v) end
    if n == math.floor(n) then return string.format("%d", n) end
    return tostring(n)
end

-- 取表的条目数(兼容数组与 sproto map)
local function count_table(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- 取第一个元素(兼容数组与 map)
local function first_value(t)
    if type(t) ~= "table" then return nil end
    return t[1] or next(t)
end

-- 单值转短字符串(嵌套表只展开一层,避免刷屏)
local function fmt_val(v, max_items)
    if type(v) ~= "table" then return tostring(v) end
    local parts, n = {}, 0
    for k, vv in pairs(v) do
        n = n + 1
        if n > (max_items or 8) then
            parts[#parts + 1] = "..."
            break
        end
        parts[#parts + 1] = tostring(k) .. "=" ..
            (type(vv) == "table" and "{...}" or tostring(vv))
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

-- 请求参数转一行日志文本(键排序,便于对比)
local function dump_args(args)
    if type(args) ~= "table" then return tostring(args) end
    local keys = {}
    for k in pairs(args) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, k in ipairs(keys) do
        parts[#parts + 1] = tostring(k) .. "=" .. fmt_val(args[k])
    end
    return table.concat(parts, " ")
end

----------------------------------------------------------------------
-- 账号文件读取:与 main_bw.M.init 的逻辑完全一致
-- 格式:第 1 行 Record time(跳过),第 2 行起每行一个 JSON {"user":"A001",...}
----------------------------------------------------------------------
local function load_accounts(path)
    local f = io.open(path, "r")
    if not f then
        return nil, "账号文件打开失败: " .. tostring(path)
    end
    local lines = {}
    for line in f:lines() do
        if line and line ~= "" then lines[#lines + 1] = line end
    end
    f:close()

    local list = {}
    for i = 2, #lines do
        local ok, data = pcall(cjson.decode, lines[i])
        if ok and type(data) == "table" and data.user then
            list[#list + 1] = data
        end
    end
    return list
end

-- 选取要登录的账号:显式账号名 > 序号 > 第 1 条
local function pick_account(list)
    local want = os.getenv("WRK_TEST_ACCOUNT")
    if want and want ~= "" then
        for i, a in ipairs(list) do
            if a.user == want then return a, i end
        end
        for i, a in ipairs(list) do
            if string.upper(tostring(a.user)) == string.upper(want) then return a, i end
        end
        return nil, nil, want
    end

    local idx = int_env("WRK_TEST_ACCOUNT_INDEX", 1)
    if idx < 1 then idx = 1 end
    return list[idx], idx
end

----------------------------------------------------------------------
-- 单账号流程驱动器:伪装成 task_mgr 注入 sproto_client
--   next_request(sync_data)              -> 产出当前阶段的请求
--   record_response(proto, result, err)  -> 消费回包,推进阶段
--   watch(client)                        -> 登录失败/整体超时看护
----------------------------------------------------------------------
local Driver = {}
Driver.__index = Driver
M.Driver = Driver

-- 阶段说明(仅用于日志)
local STAGE_TEXT = {
    wait_sync    = "等待登录同步",
    enterScene   = "进入场景",
    setAoiPos    = "设置 AOI",
    findSceneObj = "搜索怪物",
    addTroop     = "出征打怪",
    observe      = "观察部队推送",
    done         = "结束",
}

function Driver.new(client, opts)
    local self = setmetatable({}, Driver)

    self.client = client
    self.sync_data = client.sync_data
    self.opts = opts or {}
    self.ctx = scene.get(self.sync_data)

    self.stage = "wait_sync"
    self.pending = nil            -- 在途请求 { stage=, proto=, at= }
    self.not_before = 0           -- 早于该时间不发下一个请求(重试退避)
    self.retry = {}               -- 各阶段重试计数
    self.max_retry = 3

    self.attack_done = 0
    self.max_attack = math.max(1, int_env("WRK_TEST_ATTACK_TIMES", 1))
    self.monster_lv = int_env("WRK_TEST_MONSTER_LV", 0)

    local now = os.time()
    self.started_at = now
    self.sync_deadline = now + int_env("WRK_TEST_SYNC_TIMEOUT", 30)
    self.deadline = now + int_env("WRK_TEST_TIMEOUT", 120)

    self.finished = false
    self.ok = false
    self.login_logged = false

    -- 单账号联调默认打开 scene_task 的明细日志(选怪等级/命中/出征目标)
    if os.getenv("WRK_TEST_VERBOSE") ~= "0" then
        scene.verbose = true
    end
    return self
end

-- 客户端登录成功回调 set_uid / set_account(保持与 protocol_task 相同的接口)
function Driver:set_uid(uid) self.uid = uid end
function Driver:set_account(name) self.account_name = name end

----------------------------------------------------------------------
-- 登录失败 / 超时看护:登录阶段不会走到 next_request,必须独立检查
----------------------------------------------------------------------
function Driver:watch(client)
    if self.finished then return end

    if not self.login_logged and client.uid then
        self.login_logged = true
        logf("登录成功 account=%s uid=%s gateway=%s:%s", tostring(self.account_name),
            tostring(client.uid), tostring(client.gateway_host), tostring(client.gateway_port))
    end

    if client.status == STATE_NONE then
        self:finish(false, "登录失败:客户端状态 STATE_NONE(reqlogin/reqAuth 失败或连接中止)")
        return
    end

    if os.time() > self.deadline then
        self:finish(false, string.format("整体超时(%ds),当前阶段 %s",
            int_env("WRK_TEST_TIMEOUT", 120), tostring(STAGE_TEXT[self.stage] or self.stage)))
    end
end

----------------------------------------------------------------------
-- 同步数据就绪判定:world.scenes 是进场景的唯一数据来源
----------------------------------------------------------------------
function Driver:sync_ready()
    local world = self.sync_data and self.sync_data.world
    local scenes = type(world) == "table" and world.scenes or nil
    if type(scenes) ~= "table" then return false end
    for k in pairs(scenes) do
        if type(k) == "number" and k > 0 then return true end
    end
    return false
end

-- 登录同步摘要:确认进场景/出征所需的数据都拿到了
function Driver:log_sync()
    local sd = self.sync_data
    local world = sd.world or {}
    local scene_parts = {}
    for k, v in pairs(world.scenes or {}) do
        scene_parts[#scene_parts + 1] = tostring(k) .. "->" .. tostring(v)
    end

    local day = 1
    if type(sd.get_server_day) == "function" then day = sd:get_server_day() end
    logf("登录同步就绪: 开服第 %s 天, 场景 %s, 主堡(%s,%s)",
        tostring(day), table.concat(scene_parts, ","),
        tostring(world.castleX), tostring(world.castleY))

    local army_parts = {}
    for id, num in pairs(sd.armys or {}) do
        army_parts[#army_parts + 1] = tostring(id) .. "=" .. tostring(num)
    end
    table.sort(army_parts)
    logf("兵种: %s", #army_parts > 0 and table.concat(army_parts, " ") or "(空)")

    local hero_parts = {}
    for id in pairs(sd.heros or {}) do hero_parts[#hero_parts + 1] = tostring(id) end
    table.sort(hero_parts)
    logf("英雄: %s", #hero_parts > 0 and table.concat(hero_parts, ",") or "(空)")

    if type(sd.get_building_lv) == "function" then
        logf("主堡等级: %s", tostring(sd:get_building_lv(def.DEFAULT.castle_build_id)))
    end
end

----------------------------------------------------------------------
-- 产出当前阶段的请求
----------------------------------------------------------------------
function Driver:build_request()
    local ctx = self.ctx
    local stage = self.stage

    if stage == "enterScene" then
        if ctx.enter_scene then self.stage = "setAoiPos"; return nil end
        local proto, args = ctx:do_enter_scene()
        if not proto then
            self:finish(false, "进场景前置失败: " .. tostring(args and args.reason))
            return nil
        end
        return proto, args

    elseif stage == "setAoiPos" then
        if ctx.set_aoi then self.stage = "findSceneObj"; return nil end
        local proto, args = ctx:set_aoi_pos_first()
        if not proto then
            local reason = (args and args.reason) or "unknown"
            if args and args.err == def.ERR.LOWER_CASTLE_LV then
                self:finish(false, "主堡等级不足,无法进沙盘: " .. tostring(reason))
            else
                self:finish(false, "设置 AOI 失败: " .. tostring(reason))
            end
            return nil
        end
        return proto, args

    elseif stage == "findSceneObj" then
        local proto, args = ctx:find_scene_obj_monster(self.monster_lv)
        if not proto then
            self:finish(false, "搜索条件不满足: " .. tostring(args and args.reason))
            return nil
        end
        return proto, args

    elseif stage == "addTroop" then
        -- ctx（self.ctx）其实是一张实例表（self.ctx = scene.get(self.sync_data)）；ctx.found是实例表的数据，所以可以直接读到对应实例表的数据
        -- found是数据可以直接从实例表取，诸如其他函数才需要ctx:add_monster_troop({})去找
        if not ctx.found then self.stage = "findSceneObj"; return nil end
        local proto, args = ctx:add_monster_troop({})
        if not proto then
            if args and args.err == def.ERR.LOWER_CASTLE_LV then
                self:finish(false, "主堡等级不足,无法出征: " .. tostring(args.reason))
            else
                -- 目标失效:退回搜索
                self.stage = "findSceneObj"
            end
            return nil
        end
        return proto, args
    end

    return nil
end

----------------------------------------------------------------------
-- 客户端 IDLE 时回调:返回下一个请求(或 nil 表示本轮到心跳/保活)
----------------------------------------------------------------------
function Driver:next_request(sync_data)
    if self.finished then return nil end
    if os.time() < self.not_before then return nil end

    -- 0) 等登录同步数据落地
    if self.stage == "wait_sync" then
        if not self:sync_ready() then
            if os.time() > self.sync_deadline then
                self:finish(false, "登录同步超时:world.scenes 为空(可能未收到 syncLoginData 推送)")
            end
            return nil
        end
        self:log_sync()
        self.stage = "enterScene"
    end

    -- 1) 观察窗口结束:打印部队推送情况并收尾
    if self.stage == "observe" then
        self:log_troops()
        self:finish(true, "打怪流程完成")
        return nil
    end

    -- 2) 依次尝试当前及后续阶段(某些阶段可能因状态已就绪而直接跳过)
    for _ = 1, 4 do
        if self.finished or self.stage == "done" then return nil end
        local proto, args = self:build_request()
        if proto then
            self.pending = { stage = self.stage, proto = proto, at = os.time() }
            logf("[req ] %-12s %s", proto, dump_args(args))
            return proto, args
        end
    end
    return nil
end

----------------------------------------------------------------------
-- 回包摘要
----------------------------------------------------------------------
function Driver:brief_result(proto_name, result)
    if type(result) ~= "table" then return "" end

    if proto_name == "findSceneObj" then
        local objs = result.objs
        local n = count_table(objs)
        if n == 0 then return "未命中对象" end
        local o = first_value(objs) or {}
        return string.format("命中 %d 个, 首个 id=%s type=%s cfg=%s pos=(%s,%s) status=%s",
            n, tostring(o.id), tostring(o.type), tostring(o.configId),
            tostring(o.x), tostring(o.y), tostring(o.status))
    elseif proto_name == "addTroop" then
        return string.format("troopId=%s", tostring(result.troopId or result.id))
    elseif proto_name == "enterScene" then
        return "已进入场景"
    elseif proto_name == "setAoiPos" then
        return "AOI 就绪"
    end
    return ""
end

-- 重试退避:同一阶段连续失败超过上限则判失败
function Driver:retry_later(stage, delay)
    self.retry[stage] = (self.retry[stage] or 0) + 1
    if self.retry[stage] > self.max_retry then
        self:finish(false, string.format("%s 连续失败 %d 次,放弃", stage, self.retry[stage]))
        return
    end
    self.not_before = os.time() + (delay or 2)
    logf("  %s 未完成,第 %d/%d 次重试,%ds 后继续",
        tostring(STAGE_TEXT[stage] or stage), self.retry[stage], self.max_retry, delay or 2)
end

----------------------------------------------------------------------
-- 回包处理:推进阶段 + 回灌 scene_task 状态机
----------------------------------------------------------------------
function Driver:record_response(proto_name, result, err_code)
    if self.finished then return end

    local pending = self.pending
    if not pending then
        -- 心跳/保活的回包不属于本驱动器,直接忽略
        logf("[skip] %s (非流程请求的响应,忽略)", tostring(proto_name))
        return
    end
    self.pending = nil

    err_code = tonumber(err_code) or 0
    local stage = pending.stage
    local cost = os.time() - (pending.at or os.time())

    logf("[resp] %-12s err=%-4d cost=%ds %s", tostring(proto_name), err_code, cost,
        self:brief_result(proto_name, result))

    -- 回灌:enterScene/setAoiPos/findSceneObj/addTroop 的本地状态由 scene_task 推进
    local ok_ctx, ctx_err = pcall(self.ctx.on_response, self.ctx, proto_name, result, err_code)
    if not ok_ctx then
        self:finish(false, "scene on_response 异常: " .. tostring(ctx_err))
        return
    end

    local ERR = def.ERR

    if stage == "enterScene" then
        -- Python 对 enterScene 忽略 NOT_FOUND(场景已存在/无该场景),这里保持一致
        if err_code == ERR.SUCCESS or err_code == ERR.NOT_FOUND then
            self.retry.enterScene = 0
            self.stage = "setAoiPos"
        else
            self:retry_later("enterScene", 2)
        end

    elseif stage == "setAoiPos" then
        if err_code == ERR.SUCCESS or err_code == ERR.NOT_FOUND then
            self.retry.setAoiPos = 0
            self.stage = "findSceneObj"
        elseif err_code == ERR.NOT_ENTER_SCENE then
            -- on_response 已重置 enter_scene/set_aoi,重新进场景
            self.stage = "enterScene"
            self:retry_later("setAoiPos", 1)
        else
            self:retry_later("setAoiPos", 2)
        end

    elseif stage == "findSceneObj" then
        if err_code == ERR.SUCCESS and self.ctx.found then
            self.retry.findSceneObj = 0
            self.stage = "addTroop"
        else
            if err_code == ERR.NOT_ENTER_SCENE then
                self.stage = "enterScene"
            end
            -- 19/511/532:目标不在/搜不到,稍等后重新搜索
            self:retry_later("findSceneObj", 2)
        end

    elseif stage == "addTroop" then
        if err_code == ERR.SUCCESS then
            self.retry.addTroop = 0
            self.attack_done = self.attack_done + 1
            logf("  出征成功 (%d/%d)", self.attack_done, self.max_attack)
            if self.attack_done >= self.max_attack then
                -- 留 3s 观察窗口:确认服务端把部队推送下来(syncPlayerInfo.troop)
                self.stage = "observe"
                self.not_before = os.time() + 3
                logf("  等待 3s 观察部队推送...")
            else
                self.stage = "findSceneObj"
                self.not_before = os.time() + 1
            end
        elseif err_code == ERR.TROOP_MAX_QUEUE then
            -- 行军队列已满:等待在途部队,稍后重新搜索出征
            self.retry.addTroop = (self.retry.addTroop or 0) + 1
            if self.retry.addTroop > self.max_retry then
                self:finish(false, "行军队列持续已满(502),放弃")
            else
                logf("  行军队列已满(502),5s 后重试 (%d/%d)",
                    self.retry.addTroop, self.max_retry)
                self.stage = "findSceneObj"
                self.not_before = os.time() + 5
            end
        elseif err_code == ERR.NOT_ENTER_SCENE then
            self.stage = "enterScene"
            self:retry_later("addTroop", 1)
        else
            self:retry_later("addTroop", 2)
        end
    end
end

----------------------------------------------------------------------
-- 收尾:打印结果摘要并上报完成(让 wrk 提前结束,不必等满 duration)
----------------------------------------------------------------------
function Driver:log_troops()
    local troops = (self.sync_data and self.sync_data.troops) or {}
    local parts = {}
    for id, info in pairs(troops) do
        if type(info) == "table" then
            parts[#parts + 1] = string.format("%s(status=%s)", tostring(id), tostring(info.status))
        else
            parts[#parts + 1] = tostring(id)
        end
    end
    table.sort(parts)
    logf("部队表(%d): %s", #parts, #parts > 0 and table.concat(parts, " ") or "(空)")
end

function Driver:finish(ok, reason)
    if self.finished then return end
    self.finished = true
    self.ok = ok
    self.stage = "done"

    local ctx = self.ctx
    local st = (ctx and ctx.stats) or {}
    local account_name = self.account_name
        or (self.client.login_web_data and self.client.login_web_data.account)

    print("")
    logf("================ 用例结果 ================")
    logf("账号        : %s", tostring(account_name))
    logf("uid         : %s", tostring(self.client.uid))
    logf("结论        : %s (%s)", ok and "PASS" or "FAIL", tostring(reason))
    logf("场景 id     : %s", tostring(ctx and ctx.scenes))
    logf("主堡坐标    : (%s, %s)", tostring(ctx and ctx.castle_x), tostring(ctx and ctx.castle_y))
    logf("搜怪/出征   : 命中 %s 次, 出征成功 %s 次",
        tostring(st.find or 0), tostring(st.attack or 0))
    logf("失败回包数  : %s", tostring(st.fail or 0))
    logf("耗时        : %ds", os.time() - (self.started_at or os.time()))
    logf("==========================================")
    print("")

    -- 上报完成:主线程每秒检查一次,所有线程 done 后提前结束压测
    if wrk and wrk.report_done then
        wrk.report_done()
    end
end

----------------------------------------------------------------------
-- wrk 主入口:init / connected / writeable / readable / delay
----------------------------------------------------------------------
function M.init(id, connections)
    identify = id

    -- 协议初始化:注册 c2s(槽位 1) 与 s2c(槽位 2)
    proto_util.init()

    -- 账号文件:与压测同一套读取逻辑(第 1 行 Record time 跳过,其余每行一个 JSON)
    local file = os.getenv("WRK_TEST_ACCOUNT_FILE")
    if not file or file == "" then file = config.user_ids_file end

    local list, err = load_accounts(file)
    if not list then
        print("[test] " .. tostring(err))
        return
    end
    account_total = #list
    if account_total == 0 then
        print("[test] 账号文件无有效条目: " .. tostring(file))
        return
    end

    local picked, idx, want = pick_account(list)
    if not picked then
        print(string.format("[test] 账号文件 %s 中找不到指定账号 %s", tostring(file), tostring(want)))
        return
    end
    account, account_index = picked, idx

    print(string.format("[test] 账号文件 %s, 共 %d 条", tostring(file), account_total))
    print(string.format("[test] 使用账号 %s (%d/%d) kingdomId=%s nickName=%s",
        tostring(account.user), account_index, account_total,
        fmt_num(account.kingdomId), tostring(account.nickName)))
    print(string.format("[test] 单连接联调: threads=%s connections=%s",
        tostring(config.threads), tostring(config.connections)))

    math.randomseed(os.time() + (identify or 0) * 1000)
end

function M.connected(fd)
    -- fd 复用场景:reqlogin 后的 wrk.reconnect 会迁移 clients 映射并对新 fd 触发本回调,
    -- 此时驱动器和登录流程都已在跑,直接返回(wrk.reconnect 可能复用同一 fd)
    if clients[fd] then
        return
    end
    if not account then
        print("[test] 无可用账号,放弃连接 fd=" .. tostring(fd))
        -- 没有账号就没有后续流程,直接上报完成,避免空转到 duration
        if wrk and wrk.report_done then wrk.report_done() end
        return
    end

    local client_mod = require "client.sproto_client"
    local client = client_mod.new(fd)
    clients[fd] = client

    -- 登录服地址:relogin 需要从网关切回登录服(本用例不轮换账号,保留以防重连)
    client.login_host = config.host
    client.login_port = config.port
    -- 网关切换后迁移 clients 映射(必须点调用,详见 main_bw.connected 的说明)
    client._on_reconnect = function(oldfd, newfd)
        local c = clients[oldfd]
        if not c then return end
        clients[oldfd] = nil
        clients[newfd] = c
    end

    -- 注入单账号流程驱动器:登录完成后由它接管请求产出
    local driver = Driver.new(client)
    driver:set_account(account.user)
    client:set_task_manager(driver)

    -- 复用原有登录逻辑:reqlogin -> 切网关 -> reqAuth
    client:start({ account = account.user })
    print("[test] 开始登录 fd=" .. tostring(fd) .. " account=" .. tostring(account.user))
end

function M.writeable(fd)
    local client = clients[fd]
    if not client then
        return "", 0
    end

    -- 登录失败/整体超时看护(此时还没走到 task_mgr)
    local driver = client.task_mgr
    if driver and driver.watch then
        driver:watch(client)
    end

    local data, proto_id, over = client:writeable()
    if over then
        clients[fd] = nil
        return "", 0
    end
    if proto_id == -1 or not data or #data == 0 then
        return "", 0
    end
    return data, #data
end

function M.readable(fd, buffer, sz)
    local MSG = {}

    -- 单条消息:拆原始 payload 后交给 client:readable(sproto host:dispatch)
    local function dispatch_msg(msg_fd, msg, msg_sz)
        local client = clients[msg_fd]
        if not client then
            print("[test] readable 无对应 client, fd=" .. tostring(msg_fd))
            return -1, 1
        end
        local payload = netpack.unpackraw(msg, msg_sz)
        if not payload or #payload == 0 then
            return -2, 0
        end
        local result = client:readable(payload)
        if result == 0 then
            return 0, 1
        end
        return -1, 1
    end
    MSG.data = dispatch_msg

    -- 队列中累积的多条消息
    local function dispatch_queue()
        local readhandle = -1
        local result = 0
        for msg_fd, msg, msg_sz in netpack.pop, queue do
            local r1, r2 = dispatch_msg(msg_fd, msg, msg_sz)
            if r1 == 0 then readhandle = 0 end
            result = result + r2
        end
        return readhandle, result
    end
    MSG.more = dispatch_queue

    local q, msg_type, fd2, msg, sz2 = netpack.filter(queue, buffer, sz, fd)
    queue = q

    if msg_type == "data" then
        return MSG[msg_type](fd2, msg, sz2)
    elseif msg_type == "more" then
        return MSG[msg_type]()
    end
    return -2, 0
end

-- 空闲轮询间隔(毫秒):单账号联调要求响应尽量快,给 20ms
function M.delay(fd)
    return 20
end

function M.heartbeat(fd)
    -- 心跳由 sproto_client 状态机内部驱动,这里无需处理
end

return M
