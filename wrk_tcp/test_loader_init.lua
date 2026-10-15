-- loader.lua / main_bw.init 独立测试脚本
-- 模拟 wrk.exe 中 script_start 的调用:加载 loader → 调用 main.init(id, connections)

-- 复用 loader 的 package 配置
local ok, err = xpcall(function()
    -- loader.lua 内部会 require main_bw,返回的 main 表上有 init
    local main = dofile("lualib/loader.lua")
    print("loader returned main:", type(main))
    print("main.init:", type(main.init))

    -- 调用 init(等同 wrk 中 script_start)
    main.init(1, 1)
    print("init called OK")
end, function(e)
    -- 错误处理:打印完整堆栈
    print("ERROR:", e)
    print(debug.traceback("", 2))
end)

if not ok then
    print("Test failed")
    os.exit(1)
end
