-- scene_task 冒烟测试(离线,不连服务器)
-- 目的:用构造的登录同步数据驱动沙盘状态机,验证
--   1) sync_data 的取值接口(get_building_lv / get_max_kill_monster / get_server_day)
--   2) 进场景 -> 搜索 -> 出征 的请求产出与状态推进
--   3) 采集 / 加速 / 迁城 / xlsx 分发入口
--   4) 产出的请求能被 c2s.sproto 正常编码
--
-- 运行(必须在 wrk_tcp 目录下,proto 加载按 "./lualib/protocol/" 相对路径):
--   set PATH=E:\LuaYaCe\wrk_tcp;%PATH%
--   E:\LuaYaCe\luarocks\bin\lua.exe test_scene_task.lua

package.path = "lualib/?.lua;lualib/?/init.lua;game_bw/?.lua;game_bw/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;" .. package.cpath

-- wrk 定制版 Lua 把模块名的 "." 换成 "/",标准 lua.exe 没有这个 searcher,这里补上,
-- 否则 require "scene.scene_task" 会去找 game_bw/scene.scene_task.lua
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
local scene = require "scene.scene_task"
local def = require "scene.scene_def"

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

local function dump_proto(proto, args)
    local parts = {}
    for k, v in pairs(args or {}) do
        if type(v) == "table" then
            parts[#parts + 1] = k .. "={...}"
        else
            parts[#parts + 1] = k .. "=" .. tostring(v)
        end
    end
    table.sort(parts)
    return tostring(proto) .. " [" .. table.concat(parts, ", ") .. "]"
end

-- 统计 map/数组的条目数(sproto map 形态不能用 # 取长度)
local function count_entries(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

----------------------------------------------------------------------
-- 1) 构造登录同步数据
----------------------------------------------------------------------
-- 按服务端真实解码形状构造:sproto 的 `*Type(主键)` / `*Type()` 字段落地后
-- 都是「键 -> 值」的映射表,不是 1..n 的数组
local LOGIN = {
    serverTime = 1700000000,
    serverOpenTime = 1700000000 - 86400 * 10,     -- 开服第 11 天
    world = {
        castleX = 700,
        castleY = 300,
        -- *ComIntInt() 是 sproto map:解码结果是 { [sceneId] = sceneCfgId }
        scenes = { [35338588258304] = 10119 },
    },
    -- *ComArmyIdAndNum() 是 sproto map: { [兵种id] = 数量 }
    army = {
        [230011] = 8000,
        [230021] = 5000,
        [230031] = 3000,
    },
    -- *ComHero(heroCfgId) 是带主键数组: { [heroCfgId] = ComHero }
    hero = {
        [63503] = { heroCfgId = 63503, lv = 50 },
        [63502] = { heroCfgId = 63502, lv = 40 },
        [63501] = { heroCfgId = 63501, lv = 30 },
    },
    -- *ComBuild(id) 同上
    city = {
        [1001] = { id = 1001, buildCfgId = 100, lv = 8 },
        [1091] = { id = 1091, buildCfgId = 109, lv = 1 },
    },
    -- *ComIntInt() map: { [lv] = 击杀数 }
    lordKillNormalMonsterStat = {
        [1] = 10,
        [2] = 3,
    },
}

local sd = sync_mod.new()
sd:handle_sync_login_data(LOGIN)

print("==== 1. sync_data 取值 ====")
check(sd:get_building_lv(100) == 8, "get_building_lv(100) == 8", sd:get_building_lv(100))
check(sd:get_building_lv(109) == 1, "get_building_lv(109) == 1", sd:get_building_lv(109))
check(sd:get_building_lv(153) == -1, "get_building_lv(153) == -1(缺失返回 -1)", sd:get_building_lv(153))
check(sd:get_max_kill_monster() == 3, "get_max_kill_monster() == 3(已杀最高2级+1)", sd:get_max_kill_monster())
check(sd:get_server_day() == 11, "get_server_day() == 11", sd:get_server_day())
check(sd.castle_x == 700 and sd.castle_y == 300, "castle 坐标落地", sd.castle_x .. "," .. sd.castle_y)

----------------------------------------------------------------------
-- 2) 进场景 -> 设置 aoi
----------------------------------------------------------------------
print("==== 2. 进场景链路 ====")
local ctx = scene.get(sd)
check(ctx ~= nil, "scene.get 创建上下文")

local proto, args = ctx:set_aoi_pos_first()
print("  -> " .. dump_proto(proto, args))
check(proto == "enterScene", "首个请求是 enterScene", proto)
check(args.sceneId == 35338588258304, "enterScene.sceneId 取自 world.scenes[1].key", args.sceneId)

ctx:on_response("enterScene", {}, 0)
check(ctx.enter_scene == true, "enterScene 成功后 enter_scene = true")

proto, args = ctx:set_aoi_pos_first()
print("  -> " .. dump_proto(proto, args))
check(proto == "setAoiPos", "第二个请求是 setAoiPos", proto)
check(args.sceneId == 35338588258304 and args.lod == 1, "setAoiPos 携带 sceneId/lod", args.sceneId)

ctx:on_response("setAoiPos", {}, 0)
check(ctx.set_aoi == true, "setAoiPos 成功后 set_aoi = true")
check(ctx:set_aoi_pos_first() == nil, "已设 aoi 后不再重复请求")

----------------------------------------------------------------------
-- 3) 搜索怪 -> 出征
----------------------------------------------------------------------
print("==== 3. 搜索 + 出征 ====")
proto, args = ctx:step_attack_monster()
print("  -> " .. dump_proto(proto, args))
check(proto == "findSceneObj", "无目标时先 findSceneObj", proto)
check(args.objType == 131, "objType == 131(普通怪)", args.objType)
check(args.objCfgId == 10001 + ctx.monster_max_lv - 1,
    "objCfgId = 10001 + 可打等级 - 1", args.objCfgId)

ctx:on_response("findSceneObj", {
    objs = { { id = 51234567890, x = 600.5, y = 300.25, type = 131, configId = 10003, status = 1 } },
}, 0)
check(ctx.found ~= nil and ctx.found.id == 51234567890, "findSceneObj 结果缓存到 found", ctx.found and ctx.found.id)

proto, args = ctx:step_attack_monster()
print("  -> " .. dump_proto(proto, args))
check(proto == "addTroop", "命中目标后发 addTroop", proto)
check(args.targetId == 51234567890, "addTroop.targetId 命中对象 id", args.targetId)
check(type(args.targetX) == "number" and args.targetX == 600.5, "targetX 为 double 坐标", args.targetX)
check(type(args.army) == "table" and count_entries(args.army) > 0, "army 使用 sync_data 兵种组建", args.army and count_entries(args.army))
check(type(args.heros) == "table" and count_entries(args.heros) == 3, "heros 按英雄表组建(3 个)", args.heros and count_entries(args.heros))
check(args.isAutoBack == true and args.formationId == 1, "携带 isAutoBack/formationId", args.formationId)

ctx:on_response("addTroop", { troopId = 90001 }, 0)
check(ctx.found == nil, "出征成功后清空 found,下一轮重新搜索")
check(sd.troops[90001] ~= nil, "出征部队登记到 sync_data.troops")

----------------------------------------------------------------------
-- 4) 加速
----------------------------------------------------------------------
print("==== 4. 加速 ====")
sd.troops[90001].status = def.SceneObjStatusType.MARCHING
proto, args = ctx:next_speed_up()
print("  -> " .. dump_proto(proto, args))
check(proto == "troopSpeedUp", "行军中的部队可加速", proto)
check(args.id == 90001, "加速目标为行军中部队", args.id)
check(args.items2use[def.DEFAULT.speed_up_item] == 1, "使用加速道具 230004", args.items2use and args.items2use[def.DEFAULT.speed_up_item])

----------------------------------------------------------------------
-- 5) 迁城
----------------------------------------------------------------------
print("==== 5. 迁城 ====")
proto, args = ctx:move_castle(675, 221, 30, 20, "normal")
print("  -> " .. dump_proto(proto, args))
check(proto == "moveCastle", "迁城发 moveCastle", proto)
check(args.x >= 645 and args.x <= 705, "x 落在中心 ± 半径内", args.x)
check(args.resExchanges[def.DEFAULT.move_item] == 1, "使用迁城道具 240005", args.resExchanges and args.resExchanges[def.DEFAULT.move_item])
local mv_x, mv_y = args.x, args.y
ctx:on_response("moveCastle", {}, 0)
check(ctx.castle_x == mv_x and ctx.castle_y == mv_y, "迁城成功后本地坐标更新", ctx.castle_x .. "," .. ctx.castle_y)

----------------------------------------------------------------------
-- 6) 采集
----------------------------------------------------------------------
print("==== 6. 采集 ====")
ctx.found = nil
proto, args = ctx:step_collect_res({ res_obj_id = def.RES_CFG.WOOD })
print("  -> " .. dump_proto(proto, args))
check(proto == "findSceneObj" and args.objType == 2, "采集先搜资源点(objType 2)", args.objType)
check(args.objCfgId == 30011, "资源点配置 id 30011(伐木场)", args.objCfgId)

ctx:on_response("findSceneObj", {
    objs = { { id = 7712345678, x = 500, y = 500, type = 2, configId = 30011, status = 1 } },
}, 0)
proto, args = ctx:step_collect_res({ res_obj_id = def.RES_CFG.WOOD })
print("  -> " .. dump_proto(proto, args))
check(proto == "addTroop" and args.targetId == 7712345678, "资源点命中后发 addTroop", args.targetId)
check(args.isRally == nil and args.isRadar == nil, "采集部队不带 isRally/isRadar")

----------------------------------------------------------------------
-- 7) 未进场景(552)兜底
----------------------------------------------------------------------
print("==== 7. 552 未进场景兜底 ====")
ctx:on_response("findSceneObj", {}, def.ERR.NOT_ENTER_SCENE)
check(ctx.set_aoi == false and ctx.enter_scene == false, "552 后重置 aoi/enter 状态")
proto = ctx:step_attack_monster()
check(proto == "enterScene", "下一轮自动重新 enterScene", proto)

----------------------------------------------------------------------
-- 8) xlsx 分发入口
----------------------------------------------------------------------
print("==== 8. SceneTask.xxx 分发 ====")
local sd2 = sync_mod.new()
sd2:handle_sync_login_data({
    serverTime = 1700000000,
    serverOpenTime = 1700000000 - 86400,
    world = { castleX = 1, castleY = 2, scenes = { [999] = 10119 } },
})
scene.get(sd2)
proto, args = scene.call("enterScene", sd2, {})
check(proto == "enterScene" and args.sceneId == 999, "SceneTask.enterScene -> enterScene", proto)
scene.on_response(sd2, "enterScene", {}, 0)

-- 场景类业务请求统一前置:未设 aoi 时先补 setAoiPos(否则服务端回 552)
proto, args = scene.call("attackMonster", sd2, { monsterLv = "5", isRally = "true" })
check(proto == "setAoiPos", "aoi 未就绪时 attackMonster 先补 setAoiPos", proto)
scene.on_response(sd2, "setAoiPos", {}, 0)

proto, args = scene.call("attackMonster", sd2, { monsterLv = "5", isRally = "true" })
check(proto == "findSceneObj", "未命中目标时 attackMonster 先搜索", proto)
check(args.objCfgId == 10001, "monsterLv=\"5\" 解析为整数(可打等级 1)", args.objCfgId)

proto, args = scene.call("moveCastle", sd2, { centerX = "600", centerY = "600", rangeNum = "10" })
check(proto == "moveCastle" and args.x >= 590 and args.x <= 610,
    "camelCase 参数解析(centerX/centerY/rangeNum)", args and args.x)

local p3, a3 = scene.call("status", sd2, {})
check(p3 == nil and a3 and a3.reason, "status 为纯本地动作,不产出请求", p3)

local p4, a4 = scene.call("noSuchMethod", sd2, {})
check(p4 == nil and a4 and a4.err == -1, "未知方法返回错误", a4 and a4.reason)

----------------------------------------------------------------------
-- 9) 协议编码校验
----------------------------------------------------------------------
print("==== 9. c2s.sproto 编码校验 ====")

-- wrk 定制版把 sproto.core 静态注册在 exe 内,标准 lua.exe 需手动加载 DLL
if not package.loaded["sproto.core"] then
    local openf = package.loadlib("lualib/sproto.dll", "luaopen_sproto_core")
    if openf then
        local ok, mod = pcall(openf)
        if ok then package.loaded["sproto.core"] = mod end
    end
end

local ok_pb, pb_or_err = pcall(function()
    local loader = require "protocol.proto"
    loader.register(1, "c2s")
    return loader.load(1)
end)

if not ok_pb then
    print("[SKIP] sproto 加载失败,跳过编码校验: " .. tostring(pb_or_err))
else
    local pb = pb_or_err
    local host = pb:host("package")
    local req = host:attach(pb)

    local samples = {
        { "enterScene", { sceneId = 35338588258304 } },
        { "setAoiPos", { x = 0, y = 0, lod = 1, sceneId = 35338588258304 } },
        { "findSceneObj", { objType = 131, objCfgId = 10003, isFullRes = false,
                            isIncludeOccupyRes = false, isRadar = false, objIds = {} } },
        -- army / heros / items2use / resExchanges 都是 sproto map 形态 `*Type()`:
        -- Lua 侧必须写 { [键] = 值 },写 {{id=..,num=..}} 会让编码器把 entry 表当整数
        { "addTroop", {
            army = { [230011] = 495, [230021] = 495, [230031] = 495 },
            heros = { [1] = 63503, [2] = 63502 },
            targetId = 51234567890, targetX = 600.5 + 0.0, targetY = 300.25 + 0.0,
            isAutoBack = true, formationId = 1,
          } },
        { "addTroop", { isScout = true, targetId = 51234567890 } },
        { "troopSpeedUp", { id = 90001, items2use = { [230004] = 1 } } },
        { "moveCastle", { moveType = 1, x = 675, y = 221,
                          resExchanges = { [240005] = 1 } } },
        { "getObjDetailInfo", { objId = 51234567890 } },
        { "getBuffHoldList", {} },
        { "setAutoRallyInfo", { isOpen = true, addTroopType = 0, selectedBoss = { 5 } } },
        { "quitScene", {} },
    }

    for _, s in ipairs(samples) do
        local name, msg = s[1], s[2]
        local ok_enc, packed = pcall(req, name, msg, 1, 0)
        if ok_enc and type(packed) == "string" and #packed > 0 then
            check(true, string.format("encode %s ok (%d bytes)", name, #packed))
        else
            check(false, string.format("encode %s failed", name), packed)
        end
    end

    ------------------------------------------------------------------
    -- 9b) 真实链路产出再编码:状态机组装的包必须能直接编码
    -- (样本表是手写的,这里再用真跑出来的 args 兜一遍,防止组包形状回归)
    ------------------------------------------------------------------
    local sd2 = sync_mod.new()
    sd2:handle_sync_login_data(LOGIN)
    local ctx2 = scene.get(sd2)
    local real = {}

    local function record(proto_name, argv)
        if proto_name then real[#real + 1] = { proto_name, argv } end
    end

    local p, a = ctx2:set_aoi_pos_first()          -- enterScene
    record(p, a)
    ctx2:on_response("enterScene", {}, 0)

    p, a = ctx2:set_aoi_pos_first()                -- setAoiPos
    record(p, a)
    ctx2:on_response("setAoiPos", {}, 0)

    p, a = ctx2:step_attack_monster()              -- findSceneObj
    record(p, a)
    ctx2:on_response("findSceneObj", {
        objs = { { id = 51234567890, x = 600.5, y = 300.25, type = 131, configId = 10003, status = 1 } },
    }, 0)

    p, a = ctx2:step_attack_monster()              -- addTroop(带 army/heros)
    record(p, a)
    ctx2:on_response("addTroop", { troopId = 90001 }, 0)

    sd2.troops[90001].status = def.SceneObjStatusType.MARCHING
    p, a = ctx2:next_speed_up()                    -- troopSpeedUp
    record(p, a)

    p, a = ctx2:move_castle(675, 221, 30, 20, "normal")
    record(p, a)

    for _, r in ipairs(real) do
        local ok_enc, packed = pcall(req, r[1], r[2], 1, 0)
        check(ok_enc and type(packed) == "string" and #packed > 0,
            string.format("真实链路 encode %s ok", tostring(r[1])), packed)
    end
end

print(string.format("\n==== 结果: PASS %d / FAIL %d ====", pass, fail))
if fail > 0 then os.exit(1) end
