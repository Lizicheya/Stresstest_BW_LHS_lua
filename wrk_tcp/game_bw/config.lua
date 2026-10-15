-- game_bw 压测配置表
-- 定义登录流程、协议槽位、Web 登录与目标服务器参数
-- 首先 dofile 根 config.lua(压测全局配置),然后 game_bw 自身字段覆盖/补充
-- 这样 game_bw 子目录下所有 require "config" 能同时看到根配置(game_module,threads,
-- connections,total_accounts,host,port 等)和本配置(game_bw 特有字段)
local root_cfg = {}
pcall(function()
    local ok, t = pcall(dofile, "config.lua")
    if ok and type(t) == "table" then
        root_cfg = t
    end
end)

local bw_cfg = {
    -- 客户端逻辑模块名:由 main.lua 通过 require 加载,负责单连接的状态机
    procedure = "client.game_client",

    -- sproto 协议槽位(对应 proto.register/load 的 index)
    proto_index = 1,
    -- 协议文件名(放在 lualib/protocol/<name>.proto),可拼接多个
    proto_files = { "c2s" },

    -- package 类型名(c2s.sproto 中 .package),用于会话确认
    package_type = "package",

    -- sproto TCP 登录参数(对应原 Python aow_test_config.py 的 LoginHost)
    -- wrk 的 TCP 连接目标由根 config.lua 的 host/port 指定,这里不再重复
    -- 登录默认不需要密码: reqlogin 仅含 account + sdkToken
    -- sdkToken 按原项目 com.py 逻辑: 10.0.0.142:8007 不匹配 skip 分支, 用 ""
    sdk_token = "",              -- reqlogin.sdkToken 字段
    server_id = 1,               -- reqlogin.serverId 字段(仅 create_new_role=true 时发送)
    create_new_role = false,    -- reqlogin.createNewRole 字段(false 时不发送 serverId/createNewRole)

    -- 心跳间隔(秒):调大降低心跳干扰,给业务任务更多带宽
    heartbeat_interval = 30,

    -- 请求超时(秒):STATE_WAIT_RESP 超过该时间无响应则重置为 IDLE,避免连接卡死
    request_timeout = 5,

    -- confirmNetMsg 冷却(秒):避免每次 IDLE 都发占位请求,降低非业务流量
    confirm_cooldown = 3,

    -- 任务预设名:light/normal/heavy/combat/gather,详见 pressure/task_manager.lua
    task_preset = "normal",

    -- 是否在连接后立即跑业务任务(否则仅维持登录+心跳)
    enable_tasks = true,

    -- 调试日志开关:false 关闭高频诊断日志(writeable/readable/dispatch 等),
    -- 正式压测时避免 stderr 刷屏开销;排障时改为 true
    debug = false,
}

-- 合并:根配置作为基础,game_bw 自身字段覆盖根同名字段
-- 根配置字段(threads,connections,total_accounts,host,port,duration 等)在 game_bw 下
-- 的 require "config" 中也能直接访问,不再需要 main_bw.lua 额外 dofile
for k, v in pairs(bw_cfg) do
    root_cfg[k] = v
end

return root_cfg