local proto = require "proto_util"
local config = require "config"
local util = require "util"

-- 登录客户端对象:负责发起登录请求并处理登录响应
local M = class("login_client")

-- 客户端状态枚举
M.STATE_LOGIN = 1        -- 待发送登录请求
M.STATE_LOGIN_RES= 2     -- 已发送登录请求,等待响应

M.STATE_NONE = 3         -- 登录流程结束

M.login_web_data = {}    -- Web 登录返回的账号凭证

-- 构造函数:保存 fd 并初始化状态机与消息处理表
function M:ctor(fd)
    self.fd = fd
    self.status = self.STATE_LOGIN
    -- 状态机:每个状态对应的发送处理函数
    self.state_func = {
        self.login,
    }
    -- 消息处理表:协议名 -> 处理函数
    self.msg_handle = {
        ["login_rsp"] = self.login_rsp,
    }
end

-- 启动客户端:保存 Web 登录数据并初始化 sproto
function M:start(account)
    self.login_web_data = account
    proto.init()
end

-- 登录请求:编码并发送 login 协议
function M:login()
    self.status = self.STATE_LOGIN_RES
    return proto.encode_msg("login", { userid=self.login_web_data.userid, token=self.login_web_data.token, app_ver="1.0", hotfix_ver=0 })
end

-- 登录响应处理:成功则结束流程,失败则打印错误
function M:login_rsp(msg)
    if msg.code == 0 then
        self.status = self.STATE_NONE
    else
        print("login_rsp failed, code:"..msg.code)
    end
end

---------------------------------------------------------------
-- 可写回调:根据当前状态取出待发送数据;流程结束后标记结束
function M:writeable()
    if self.status == self.STATE_NONE then
        return "", -1, true
    end

    local handle = self.state_func[self.status]
    if handle then
        return handle(self)
    else
        return "", -1
    end
end

-- 可读回调:解包服务器消息并交给对应处理函数
function M:readable(type, proto_id, client_id, session, proto_msg)
    -- 跳过内部心跳类协议
    if proto_id == 9500 or proto_id == 125 then
        return -1
    end
    local proto, msg = proto.decode_msg(type, proto_id, client_id, session, proto_msg)
    print("proto:"..proto)

    local handle = self.msg_handle[proto]
    if handle then
        handle(self, msg)
        return 0
    else
        return -1
    end
end

return M
