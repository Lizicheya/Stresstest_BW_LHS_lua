-- game_bw 业务任务:心跳与确认(轻量任务)
-- 对应 Python PressureTest_BW_LHS/modules/heart/heart_task.py
-- 心跳主流程由 sproto_client 状态机自动驱动,这里仅注册可选的 confirmNetMsg 任务

local M = {}

-- 服务器包确认:confirmNetMsg 13
-- 用于在空闲时主动确认服务器推送,降低服务端推送重试压力
M.confirm_net_msg = {
    name = "confirmNetMsg",
    weight = 1,
    generate_request = function(sync_data)
        -- sessionResponse/sessionSync 简化为 0,真实实现需记录最近推送的 session
        return "confirmNetMsg", { sessionResponse = 0, sessionSync = 0 }
    end,
}

-- 切换后台:switchBackground 12(低频,随机触发)
M.switch_background = {
    name = "switchBackground",
    weight = 1,
    generate_request = function(sync_data)
        return "switchBackground", { isBackground = false }
    end,
}

M.all_tasks = {
    M.confirm_net_msg,
    M.switch_background,
}

return M
