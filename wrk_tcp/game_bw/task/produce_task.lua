-- game_bw 业务任务:生产/采集
-- 对应 Python PressureTest_BW_LHS/modules/produce/produce_task.py
-- 涉及协议:collectResource 1101(资源建筑)/ collectSpeedUp 78(部队采集加速)

local util = require "util"

local M = {}

-- 从 sync_data 取资源建筑 id 列表
local function pick_res_build_ids(sync_data)
    local builds = sync_data:get_building_list()
    local ids = {}
    for bid, _ in pairs(builds) do
        -- 简化:取所有建筑 id,实际应按类型过滤资源建筑
        ids[#ids + 1] = bid
    end
    return ids
end

-- 从 sync_data 取一个部队 id(collectSpeedUp 需要)
local function pick_troop_id(sync_data)
    local troops = sync_data:get_all_troops() or {}
    for tid, _ in pairs(troops) do
        return tid
    end
    return nil
end

-- 收集资源:collectResource 1101
-- 协议字段:buildIds (*uint32 资源建筑 id 列表)
M.collect_resource = {
    name = "collectResource",
    weight = 3,
    generate_request = function(sync_data)
        local ids = pick_res_build_ids(sync_data)
        if #ids == 0 then return nil end
        return "collectResource", { buildIds = ids }
    end,
}

-- 采集加速:collectSpeedUp 78
-- 协议字段:id (uint64 部队 id)
M.collect_speed_up = {
    name = "collectSpeedUp",
    weight = 1,
    generate_request = function(sync_data)
        local tid = pick_troop_id(sync_data)
        if not tid then return nil end
        return "collectSpeedUp", { id = tid }
    end,
}

M.all_tasks = {
    M.collect_resource,
    M.collect_speed_up,
}

return M
