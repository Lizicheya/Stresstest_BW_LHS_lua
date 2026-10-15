local proto = require "protocol.proto"
local netpack = require "netpack"
local config = require "config"
local http = require("socket.http")
local proto_util = require "proto_util"

-- 压测主调度模块:负责账号准备、连接建立与数据读写分发
local M = {}
local count = 0               -- 已生成的账号计数器
local identify                -- 当前线程标识
local accounts ={}            -- 已登录 Web 后的账号列表

local clients = {}            -- fd -> 客户端对象 映射表

local queue                   -- netpack 解包队列

-- 生成一个全局唯一的压测账号名
function M.get_account()
    count = count + 1
    return "wrkplayer"..identify.."_"..count
end

-- 初始化:登录 Web 获取所有账号信息,并注册协议
function M.init(id, connections)
    identify = id
    local start = os.time()

    -- 循环登录 Web,获取每个连接对应的账号凭证
    for i=1, connections do
        local account = M.get_account()
        local url = string.format(config.loginMsg, config.loginAddr, account, "pw123456",config.appID, "Tourist", "", "mac", 1001)
        local result = http.request(url)
        local res = proto_util.decode_json_msg(result)
        if tonumber(res.code) ~= 0 then
            print("result:"..result)
            print("web_login failed res code:"..res.code)
            util.dumptable(res)
        end
        accounts[count] = res
    end
    local endt = os.time()
    print("login web thread id:"..id.." delta time:"..(endt-start).." "..#accounts)

    -- 注册 sproto 协议并初始化随机种子
    proto.register(1, "test")
    math.randomseed(os.time())
end

-- 新连接建立回调:为该 fd 创建客户端对象并启动
function M.connected(fd)
    if clients[fd] then
        print("lua connected error, exist the fd:"..(fd or 0))
        return 
    end
    local client = require(config.procedure)
    clients[fd] = client.new(fd)
    clients[fd]:start(table.remove(accounts))
end

local overcount = 0           -- 已结束的连接计数
-- 可写回调:从客户端取出待发送数据并打包成 netpack 报文
function M.writeable(fd)
    local client = clients[fd]
    if not client then
        print("lua writeable failed, not exist the fd:"..(fd or 0))
        return
    end

    local data, proto_id, over = client:writeable()
    if over then
        overcount = overcount + 1 
        -- print("identify:"..identify.." over connect:"..overcount)
    end
    if proto_id == -1 then
        return data, 0
    end
    -- 将数据打包成带协议头的服务器消息
    local msg, sz = netpack.packmsg(1, proto_id, 16, 0, data)
    return msg, sz
end

-- 可读回调:从底层 buffer 拆包并分发给对应客户端处理
function M.readable(fd, buffer, sz)
    local MSG = {}

    -- 分发单条消息:解包并交给对应 fd 的客户端处理
    local function dispatch_msg(fd, msg, sz)
        local type, proto_id, client_id, session, proto_msg = netpack.unpackmsg(msg, sz)

        local client = clients[fd]
        if not client then
            print("lua readable failed, not exist the fd:"..(fd or 0))
            return
        end
        local result = client:readable(type, proto_id, client_id, session, proto_msg)
        if result == 0 then
            return 0, 1
        end

        return -1, 1
    end

	MSG.data = dispatch_msg

    -- 分发队列中累积的多条消息
    local function dispatch_queue()
        -- print("more data")
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
    local q, type, fd, msg, sz = netpack.filter(queue, buffer, sz, fd)
    queue = q

    if type == "data" then
        return MSG[type](fd, msg, sz)
    elseif type == "more" then
        return MSG[type]()
    else
        -- print("chai bao:"..(type or ""))
        --拆包
        return -2, 0
    end
end

return M
