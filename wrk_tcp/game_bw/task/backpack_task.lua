-- game_bw 业务任务:背包物品使用
-- 对应 Python PressureTest_BW_LHS/modules/backpack/backpack_task.py

local util = require "util"

local M = {}

-- 从 sync_data 取一个可用物品 id
local function pick_item_id(sync_data)
    local items = sync_data:get_all_items()
    local list = {}
    for id, info in pairs(items) do
        if (info.num or 0) > 0 then
            list[#list + 1] = id
        end
    end
    if #list > 0 then
        return list[util.rand_int(1, #list)]
    end
    return nil
end

-- 使用物品:useItem 201
-- 协议字段:id(玩家物品id)/itemCfgId(配置id)/num,二者互斥
M.use_item = {
    name = "useItem",
    weight = 2,
    generate_request = function(sync_data)
        local item_id = pick_item_id(sync_data)
        if not item_id then return nil end
        local num = sync_data:get_item_count(item_id)
        return "useItem", {
            id = item_id,
            num = math.min(num, util.rand_int(1, 5)),
        }
    end,
}

-- 批量使用物品:useItems 202
-- 协议字段:items2use (*ComUint32Uint32 列表, key=itemId, value=num)
M.use_items = {
    name = "useItems",
    weight = 1,
    generate_request = function(sync_data)
        local item_id = pick_item_id(sync_data)
        if not item_id then return nil end
        return "useItems", {
            items2use = { { key = item_id, value = util.rand_int(1, 3) } },
        }
    end,
}

-- 回收道具:recallItems 204
M.recall_items = {
    name = "recallItems",
    weight = 1,
    generate_request = function(sync_data)
        local item_id = pick_item_id(sync_data)
        if not item_id then return nil end
        return "recallItems", { itemId = item_id }
    end,
}

M.all_tasks = {
    M.use_item,
    M.use_items,
    M.recall_items,
}

return M
