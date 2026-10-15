-- 游戏登录配置表:定义登录流程使用的过程名、AppID、登录地址与登录 URL 模板
return {
    procedure = "login_client",          -- 登录过程使用的客户端逻辑模块名
    appID = "1234567890",                -- 应用唯一标识 AppID
    loginAddr = "127.0.0.1:17788",       -- Web 登录服务地址
    loginMsg = "http://%s/login?account=%s&pass=%s&appid=%s&name=%s&device=%s&platform=%s&channel=%s",  -- 登录请求 URL 格式模板
}
