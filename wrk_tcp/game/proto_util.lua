local proto  = require ("protocol.proto")
local httpc = require ("http.httpc")
local json = require "cjson"
local util = require "util"

local pb    -- sproto 协议对象,init 后赋值

-- 协议编解码与 HTTP 请求构造工具集
local M = {}

-- 初始化 sproto 协议对象
function M.init()
    pb = proto.load(1)
    if not pb then
        print("can not load proro config")
        return
    end
end

-- URL 转义:对非字母数字下划线字符做百分号编码
local function escape(s)
	return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

-- local host = "127.0.0.1:17788";
-- local path = "/test_wrk?a=11";
-- 构造 HTTP GET 请求报文,返回报文与长度
function M.encode_get(host, path)
    local request = httpc.get(host, path)
    return request, #request
end

-- 构造表单方式(application/x-www-form-urlencoded)的 POST 请求报文
function M.encode_post(host, path, form)
    local header = {
		["content-type"] = "application/x-www-form-urlencoded"
    }
    -- 拼接表单字段为 key=value&key=value 形式
    local body = {}
	for k,v in pairs(form) do
		table.insert(body, string.format("%s=%s",escape(k),escape(v)))
    end
    
    local request = httpc.post(host, path, header, table.concat(body , "&"))

    return request, #request
end

-- 构造 JSON 方式的 POST 请求报文
function M.encode_post_json(host, path, form)
    local header = {
		["content-type"] = "application/json; charset=utf-8;"
    }

    local body = json.encode(form)
    local request = httpc.post(host, path, header, body)

    return request, #request
end

-- 解析 JSON 响应体为 Lua 表
function M.decode_json_msg(body)
    return json.decode(body)
end

-- 按协议名编码请求消息,返回二进制数据与协议 id
function M.encode_msg(proto_name, msg)
    local data, proto_id = pb:request_encode(proto_name, msg)
    return data, proto_id
end

-- 解码服务器消息:根据方向区分请求/响应,返回协议名(带 _req/_rsp 后缀)与参数表
function M.decode_msg(type, proto_id, client_id, session, proto_msg)
    local proto_name, msg_params
    if type > 0 then
        -- 请求方向
        msg_params, proto_name = pb:request_decode(proto_id, proto_msg)
        proto_name = proto_name.."_req"
    else
        -- 响应方向
        msg_params, proto_name = pb:response_decode(proto_id, proto_msg)
        proto_name = proto_name.."_rsp"
    end

    -- print("type:"..type.." proto_id:"..proto_id.." proto_name:"..proto_name)
    -- util.dumptable(msg_params)

    return proto_name, msg_params
end

return M
