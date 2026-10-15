-- game_bw 压测主调度入口
-- 对应 Python PressureTest_BW_LHS/pythonTest1/run_pressure_test.py + modules/pressure/locust_client.py
-- 职责:账号准备/Web 登录、协议注册、连接管理、收发分发、任务管理器装配

local proto_util = require "proto_util"
local netpack = require "netpack"
local config = require "config"
local util = require "util"
local cjson = require "cjson"

local protocol_task_mod = require "protocol.protocol_task"

local M = {}

local count = 0               -- 已生成的账号计数器(回退用,无账号文件时)
local identify                -- 当前线程标识

local clients = {}            -- fd -> 客户端对象 映射表

local queue                   -- netpack 解包队列

local user_ids = {}           -- 从账号文件载入的账号列表
local client_seq = 0          -- 已连接的客户端序号(循环分配账号用)
local root_threads = 1        -- 根 config.lua 的线程数(账号跨步分配用)
local root_host, root_port    -- 根 config.lua 的登录服地址(账号轮换/重登切回登录服用)
local early_stop = true       -- 全部任务完成后提前结束压测(根 config.lua early_stop 可关)
local had_client = false      -- 本线程是否建立过连接(启动阶段防误判完成)
local done_reported = false   -- 是否已向 C 层上报任务完成(每线程仅一次)
local last_done_check = 0     -- 上次完成检测时间戳(每秒最多检测一次)
local total_accounts = 0      -- 压测账号总数上限(根 config.lua total_accounts,0 表示不轮换账号)

-- 生成一个全局唯一的压测账号名
local function get_account()
    count = count + 1
    return "bwplayer" .. identify .. "_" .. count
end

----------------------------------------------------------------------
-- 分配下一个压测账号:线程跨步 gidx = seq*threads + identify,各线程索引互不重叠
-- 连接建立与账号轮换共用此分配器,client_seq 持续递增直至账号配额用尽
-- 返回: 账号名, 全局序号; 无账号文件或配额用尽时返回 nil
----------------------------------------------------------------------
local function next_account()
    if not config.test_spec_user or #user_ids == 0 then return nil end
    local gidx = client_seq * root_threads + identify
    if gidx > #user_ids then return nil end
    -- total_accounts > 0 时启用轮换并限制账号总数,0 表示仅初始连接各用 1 个账号
    if total_accounts > 0 and gidx > total_accounts then return nil end
    client_seq = client_seq + 1
    return user_ids[gidx], gidx
end

-- 账号轮换开关:total_accounts > 0 且使用账号文件时,连接跑完用例后自动换下一个账号
local function rotation_enabled()
    return total_accounts > 0 and config.test_spec_user and #user_ids > 0
end

----------------------------------------------------------------------
-- 初始化:登录 Web 获取所有账号凭证,注册 c2s.sproto,初始化 sproto host
----------------------------------------------------------------------
function M.init(id, connections)
    identify = id
    local start = os.time()

    -- 本模块 require "config" 加载的是 game_bw/config.lua(不含 threads),
    -- 这里按 loader.lua 同样的方式 dofile 根 config.lua 取线程数,
    -- 保证与 C 层读取的 threads 单一数据源
    local ok_cfg, root_cfg = pcall(dofile, "config.lua")
    if ok_cfg and type(root_cfg) == "table" and root_cfg.threads then
        root_threads = root_cfg.threads
        -- 仅显式配置 false 时关闭提前结束,nil/true 均视为开启
        early_stop = root_cfg.early_stop ~= false
        -- 压测账号总数上限:>0 时开启账号轮换,连接跑完用例自动换下一个账号
        total_accounts = tonumber(root_cfg.total_accounts) or 0
        -- 登录服地址:reqlogin 只能发往登录服,轮换/重登时需从网关切回
        root_host = root_cfg.host
        root_port = root_cfg.port
    end

    -- 初始化 sproto:内部会注册 c2s 协议(pcall 容错)并创建 host
    proto_util.init()

    -- 载入账号文件(对应原项目 com.py get_self_user 的文件读取)
    -- 格式: 第0行 Record time(跳过), 第1行起每行 JSON {"user":"B202",...}
    if config.test_spec_user and config.user_ids_file then
        local f = io.open(config.user_ids_file, "r")
        if f then
            local lines = {}
            for line in f:lines() do
                if line and line ~= "" then
                    lines[#lines + 1] = line
                end
            end
            f:close()
            -- 从第2行起解析 JSON 取 user 字段
            for i = 2, #lines do
                local ok, data = pcall(cjson.decode, lines[i])
                if ok and type(data) == "table" and data.user then
                    user_ids[#user_ids + 1] = data.user
                end
            end
            print("game_bw load accounts from " .. config.user_ids_file .. ", count:" .. #user_ids)
        else
            print("game_bw account file not found: " .. config.user_ids_file .. ", fallback to generated account")
        end
    end

    local endt = os.time()
    print("game_bw init thread id:" .. id .. " delta:" .. (endt - start) .. "s")

    -- 初始化随机种子
    math.randomseed(os.time() + identify * 1000)
end

----------------------------------------------------------------------
-- 新连接建立回调:为该 fd 创建客户端对象并启动登录流程
----------------------------------------------------------------------
function M.connected(fd)
    had_client = true
    -- fd 复用场景:_on_reconnect(oldfd, newfd) 可能把 client 迁移到 newfd,
    -- 而 newfd 可能是另一个连接的活跃 fd(OS fd 复用,无法控制),
    -- 导致 clients[fd] 已存在(迁移过来的 client),但其 task_mgr 为 nil(未注入),
    -- 原逻辑直接 return 会让该 client 永远无 task,IDLE 状态产不出业务请求。
    -- 修复:已存在时重新注入 task_manager,确保每个 client 都有有效 task。
    if not clients[fd] then
        local client = require "client.sproto_client"
        clients[fd] = client.new(fd)
        -- 注入登录服地址:relogin 检测到连接在网关上时先切回登录服再发 reqlogin
        clients[fd].login_host = root_host
        clients[fd].login_port = root_port
        -- 注入重连迁移回调:reqlogin 后 sproto_client 调 wrk.reconnect 切到网关 newfd,
        -- 通过此回调把 clients 映射迁到 newfd,保证后续 read/write 找到同一 client
        clients[fd]._on_reconnect = function(oldfd, newfd)
            -- 注意顺序:先取再清再设,兼容 Windows 下 wrk.reconnect 复用同一 fd 的场景
            -- (oldfd==newfd 时先设后清会把 client 误删,导致 writeable/readable 找不到客户端)
            local c = clients[oldfd]
            if not c then return end
            clients[oldfd] = nil
            clients[newfd] = c
        end
    end
    -- 装配 protocol_task:只在 client 无 task_mgr 时注入(fd 变化场景迁移过来的 client 可能 task_mgr 为 nil)
    -- fd 复用场景(452->452)下原 pt1 已在 reqlogin 响应中 set_uid,重新注入 pt2 会覆盖 pt1 导致 uid 丢失,
    -- cheat 的 data 缺少 uid 触发服务端 cmd not found。已有 task_mgr 时保留原 task(含 uid/account)。
    if not clients[fd].task_mgr then
        local pt = protocol_task_mod.new({
            template_path = config.protocol_template_path,
        })
        clients[fd]:set_task_manager(pt)
        -- 注入 client 引用,供 protocol_task 执行重新登录/账号切换
        pt:set_client(clients[fd])
    end
    -- 仅首次连接时启动登录流程;reconnect 后的 connected(fd 复用场景)
    -- 不应重新 start,否则会把 status 从 WAIT_AUTH 重置为 REQLOGIN,
    -- 导致状态混乱、队列堆积、最终卡死。判断依据:client.status,
    -- STATE_INIT 表示首次连接,非 INIT 表示 reconnect 后的 connected。
    local sproto_client = require "client.sproto_client"
    if clients[fd].status == sproto_client.STATE_INIT then
        -- 启动客户端:从账号文件按线程跨步取账号(全局唯一,防同账号重复登录被踢),
        -- 无账号文件或配额用尽时回退到线程内唯一生成的账号名
        local account = next_account() or get_account()
        clients[fd]:start({ account = account })
    end
end

local overcount = 0           -- 已结束的连接计数

----------------------------------------------------------------------
-- 账号轮换:为连接注入全新任务实例并重走登录(uid/account 由 reqlogin 响应回填)
----------------------------------------------------------------------
local function start_rotation(client, account, gidx)
    local pt = protocol_task_mod.new({
        template_path = config.protocol_template_path,
    })
    client:set_task_manager(pt)
    pt:set_client(client)
    client:relogin(account)
    print(string.format("game_bw thread %d fd=%s rotate to account %s (%d/%d)",
        identify, tostring(client.fd), account, gidx, total_accounts))
end

----------------------------------------------------------------------
-- 登录升级重建:WAIT_LOGIN 连续超时(3 次)的连接在此重建连接并重发 reqlogin。
-- 必须在 next_payload 之前执行:reconnect 后旧 fd 即刻失效,
-- 在 next_payload 内部 reconnect 会导致返回帧被 C 层发往已关闭的旧 fd。
-- 先收集后处理,避免遍历 clients 期间因 reconnect 迁移修改键集
----------------------------------------------------------------------
local function process_login_escalations()
    local escalations
    for _, client in pairs(clients) do
        if client.wait_login_escalate then
            escalations = escalations or {}
            escalations[#escalations + 1] = client
        end
    end
    if not escalations then return end
    for _, client in ipairs(escalations) do
        client.wait_login_escalate = nil
        print(string.format("game_bw thread %d fd=%s rebuild connection for stuck reqlogin",
            identify, tostring(client.fd)))
        client:relogin(nil)
    end
end

----------------------------------------------------------------------
-- 任务完成检测与账号轮换:由可写回调驱动(每秒最多检测一次)
-- 1) 轮换开启时(total_accounts > 0):连接用例跑完后自动换下一个账号重走登录,
--    直至账号配额用尽;relogin 仅入队 reqlogin 不改 clients 表,遍历内调用安全
-- 2) 全部连接跑完且无账号可换(或未开启轮换)时向 C 层上报,提前结束压测
----------------------------------------------------------------------
local function check_all_done()
    if done_reported or not early_stop or not had_client then return end
    local now = os.time()
    if now == last_done_check then return end
    last_done_check = now

    local can_rotate = rotation_enabled()
    local blocked = false    -- 存在未完成/降级/无任务连接,不能提前结束
    local rotated = false    -- 本轮发生过轮换,新任务刚注入,不能判完成
    -- 先收集后处理:start_rotation→relogin→wrk.reconnect→_on_reconnect 会修改
    -- clients 表(迁移键),在 pairs 遍历中修改会抛 'invalid key to 'next'' 错误,
    -- 导致 script_writeable pcall 失败、c->request 被置 NULL、连接永久沉默卡死
    local rotate_list = {}    -- 待轮换的 client(account, gidx 已预分配)
    local finish_list = {}    -- 待标记 _run_finished 的 client
    for _, client in pairs(clients) do
        local tm = client.task_mgr
        if client._abandoned then
            -- 登录彻底失败的连接:不阻塞 early stop;有剩余配额则换号重试,否则进入终态
            if not client._run_finished then
                local account, gidx
                if can_rotate then
                    account, gidx = next_account()
                end
                if account then
                    client._abandoned = false
                    rotate_list[#rotate_list + 1] = { client = client, account = account, gidx = gidx }
                    rotated = true
                else
                    finish_list[#finish_list + 1] = client
                end
            end
        elseif not tm or tm.degraded or not tm.done then
            -- 无任务或降级任务(xlsx 读取失败立即 done)不计入完成判定,维持完整时长心跳流量
            blocked = true
        elseif not client._run_finished then
            local account, gidx
            if can_rotate then
                account, gidx = next_account()
            end
            if account then
                -- 轮换:注入全新任务实例(uid/account 由 reqlogin 响应回填)并重走登录
                rotate_list[#rotate_list + 1] = { client = client, account = account, gidx = gidx }
                rotated = true
            else
                -- 无更多账号(或未开启轮换):该连接进入终态完成
                finish_list[#finish_list + 1] = client
            end
        end
    end
    -- 遍历结束后统一处理,避免修改 clients 表导致 pairs 拋错
    for _, item in ipairs(rotate_list) do
        start_rotation(item.client, item.account, item.gidx)
    end
    for _, client in ipairs(finish_list) do
        client._run_finished = true
    end
    if blocked or rotated then return end

    done_reported = true
    print("game_bw thread " .. tostring(identify) .. " all accounts done, report early stop")
    -- 兼容旧版 wrk.exe(未注册 report_done):静默跳过,压测仍跑满完整时长
    if wrk and wrk.report_done then
        wrk.report_done()
    end
end

----------------------------------------------------------------------
-- 可写回调:从客户端取出待发送帧
-- 返回 (data, size) 供 C 层发送
-- 客户端返回 (data, proto_id, over):
--   proto_id == -2: raw 模式,data 为已含 2 字节长度头的完整帧,直接发送
--   proto_id == -1: 无数据可发
--   over == true: 连接应结束
----------------------------------------------------------------------
function M.writeable(fd)
    process_login_escalations()
    check_all_done()
    local client = clients[fd]
    if not client then
        print("game_bw writeable failed, no client fd:" .. (fd or 0))
        return "", 0
    end

    local data, proto_id, over = client:writeable()
    if over then
        overcount = overcount + 1
        clients[fd] = nil
        return "", 0
    end
    if proto_id == -1 or not data or #data == 0 then
        return "", 0
    end

    -- raw 模式:直接返回字符串与长度(C 层 get_buffer 会拷贝)
    return data, #data
end

----------------------------------------------------------------------
-- 可读回调:从底层 buffer 拆包并分发给对应客户端处理
-- 与 game/main.lua 不同:这里用 netpack.unpackraw 取原始 sproto payload,
-- 再由 client:readable(payload) 走 sproto host:dispatch 解码
----------------------------------------------------------------------
function M.readable(fd, buffer, sz)
    local MSG = {}

    -- 分发单条消息:拆原始 payload 并交给客户端
    local function dispatch_msg(fd, msg, sz)
        local client = clients[fd]
        if not client then
            print("game_bw readable failed, no client fd:" .. (fd or 0))
            return -1, 1
        end
        -- unpackraw 把 lightuserdata+size 转为 Lua 字符串并释放内存
        local payload = netpack.unpackraw(msg, sz)
        if not payload or #payload == 0 then
            return -2, 0
        end
        local result = client:readable(payload)
        if result == 0 then
            -- 正常:重新触发可写以发起下一帧(ping-pong)
            return 0, 1
        end
        return -1, 1
    end
    MSG.data = dispatch_msg

    -- 分发队列中累积的多条消息
    local function dispatch_queue()
        local readhandle = -1
        local result = 0
        for fd, msg, sz in netpack.pop, queue do
            local res1, res2 = dispatch_msg(fd, msg, sz)
            if res1 == 0 then
                readhandle = 0
            end
            result = result + res2
        end
        return readhandle, result
    end
    MSG.more = dispatch_queue

    -- 调用 netpack.filter 从 buffer 解析出消息类型与负载
    local q, type, fd2, msg, sz2 = netpack.filter(queue, buffer, sz, fd)
    queue = q

    if type == "data" then
        return MSG[type](fd2, msg, sz2)
    elseif type == "more" then
        return MSG[type]()
    else
        -- 拆包未完整或单字节残留:继续等待下次可读
        return -2, 0
    end
end

----------------------------------------------------------------------
-- 延迟回调:控制下次可写轮询间隔(毫秒)
-- 在 req/resp 模型下,主要由可读驱动;此值仅在空闲时生效
----------------------------------------------------------------------
function M.delay(fd)
    return 100  -- 100ms 空闲轮询
end

----------------------------------------------------------------------
-- 心跳回调(C 层未实际调用,保留接口)
----------------------------------------------------------------------
function M.heartbeat(fd)
    local client = clients[fd]
    if client and client.switch_background then
        -- 空操作:心跳由状态机内部驱动
    end
end

return M
