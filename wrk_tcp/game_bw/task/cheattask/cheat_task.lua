-- game_bw GM 命令(HTTP 调用)
-- 对应 Python PressureTest_BW_LHS/modules/cheat/cheat_task.py
-- 通过 HTTP 接口调用游戏服务端的 cheat 端点,实现资源/物品/英雄等发放与设置
-- 注意:此模块在压测启动前(M.init 阶段)或独立脚本中调用,不参与 TCP 压测主循环

local http = require("socket.http")
local ltn12 = require "ltn12"
local json = require "cjson"
local config = require "config"
-- 同目录 cheat_defs.lua:提供英雄配置 id 列表等常量(新路径 task/cheattask/)
local cheat_defs = require "task.cheattask.cheat_defs"
-- lrandom:基于 Mersenne Twister(MT19937) 的随机数库
-- 注意:rock 名为 lrandom,但安装后模块名为 random,故 require "random"
-- 用法:local r = random.new(seed) 新建生成器;r:value() 取 [0,1) 浮点数;r:seed(n) 重置种子以复现
local random = require "random"

local M = {}

-- cheat 服务地址:取 game_bw/config.lua 的 cheat_host(对应 Python WebHost: 10.0.0.142:9007)
-- 注意:require "config" 加载的是 game_bw/config.lua(无 loginAddr 字段,勿用)
local CHEAT_HOST = config.cheat_host or "10.0.0.142:9007"
-- GM 端点路径:Python aow_url 为根路径 "http://host:port/"
local CHEAT_PATH = "/"
-- GM 签名常量(与 Python cheat_task.py generate_req_data 硬编码一致)
local CHEAT_SIGN = "6bb8c5202918721b84bf0d183b653c0e"

----------------------------------------------------------------------
-- 内部:发起一次 cheat HTTP GET 请求并返回解码后的响应表
-- action: cheat 动作名
-- params: 参数表(key -> value)
-- 返回: 解码后的响应表(失败返回 nil)
----------------------------------------------------------------------
local function curl_cheat(action, params)
    -- 请求体:{cmd, sign, time, data} 包装,data 为 xlsx pkt 解析出的参数表
    -- 与 Python generate_req_data 格式完全一致,嵌套表由 cjson 标准序列化
    local body = json.encode({
        cmd = action,
        sign = CHEAT_SIGN,
        time = 0,
        data = params or {},
    })
    local url = string.format("http://%s%s", CHEAT_HOST, CHEAT_PATH)
    -- 发送前日志:输出实际请求地址与请求体
    print(string.format("curl_cheat POST %s body=%s", url, body))
    -- POST + JSON body(luasocket 表参数形式,sink.table 收响应体)
    local sink_tbl = {}
    local ok, status_code = http.request({
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#body),
        },
        source = ltn12.source.string(body),
        sink = ltn12.sink.table(sink_tbl),
    })
    if not ok then
        io.stderr:write("curl_cheat request failed: url=" .. url .. " err=" .. tostring(status_code) .. "\n")
        io.stderr:flush()
        return nil
    end
    local result = table.concat(sink_tbl)
    if result == "" then return nil end
    local ok2, res = pcall(json.decode, result)
    if not ok2 then return nil end
    return res
end

-- 向 pkt 注入当前登录 uid(服务端按 uid 定位玩家,缺失报 cmd not found)
-- pkt 为 xlsx 用例数据,作为 data 直接透传给服务端(按服务端字段名填写)
local function with_uid(uid, pkt)
    pkt = pkt or {}
    pkt.uid = uid
    return pkt
end

----------------------------------------------------------------------
-- 通用:添加物品 OnAddItem
----------------------------------------------------------------------
function M.add_item(uid, pkt)
    return curl_cheat("addItem", with_uid(uid, pkt))
end

-- 批量添加物品
function M.add_items(uid, pkt)
    return curl_cheat("addItems", with_uid(uid, pkt))
end

-- 添加资源 addAssets
function M.add_assets(uid, pkt)
    return curl_cheat("addAssets", with_uid(uid, pkt))
end

-- 批量资源
function M.add_many_assets(uid, pkt)
    return curl_cheat("addManyAssets", with_uid(uid, pkt))
end

-- 基础资源(粮食/木材/石料/金币),pkt.num 指定数量(缺省 1000000)
function M.add_base_res(uid, pkt)
    pkt = pkt or {}
    local num = pkt.num or 1000000
    return curl_cheat("addManyAssets", with_uid(uid, {
        assets = {
            { type = 1, num = num },  -- 粮食
            { type = 2, num = num },  -- 木材
            { type = 3, num = num },  -- 石料
            { type = 4, num = num },  -- 金币
        },
    }))
end

-- 加兵 addArmy
function M.add_army(uid, pkt)
    return curl_cheat("addArmy", with_uid(uid, pkt))
end

-- 加英雄 add_hero_item
function M.add_hero_item(uid, pkt)
    return curl_cheat("addHero", with_uid(uid, pkt))
end

-- 添加全部英雄(cheatnewgethero)
function M.add_all_hero(uid, pkt)
    return curl_cheat("addAllHero", with_uid(uid, pkt))
end

-- 添加随机星级等级英雄(cheatnewgethero)
-- 对应 Python cheat_task.cheatnewgethero:遍历英雄列表,为每个英雄
-- 随机生成星级(5~25)与等级(40~100),逐个发送 addOneHero 作弊请求
-- uid: 当前登录账号 uid(服务端按 uid 定位玩家,缺失会导致 cmd not found)
function M.add_random_hero(uid, pkt)
    for _, hero_id in ipairs(cheat_defs.BW_HERO_LIST) do
        local star_lv = math.random(5, 25)
        local hero_lv = math.random(40, 100)
        curl_cheat("addOneHero", {
            uid = uid,
            heroCfgId = hero_id,
            starLv = star_lv,
            lv = hero_lv,
        })
    end
end

-- 英雄装备 add_hero_equip
function M.add_hero_equip(uid, pkt)
    return curl_cheat("addHeroEquip", with_uid(uid, pkt))
end

-- 徽章 add_badge_items
function M.add_badge_item(uid, pkt)
    return curl_cheat("addBadge", with_uid(uid, pkt))
end

-- 强制改建筑等级 forceChangeBuildLv
-- pkt: { buildCfgId = .., lv = .. }(对应 Python forceChangeBuildLv(build_id, build_lv))
function M.force_change_build_lv(uid, pkt)
    return curl_cheat("forceChangeBuildLv", with_uid(uid, pkt))
end

-- 全部建筑升至满级 forceChangeAllBuild2MaxLv
function M.force_all_build_max_lv(uid, pkt)
    return curl_cheat("forceChangeAllBuild2MaxLv", with_uid(uid, pkt))
end

-- 解锁城内区域 unlockCityAreaAll
function M.unlock_city_area_all(uid, pkt)
    return curl_cheat("unlockCityAreaAll", with_uid(uid, pkt))
end

-- 升全部科技 upAllTech
function M.up_all_tech(uid, pkt)
    return curl_cheat("upAllTech", with_uid(uid, pkt))
end

-- 联盟科技升至满级
function M.lv_up_all_alliance_tech_max(uid, pkt)
    return curl_cheat("lvUpAllAllianceTechnologyMax", with_uid(uid, pkt))
end

-- 完成章节 finishChapter(pkt: { chapterId = .. })
function M.finish_chapter(uid, pkt)
    return curl_cheat("finishChapter", with_uid(uid, pkt))
end

-- 设置任务奖励状态 setTaskAwardStatus
function M.set_task_award_status(uid, pkt)
    return curl_cheat("setTaskAwardStatus", with_uid(uid, pkt))
end

-- 改服务器时间 changeServerTime
function M.change_server_time(uid, pkt)
    return curl_cheat("changeServerTime", with_uid(uid, pkt))
end

-- 加雷达事件 addNewRadarEvent
function M.add_new_radar_event(uid, pkt)
    return curl_cheat("addNewRadarEvent", with_uid(uid, pkt))
end

-- 雷达刷新 radarRefresh
function M.radar_refresh(uid, pkt)
    return curl_cheat("radarRefresh", with_uid(uid, pkt))
end

-- 联盟建筑 placeAllianceBuild
function M.place_alliance_build(uid, pkt)
    return curl_cheat("placeAllianceBuild", with_uid(uid, pkt))
end

-- 活动发放 activityAdd
function M.activity_add(uid, pkt)
    return curl_cheat("activityAdd", with_uid(uid, pkt))
end

-- 加城市外观 add_city_dress
function M.add_city_dress(uid, pkt)
    return curl_cheat("addCityDress", with_uid(uid, pkt))
end

-- 取玩家信息 get_player_info
function M.get_player_info(uid, pkt)
    return curl_cheat("getPlayerInfo", with_uid(uid, pkt))
end

-- 导出通用 cheat 接口:直接调用服务端 cheat 端点
-- action: cheat 动作名
-- params: 参数表(key -> value)
-- 返回: 解码后的响应表(失败返回 nil)
M.curl_cheat = curl_cheat

return M