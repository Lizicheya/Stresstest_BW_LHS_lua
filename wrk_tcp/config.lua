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
    -- port = 8007,            -- 目标主机端口；登录服端口(reqlogin 在此发,响应后 reconnect 切到网关发 reqAuth)   ---虎生服
    port = 8007,            -- -李虎生
    -- port = 8005,               ---先习服
    -- port = 8011,               ---SDK服

    -- GM Web(cheat) 服务器:对应 Python aow_test_config.py 的 WebHost("10.0.0.142", 9007)
    -- cheat_task.curl_cheat 向该地址 POST JSON 作弊请求
    cheat_host = "10.0.0.142:9007",        --虎生服
    -- cheat_host = "10.0.0.142:9005",           --先习服
    -- cheat_host = "10.0.0.142:9011",           --SDK服

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

-------------------------------------------------------------------------------------------
-- 单账号联调用例入口覆盖(默认关闭,不影响正常压测)
-- 设置环境变量 WRK_MAIN_ENTRY 时:改用该入口,并把并发压到 1 连接 / 1 线程、关闭账号轮换。(要执行的文件在下述的批处理文件中修改)
-- 供 game_bw/test/test_find_attack_monster.lua 这类「单账号真实登录 + 指定业务步骤」的
-- 调试用例使用(由 run_test_find_attack_monster.bat 设置,见该批处理说明)。
-------------------------------------------------------------------------------------------
local test_entry = os.getenv("WRK_MAIN_ENTRY")
if test_entry and test_entry ~= "" then
    config.main_entry     = test_entry
    config.connections    = 1
    config.threads        = 1
    config.duration       = tonumber(os.getenv("WRK_TEST_DURATION") or "") or 180
    config.total_accounts = 0                          -- 0 = 不轮换账号
    config.early_stop     = true
    config.test_spec_user = true
    config.user_ids_file  = os.getenv("WRK_TEST_ACCOUNT_FILE") or "robot/ycf_a.txt"
end

return config
