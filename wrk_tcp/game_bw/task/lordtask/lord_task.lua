local util = require "util"
-- game_bw 业务任务:领主相关协议发送
-- 对应 Python PressureTest_BW_LHS/modules/lord/lord_task.py
-- cmd_module 为 LordTask.xxx 时由 protocol_task._handle_lord_task 分发到本模块

local M = {}

----------------------------------------------------------------------
-- 改名为当前账号名
-- cmd_module: LordTask.rename_user
-- 协议: c2s.sproto 中 rename 3001
--   request { name 0: string, items2use 1: *ComUint32Uint32() }
-- 参数传入: task_ctx 为 protocol_task 实例(可访问 task_ctx.account 取账号名)
-- 返回: (sproto_name, msg) 兼容 next_request 接口
----------------------------------------------------------------------
function M.rename_user(task_ctx, case, pkt)
    -- 玩家账号名:优先用 task_ctx.account(由 sproto_client 回填的登录账号)
    -- 兜底取 pkt.name(允许用例显式指定)
    local account_name = (task_ctx and task_ctx.account) or (pkt and pkt.name) or ""
    local msg = {
        name = tostring(account_name),
        items2use = (pkt and pkt.items2use) or {},
    }
    return "rename", msg
end

return M