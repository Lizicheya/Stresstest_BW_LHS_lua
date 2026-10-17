-- 沙盘场景「接入压测调度」链路冒烟测试(离线,不连服务器)
-- 目的:验证三处接入点真的通了
--   1) protocol_task 把 xlsx 的 `SceneTask.yyy` 分发到 scene/scene_task.lua,
--      并把响应回灌给场景状态机(record_response -> on_response)
--   2) pressure/task_manager 已注册沙盘任务(sceneAttackMonster 等按权重调度)
--   3) 分发产出的请求能被 c2s.sproto 正常编码
--
-- 运行(必须在 wrk_tcp 目录下):
--   set PATH=E:\LuaYaCe\wrk_tcp;%PATH%
--   E:\LuaYaCe\luarocks\bin\lua.exe test_scene_dispatch.lua

package.path = "lualib/?.lua;lualib/?/init.lua;game_bw/?.lua;game_bw/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;" .. package.cpath

table.insert(package.searchers, 1, function(name)
    local p = string.gsub(name, "%.", "/")
    for pattern in string.gmatch(package.path, "[^;]+") do
        local file = string.gsub(pattern, "%?", p)
        local f = io.open(file, "r")
        if f then
            f:close()
            return file
        end
    end
end)

local sync_mod = require "sync.sync_data"
local scene    = require "scene.scene_task"
local pt_mod   = require "protocol.protocol_task"

local pass, fail = 0, 0
local function check(cond, msg, extra)
    if cond then
        pass = pass + 1
        print(string.format("[PASS] %s", msg))
    else
        fail = fail + 1
        print(string.format("[FAIL] %s %s", msg, extra and ("-> " .. tostring(extra)) or ""))
    end
end

----------------------------------------------------------------------
-- 1) 登录同步数据(按服务端真实解码形状)
----------------------------------------------------------------------
local sd = sync_mod.new()
sd:handle_sync_login_data({
    serverTime = 1700000000,
    serverOpenTime = 1700000000 - 86400 * 10,
    world = { castleX = 700, castleY = 300, scenes = { [35338588258304] = 10119 } },
    army = { [230011] = 8000, [230021] = 5000, [230031] = 3000 },
    hero = {
        [63503] = { heroCfgId = 63503 }, [63502] = { heroCfgId = 63502 },
        [63501] = { heroCfgId = 63501 },
    },
    city = { [1001] = { id = 1001, buildCfgId = 100, lv = 8 } },
    lordKillNormalMonsterStat = { [1] = 10, [2] = 3 },
})

----------------------------------------------------------------------
-- 2) 造一个最小 protocol_task 实例:只测场景分发 + 响应回灌
--    (真实实例要读 xlsx,离线环境不构建)
----------------------------------------------------------------------
local pt = setmetatable({}, { __index = pt_mod })
pt.client = { sync_data = sd }
pt.waiting_response = false
pt.results = {}
pt.var_dic = {}
pt.next_request = function() return nil end     -- 失败分支会自调用,离线直接返回
pt._record_result = function(self, case, res_str, pass_str, err_str)
    self.last_record = { cmd = case.cmd_module, res = res_str, pass = pass_str, err = err_str }
end

local case = { cmd_module = "SceneTask.attackMonster", row = 2, write_log = 0 }

----------------------------------------------------------------------
-- 3) 第一次分发:未进场景 -> 先 enterScene
----------------------------------------------------------------------
print("==== 1. SceneTask.attackMonster 分发 ====")
local proto, msg = pt:_handle_scene_task(case, {}, "attackMonster")
print("  -> " .. tostring(proto))
check(proto == "enterScene", "首次调用先 enterScene", proto)
check(pt._current_scene_ctx ~= nil, "记录在途场景上下文(_current_scene_ctx)")

-- 响应回灌:enterScene 成功
pt.waiting_response = true
pt._current_case = case
pt:record_response("enterScene", {}, 0)
local ctx = scene.get(sd)
check(ctx ~= nil and ctx.enter_scene == true, "record_response 推进 enter_scene")

-- 下一次分发:setAoiPos
proto = pt:_handle_scene_task(case, {}, "attackMonster")
print("  -> " .. tostring(proto))
check(proto == "setAoiPos", "进场景后发 setAoiPos", proto)

pt.waiting_response = true
pt._current_case = case
pt:record_response("setAoiPos", {}, 0)
check(ctx.set_aoi == true, "record_response 推进 set_aoi")

-- 下一次分发:findSceneObj
proto = pt:_handle_scene_task(case, {}, "attackMonster")
print("  -> " .. tostring(proto))
check(proto == "findSceneObj", "aoi 就绪后先 findSceneObj", proto)

pt.waiting_response = true
pt._current_case = case
pt:record_response("findSceneObj", {
    objs = { { id = 51234567890, x = 600.5, y = 300.25, type = 131, configId = 10003, status = 1 } },
}, 0)
check(ctx.found ~= nil and ctx.found.id == 51234567890, "record_response 缓存搜索命中对象")

-- 下一次分发:addTroop
proto, msg = pt:_handle_scene_task(case, {}, "attackMonster")
print("  -> " .. tostring(proto))
check(proto == "addTroop", "命中目标后发 addTroop", proto)
check(type(msg.army) == "table" and next(msg.army) ~= nil, "addTroop 携带 army")
check(msg.targetId == 51234567890, "addTroop 目标为命中对象", msg.targetId)

----------------------------------------------------------------------
-- 4) 分发产出的包必须能编码
----------------------------------------------------------------------
print("==== 2. 分发产出编码 ====")
local ok_pb, pb_or_err = pcall(function()
    local loader = require "protocol.proto"
    loader.register(1, "c2s")
    return loader.load(1)
end)
if not ok_pb then
    print("[SKIP] sproto 加载失败: " .. tostring(pb_or_err))
else
    local pb = pb_or_err
    local req = pb:host("package"):attach(pb)
    local ok_enc, packed = pcall(req, proto, msg, 1, 0)
    check(ok_enc and type(packed) == "string" and #packed > 0,
        string.format("分发产出 %s 可编码(%s bytes)", tostring(proto),
            ok_enc and tostring(#packed) or "nil"), packed)
end

----------------------------------------------------------------------
-- 5) 未知方法 / 纯本地动作:不产出请求,记为 not run
----------------------------------------------------------------------
print("==== 3. 异常/跳过分支 ====")
local case_bad = { cmd_module = "SceneTask.notExist", row = 3 }
local p2 = pt:_handle_scene_task(case_bad, {}, "notExist")
check(p2 == nil, "未知方法不产出请求", p2)
check(pt.last_record and pt.last_record.pass == "not run", "未知方法记为 not run",
    pt.last_record and pt.last_record.res)

local case_status = { cmd_module = "SceneTask.status", row = 4 }
local p3 = pt:_handle_scene_task(case_status, {}, "status")
check(p3 == nil, "status 为纯本地动作,不产出请求", p3)

----------------------------------------------------------------------
-- 6) task_manager 已注册沙盘任务
----------------------------------------------------------------------
print("==== 4. 压测调度注册 ====")
local tm = require "pressure.task_manager"
local mgr = tm.new()
local names = {}
for _, t in ipairs(mgr.tasks) do names[t.name] = t end
check(names.sceneAttackMonster ~= nil, "注册 sceneAttackMonster")
check(names.sceneCollectRes ~= nil, "注册 sceneCollectRes")
check(names.sceneSpeedUp ~= nil, "注册 sceneSpeedUp")
check(names.sceneMoveCastle ~= nil, "注册 sceneMoveCastle")
check((names.sceneAttackMonster.weight or 0) == 4, "sceneAttackMonster 权重 4",
    names.sceneAttackMonster and names.sceneAttackMonster.weight)
check(mgr.total_weight > 0, "总权重 > 0", mgr.total_weight)

-- 调度器连续产出:至少在若干次内能产出沙盘类请求(其他任务前置条件可能不满足)
local got_scene = false
for _ = 1, 60 do
    local p = mgr:next_request(sd)
    if p and (p == "enterScene" or p == "setAoiPos" or p == "findSceneObj" or p == "addTroop") then
        got_scene = true
        break
    end
end
check(got_scene, "调度器能产出沙盘请求(60 次内)")

print(string.format("\n==== 结果: PASS %d / FAIL %d ====", pass, fail))
if fail > 0 then os.exit(1) end
