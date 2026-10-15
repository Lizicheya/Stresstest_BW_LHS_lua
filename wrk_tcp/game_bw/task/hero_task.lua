-- game_bw 业务任务:英雄升级/升星/招募
-- 对应 Python PressureTest_BW_LHS/modules/hero/hero_task.py

local util = require "util"

local M = {}

-- 从 sync_data 取一个英雄 cfg id
local function pick_hero_cfg_id(sync_data)
    local heros = sync_data:get_hero_info()
    local list = {}
    for cfg_id, _ in pairs(heros) do
        list[#list + 1] = cfg_id
    end
    if #list > 0 then
        return list[util.rand_int(1, #list)]
    end
    return nil
end

-- 英雄等级升级:upgradeHeroLv 609
M.upgrade_hero_lv = {
    name = "upgradeHeroLv",
    weight = 2,
    generate_request = function(sync_data)
        local cfg_id = pick_hero_cfg_id(sync_data)
        if not cfg_id then return nil end
        return "upgradeHeroLv", { heroCfgId = cfg_id }
    end,
}

-- 英雄升星:upgradeHeroStarLv 602
M.upgrade_hero_star = {
    name = "upgradeHeroStarLv",
    weight = 1,
    generate_request = function(sync_data)
        local cfg_id = pick_hero_cfg_id(sync_data)
        if not cfg_id then return nil end
        return "upgradeHeroStarLv", { heroCfgId = cfg_id }
    end,
}

-- 重置英雄等级:resetHeroLv 604
M.reset_hero_lv = {
    name = "resetHeroLv",
    weight = 1,
    generate_request = function(sync_data)
        local cfg_id = pick_hero_cfg_id(sync_data)
        if not cfg_id then return nil end
        return "resetHeroLv", { heroCfgId = cfg_id }
    end,
}

-- 英雄技能升级:upgradeHeroSkill 601
-- 协议字段:heroCfgId + slotId(技能槽)
M.upgrade_hero_skill = {
    name = "upgradeHeroSkill",
    weight = 1,
    generate_request = function(sync_data)
        local cfg_id = pick_hero_cfg_id(sync_data)
        if not cfg_id then return nil end
        return "upgradeHeroSkill", {
            heroCfgId = cfg_id,
            slotId = util.rand_int(1, 3),
        }
    end,
}

-- 获取英雄背景奖励:getHeroBackgroundReward 603
-- 协议字段:heroCfgId + id(背景ID,这里用随机 1~3 占位)
M.get_hero_background_reward = {
    name = "getHeroBackgroundReward",
    weight = 1,
    generate_request = function(sync_data)
        local cfg_id = pick_hero_cfg_id(sync_data)
        if not cfg_id then return nil end
        return "getHeroBackgroundReward", {
            heroCfgId = cfg_id,
            id = util.rand_int(1, 3),
        }
    end,
}

M.all_tasks = {
    M.upgrade_hero_lv,
    M.upgrade_hero_star,
    M.reset_hero_lv,
    M.upgrade_hero_skill,
    M.get_hero_background_reward,
}

return M
