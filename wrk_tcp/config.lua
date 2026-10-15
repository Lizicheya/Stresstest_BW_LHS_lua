-- 压测全局配置表:定义连接数、时长、线程、超时与目标地址等参数
local config = {
    connections = 20,      -- 并发连接数
    duration = 600,          -- 压测持续时长(秒,作为上限;全部用例提前跑完时可提前结束)
    early_stop = true,       -- 全部连接业务用例完成后是否提前结束压测(false 恢复死等完整时长)
    total_accounts = 20,    -- 压测账号总数(>0 时连接跑完一个账号自动换下一个,直至配额用尽;0=每连接仅 1 个账号)
    threads = 4,          -- 工作线程数
    timeout = 8000,        -- 单次请求超时时间(毫秒)

    --服务器相关配置
    ------------------------------------------------------------------------------------------
    host = "10.0.0.142",    -- 目标主机地址(真实游戏网关)
    -- port = 8007,            -- 目标主机端口
    port = 8007,            -- 登录服端口(reqlogin 在此发,响应后 reconnect 切到网关发 reqAuth)

    -- GM Web(cheat) 服务器:对应 Python aow_test_config.py 的 WebHost("10.0.0.142", 9007)
    -- cheat_task.curl_cheat 向该地址 POST JSON 作弊请求
    cheat_host = "10.0.0.142:9007",


    -- 账号文件配置(对应原项目 aow_test_config.py LoginLSTaskSet)
    -- 文件格式: 第0行 Record time, 第1行起每行 JSON {"user":"B202",...}
    -------------------------------------------------------------------------------------------
    test_spec_user = true,      -- 是否使用指定账号文件登录
    user_ids_file = "robot/ycf_b.txt",  -- 账号文件路径(相对 wrk 工作目录 wrk_tcp/)

    -- 网关地址:若 reqlogin 响应返回 gatewayHost/gatewayPort 则用返回值,否则用此默认值
    gateway_host = "127.0.0.1",
    gateway_port = 17793,

    -- 协议用例模板文件(xlsx):protocol_task 从该路径加载用例
    protocol_template_path = "game_bw/protocol/protocol_model-lhs.xlsx",

    -- 业务模块切换:
    --   "game"     -> 使用原 game/ 目录(login_client 简单登录流程)
    --   "game_bw"  -> 使用 game_bw/ 目录(sproto 全业务压测框架)
    game_module = "game_bw",
    -- 主入口文件名(对应目录下的 lua 文件,不含扩展名)
    --   game     -> main
    --   game_bw  -> main_bw
    -- main_entry = "main_bw",
    main_entry = "main_bw",
    loginAddr = "10.0.0.142:9007",
    url = "http://127.0.0.1:17788",  -- 压测目标 URL
}

return config
