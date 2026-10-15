-- game_bw 协议编解码工具模块
-- 在 wrk_tcp 原有 proto_util 基础上扩展 c2s.sproto 的请求/响应/类型编解码

local proto_loader = require "protocol.proto"
local sproto_core = require "sproto.core"
local sproto = require "sproto"
local json = require "cjson"
local config = require "config"

local M = {}

-- sproto 协议对象,init 后赋值
local pb = nil
-- host 对象,用于 dispatch(预留)
local host = nil
-- s2c 推送协议对象与 host:服务器推送 tag 定义在 s2c schema 中,
-- 与 c2s 相互独立(与 Python 双 schema 架构一致)
local s2c_pb = nil
local s2c_host = nil

-- 初始化 sproto 协议对象:注册并加载 c2s.sproto
function M.init()
    -- 注册协议到指定 index(若已注册可重复调用安全)
    -- 注意:pcall 仅用于容错打印错误,失败时仍向上抛出
    local ok, err = pcall(function()
        proto_loader.register(config.proto_index, table.unpack(config.proto_files))
    end)
    if not ok then
        error("proto_util.init: register failed: " .. tostring(err))
    end
    pb = proto_loader.load(config.proto_index)
    if not pb then
        error("proto_util.init: load sproto failed, index=" .. tostring(config.proto_index))
    end
    -- 创建 host 用于后续 dispatch(基于 .package 类型构造会话宿主)
    host = pb:host(config.package_type)

    -- 加载 s2c 推送协议(独立 index 槽位,失败不阻塞主流程仅告警)
    local s2c_index = (config.proto_index or 1) + 1
    local ok2, err2 = pcall(function()
        proto_loader.register(s2c_index, "s2c")
    end)
    if ok2 then
        s2c_pb = proto_loader.load(s2c_index)
        if s2c_pb then
            s2c_host = s2c_pb:host(config.package_type)
        end
    else
        io.stderr:write("proto_util: load s2c failed: " .. tostring(err2) .. "\n")
        io.stderr:flush()
    end
end

-- 取 s2c 推送协议 host(未加载时返回 nil)
function M.get_s2c_host()
    return s2c_host
end

-- 取底层 sproto 对象(供高级用户使用)
function M.get_pb()
    return pb
end

-- 取 host 对象
function M.get_host()
    return host
end

-- 编码请求消息,返回 (data, proto_tag)
-- proto_name: 协议名(如 "reqlogin" / "heartBeat" / "trainArmy")
-- msg: 请求字段表
function M.encode_request(proto_name, msg)
    return pb:request_encode(proto_name, msg)
end

-- 解码响应消息,返回 (msg, proto_name)
-- proto_tag: 由 netpack 解析出的协议 id
function M.decode_response(proto_tag, data)
    return pb:response_decode(proto_tag, data)
end

-- 解码请求消息(服务器侧或重放),返回 (msg, proto_name)
function M.decode_request(proto_tag, data)
    return pb:request_decode(proto_tag, data)
end

-- 取协议对应的 tag(数字 id)
function M.get_tag(proto_name)
    return pb:get_tag("proto", proto_name)
end

-- 判断类型是否存在(如 "ComLord" / "package")
function M.exist_type(typename)
    return pb:exist_type(typename)
end

-- 编码任意类型(用于通用结构编码,如 "package" / "ComIntInt")
function M.encode_type(typename, tbl)
    return pb:encode(typename, tbl)
end

-- 解码任意类型
function M.decode_type(typename, data)
    return pb:decode(typename, data)
end

----------------------------------------------------------------------
-- 网络包组装:对应 Python sprotoClient.packNetMsg
-- c2s 协议格式: [package(type+session+ud)] + [request data] -> sproto_pack -> [2字节大端长度][payload]
-- 入参:
--   session   本次会话 id(自增)
--   tag       协议名或数字 tag
--   msg       请求字段表
--   resp_type 若协议有响应,则登记 session -> resp 类型名,以便 Recv 时解码
-- 返回: 打包后的字符串(已含 2 字节大端长度头)
----------------------------------------------------------------------

-- session -> 响应类型名 或 true(无响应)的映射表
local session_map = {}

-- 通过协议名查询其响应类型名(若存在)
local function get_resp_type_name(proto_name)
    local ptype = pb:get_tag("proto", proto_name)
    -- sproto 不直接暴露 response 字段类型名,这里用约定:response 存在时 session_map 存 true,
    -- 真正解码时由 netpack 返回的 proto_tag + 反查协议名得到响应
    -- 简化:无响应协议(session_map 存 true),有响应则存 proto_name 自身用于回查
    return ptype and proto_name or nil
end

-- 打包网络消息:返回可直接发送的字节串
-- 注意:wrk_tcp 底层 netpack.packmsg 已封装了 tag+session 头,
-- 本函数用于"完整自定义打包"场景(如某些绕过 netpack 的直发场景)
function M.pack_net_msg(session, proto_name_or_tag, msg)
    local tag, req, resp
    if type(proto_name_or_tag) == "string" then
        tag = pb:get_tag("proto", proto_name_or_tag)
        req = proto_name_or_tag -- sproto:request_encode 接受名字
    else
        tag = proto_name_or_tag
        req = nil -- 数字 tag 时需外部提供 req 类型
    end

    -- 1) 组装 package 头: type/session
    local package = { type = tag, session = session }
    local package_data = pb:encode(config.package_type, package)

    -- 2) 编码请求体
    local msg_data
    if type(req) == "string" then
        msg_data = pb:request_encode(req, msg or {})
    else
        -- 仅给数字 tag 时直接编码 msg(无 proto 名,需调用者保证)
        msg_data = (msg and #msg > 0) and pb:encode("dummy", msg) or ""
    end

    -- 3) 拼接 -> sproto_core.pack 压缩为网络传输格式
    local net_data = sproto_core.pack(package_data .. msg_data)
    local net_msg_len = #net_data
    -- 4) 2 字节大端长度头 + payload
    local packed = string.char(math.floor(net_msg_len / 256), net_msg_len % 256) .. net_data

    -- 5) 登记会话
    session_map[session] = resp or true
    return packed
end

-- 登记会话(供 sproto_client 内部使用)
function M.set_session(session, value)
    session_map[session] = value
end

-- 取出并清除会话(Recv 时调用)
function M.take_session(session)
    local v = session_map[session]
    session_map[session] = nil
    return v
end

-- 查询会话(不删除)
function M.peek_session(session)
    return session_map[session]
end

----------------------------------------------------------------------
-- JSON / HTTP 辅助(沿用原 proto_util)
----------------------------------------------------------------------
-- 解析 JSON 响应体为 Lua 表
function M.decode_json_msg(body)
    if not body or body == "" then
        return { code = -1, msg = "empty body" }
    end
    return json.decode(body)
end

-- 把 Lua 表编码为 JSON 字符串
function M.encode_json_msg(tbl)
    return json.encode(tbl)
end

return M
