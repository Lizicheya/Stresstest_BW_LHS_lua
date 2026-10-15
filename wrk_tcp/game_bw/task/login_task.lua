-- game_bw 业务任务:账号初始化辅助(可选)
-- 对应 Python PressureTest_BW_LHS/modules/account/account_task.py
-- 登录主流程由 sproto_client 状态机驱动,这里仅保留少量初始化任务占位

local M = {}

-- 占位:登录后的城市初始化(实际可走 cheat 命令,见 cheat/cheat_task.lua)
M.common_login_sync = {
    name = "commonLoginSync",
    weight = 0,   -- 不参与随机调度,仅作占位登记
    generate_request = function(sync_data)
        return nil
    end,
}

M.all_tasks = {
    -- 暂不注册,实际按需扩展
}

return M
