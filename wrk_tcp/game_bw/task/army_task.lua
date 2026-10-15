-- game_bw 业务任务:军队训练/收集/升级/治疗
-- 对应 Python PressureTest_BW_LHS/modules/army/army_task.py
-- 每个 task 是一个表: { name, weight, generate_request(sync_data) -> proto_name, args }

local util = require "util"

local M = {}

-- 默认兵种配置 id 列表(实际应从配置表读取,这里给常见值)
local DEFAULT_ARMY_CFG_IDS = { 1001, 1002, 1003, 1004 }

-- 从 sync_data 取一个可用兵种 id,没有则用默认
local function pick_army_cfg_id(sync_data)
    local armys = sync_data:get_all_armys()
    for cfg_id, _ in pairs(armys) do
        return cfg_id
    end
    return DEFAULT_ARMY_CFG_IDS[util.rand_int(1, #DEFAULT_ARMY_CFG_IDS)]
end

-- 训练军队:trainArmy 1001
M.train_army = {
    name = "trainArmy",
    weight = 3,
    generate_request = function(sync_data)
        local cfg_id = pick_army_cfg_id(sync_data)
        return "trainArmy", {
            armyCfgId = cfg_id,
            num = util.rand_int(10, 100),
            trainItemCfgId = 0,
            trainExchangeCfgId = 0,
            immediately = false,
        }
    end,
}

-- 收集训练完成的兵:collectArmy 1002
M.collect_army = {
    name = "collectArmy",
    weight = 2,
    generate_request = function(sync_data)
        return "collectArmy", { armyType = 0 }
    end,
}

-- 升级兵种:upgradeArmy 1004
M.upgrade_army = {
    name = "upgradeArmy",
    weight = 1,
    generate_request = function(sync_data)
        local cfg_id = pick_army_cfg_id(sync_data)
        return "upgradeArmy", {
            oldArmyCfgId = cfg_id,
            armyCfgId = cfg_id + 1,
            num = util.rand_int(10, 50),
            immediately = false,
        }
    end,
}

-- 治疗伤兵:healWoundedArmy 1005
M.heal_wounded_army = {
    name = "healWoundedArmy",
    weight = 1,
    generate_request = function(sync_data)
        -- 取所有伤兵并治疗
        local wounded = sync_data.wounded_armys or {}
        local id2num = {}
        for cfg_id, num in pairs(wounded) do
            if num > 0 then
                id2num[#id2num + 1] = { key = cfg_id, value = num }
            end
        end
        if #id2num == 0 then
            -- 无伤兵则跳过,返回 nil 让 task_manager 选下一个
            return nil
        end
        return "healWoundedArmy", {
            id2num = id2num,
            immediately = false,
        }
    end,
}

-- 收集治疗完成的兵:collectHealArmy 1007
M.collect_heal_army = {
    name = "collectHealArmy",
    weight = 1,
    generate_request = function(sync_data)
        return "collectHealArmy", {}
    end,
}

-- 导出所有任务列表
M.all_tasks = {
    M.train_army,
    M.collect_army,
    M.upgrade_army,
    M.heal_wounded_army,
    M.collect_heal_army,
}

return M
