-- test_find_attack_monster 流程驱动器的离线回归测试(不连服务器)
--
-- 目的:
--   1) 用合成回包驱动 game_bw/test/test_find_attack_monster.lua 里的 Driver,
--      断言「进场景 -> 设置AOI -> 搜怪 -> 出征」的协议顺序与状态推进正确;
--   2) 把 Driver 真实产出的每个请求用 c2s.sproto 编码一遍,
--      确认单账号联调实际要发出去的报文形状合法(避免真机跑起来才发现编码失败);
--   3) 覆盖两条异常分支:findSceneObj 搜不到(重试)、addTroop 行军队列满 502(重试)。
--
-- 运行(必须在 wrk_tcp 目录,且 Lua53.dll 在 PATH):
--   set PATH=E:\LuaYaCe\wrk_tcp;%PATH%
--   E:\LuaYaCe\luarocks\bin\lua.exe game_bw\test\test_find_attack_monster_offline.lua

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

-- wrk 全局:Driver:finish 会调用 report_done,离线用桩记录调用次数
local reported = 0
wrk = { report_done = function() reported = reported + 1 end }

local mod      = require "test.test_find_attack_monster"
local sync_mod = require "sync.sync_data"
local scene    = require "scene.scene_task"
local def      = require "scene.scene_def"

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
-- c2s.sproto 编码器:验证 Driver 产出的报文能真正编码
----------------------------------------------------------------------
local loader = require "protocol.proto"
loader.register(1, "c2s")
local pb = loader.load(1)
local req = pb:host("package"):attach(pb)

----------------------------------------------------------------------
-- 构造一份与服务端解码形状一致的登录同步数据
----------------------------------------------------------------------
local function new_sync_data()
    local sd = sync_mod.new()
    local now = os.time()
    sd:handle_sync_login_data({
        serverTime = now,
        serverOpenTime = now - 86400 * 12,                 -- 开服第 13 天
        world = {
            castleX = 700,
            castleY = 300,
            -- *ComIntInt() 是 sproto map: { [sceneId] = sceneCfgId }
            scenes = { [35338588258304] = 10119 },
        },
        -- *ComArmyIdAndNum() map: { [兵种id] = 数量 }
        army = { [230011] = 8000, [230021] = 5000, [230031] = 3000 },
        -- *ComHero(heroCfgId) 带主键数组
        hero = {
            [63503] = { heroCfgId = 63503, lv = 50 },
            [63502] = { heroCfgId = 63502, lv = 40 },
            [63501] = { heroCfgId = 63501, lv = 30 },
        },
        -- *ComBuild(id)
        city = { [1001] = { id = 1001, buildCfgId = 100, lv = 8 } },
        -- *ComIntInt() map: { [怪等级] = 击杀数 }
        lordKillNormalMonsterStat = { [1] = 10, [2] = 3 },
    })
    return sd
end

local function new_fake_client(sd)
    return {
        sync_data = sd,
        uid = 4000123,
        status = 6,                          -- STATE_IDLE
        login_web_data = { account = "A001" },
    }
end

----------------------------------------------------------------------
-- 用一个回包脚本驱动 Driver,返回实际发出的协议序列
-- responder(proto, args, n) -> result, err
----------------------------------------------------------------------
local function run_driver(responder, max_steps)
    local sd = new_sync_data()
    local fake = new_fake_client(sd)
    local drv = mod.Driver.new(fake)
    drv:set_account("A001")

    local protos = {}
    local guard = 0
    while not drv.finished and guard < (max_steps or 20) do
        guard = guard + 1
        drv.not_before = 0               -- 离线不等退避/观察窗口
        local proto, args = drv:next_request(sd)
        if proto then
            protos[#protos + 1] = proto

            local n = #protos
            local ok_enc, packed = pcall(req, proto, args, n, 0)
            check(ok_enc and type(packed) == "string" and #packed > 0,
                string.format("req#%d %s 可编码(%s bytes)", n, proto,
                    ok_enc and tostring(#packed) or "nil"), packed)

            local result, err = responder(proto, args, n)
            drv:record_response(proto, result, err)
        elseif not drv.finished then
            break                        -- 既没产出也没结束 = 卡住
        end
    end
    return drv, protos, sd
end

----------------------------------------------------------------------
-- 1) 正常路径:进场景 -> 设AOI -> 搜怪 -> 出征
----------------------------------------------------------------------
print("==== 1. 正常路径 ====")
local reported_before = reported
local drv1, protos1, sd1 = run_driver(function(proto)
    if proto == "findSceneObj" then
        return { objs = {
            { id = 51234567890, x = 600.5, y = 300.25, type = 131, configId = 10001, status = 1 },
        } }, 0
    elseif proto == "addTroop" then
        return { troopId = 90001 }, 0
    end
    return {}, 0
end)

local expect1 = { "enterScene", "setAoiPos", "findSceneObj", "addTroop" }
local same = (#protos1 == #expect1)
for i = 1, #expect1 do
    if protos1[i] ~= expect1[i] then same = false end
end
check(same, "协议顺序 enterScene -> setAoiPos -> findSceneObj -> addTroop",
    table.concat(protos1, ","))
check(drv1.ok == true, "流程判定 PASS", drv1.ok)
check(drv1.attack_done == 1, "出征计数 1", drv1.attack_done)
check(reported == reported_before + 1, "结束时调用 wrk.report_done(提前结束)")

local ctx1 = scene.get(sd1)
check(ctx1 and ctx1.enter_scene == true, "scene 状态:enter_scene=true")
check(ctx1 and ctx1.set_aoi == true, "scene 状态:set_aoi=true")
check(ctx1 and ctx1.scenes == 35338588258304, "scene 状态:场景 id 取自 world.scenes",
    ctx1 and ctx1.scenes)
check(ctx1 and (ctx1.stats.attack or 0) == 1, "scene 统计:attack=1",
    ctx1 and ctx1.stats.attack)

----------------------------------------------------------------------
-- 2) 异常分支:搜不到怪(532)后重试
----------------------------------------------------------------------
print("==== 2. 搜怪重试(532) ====")
local find_calls = 0
local drv2, protos2 = run_driver(function(proto)
    if proto == "findSceneObj" then
        find_calls = find_calls + 1
        if find_calls == 1 then
            return nil, def.ERR.CAN_NOT_FIND_OBJ      -- 第一次搜不到
        end
        return { objs = { { id = 70001, x = 610.5, y = 320.5, type = 131, configId = 10001, status = 1 } } }, 0
    elseif proto == "addTroop" then
        return { troopId = 90002 }, 0
    end
    return {}, 0
end)
check(find_calls == 2, "搜怪失败后重新搜索(共 2 次)", find_calls)
check(drv2.ok == true, "重试后流程仍 PASS", drv2.ok)
check(#protos2 == 5 and protos2[3] == "findSceneObj" and protos2[4] == "findSceneObj",
    "序列含两次 findSceneObj", table.concat(protos2, ","))

----------------------------------------------------------------------
-- 3) 异常分支:行军队列已满(502)后重试
----------------------------------------------------------------------
print("==== 3. 队列满重试(502) ====")
local add_calls = 0
local drv3, protos3 = run_driver(function(proto)
    if proto == "findSceneObj" then
        return { objs = { { id = 70002, x = 620.5, y = 330.5, type = 131, configId = 10001, status = 1 } } }, 0
    elseif proto == "addTroop" then
        add_calls = add_calls + 1
        if add_calls == 1 then
            return nil, def.ERR.TROOP_MAX_QUEUE       -- 第一次队列满
        end
        return { troopId = 90003 }, 0
    end
    return {}, 0
end)
check(add_calls == 2, "队列满后重新出征(共 2 次)", add_calls)
check(drv3.ok == true, "队列释放后流程 PASS", drv3.ok)

----------------------------------------------------------------------
-- 4) 超时看护:未收到同步数据时不产出请求
----------------------------------------------------------------------
print("==== 4. 同步未就绪 ====")
local sd4 = sync_mod.new()                       -- 空数据:world.scenes 为空
local fake4 = new_fake_client(sd4)
local drv4 = mod.Driver.new(fake4)
local proto4 = drv4:next_request(sd4)
check(proto4 == nil, "world.scenes 为空时不发请求", proto4)
check(drv4.finished == false, "未到超时前不判失败")
drv4.sync_deadline = os.time() - 1
drv4:next_request(sd4)
check(drv4.finished == true and drv4.ok == false, "超过同步等待上限判 FAIL")

print(string.format("\n==== 结果: PASS %d / FAIL %d ====", pass, fail))
if fail > 0 then os.exit(1) end
