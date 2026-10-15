-- game_bw 核心客户端:每连接一个实例
-- 对应 Python PressureTest_BW_LHS/modules/client/sprotoClient.py 的 Tcp 类
-- 负责:登录握手/网关验证/会话管理/收发分发/数据同步/业务任务调度

-- class 为全局函数,由 loader.lua 的 require "class" 注入
local proto_util = require "proto_util"
local config = require "config"
local util = require "util"
local sync_data_mod = require "sync.sync_data"

-- 高频诊断日志开关:由 game_bw/config.lua 的 debug 字段控制,
-- false 时关闭 writeable/readable/dispatch 等高频日志,避免正式压测时 stderr 刷屏开销
local dbg = config.debug == true

local M = class("sproto_client")

----------------------------------------------------------------------
-- 客户端状态枚举
----------------------------------------------------------------------
M.STATE_INIT            = 0   -- 未初始化
M.STATE_REQLOGIN        = 1   -- 待发送 reqlogin
M.STATE_WAIT_LOGIN      = 2   -- 已发 reqlogin,等待响应
M.STATE_REQAUTH         = 3   -- 待发送 reqAuth
M.STATE_WAIT_AUTH       = 4   -- 已发 reqAuth,等待响应
M.STATE_SYNC_LOGIN      = 5   -- 登录后等待同步数据
M.STATE_IDLE            = 6   -- 空闲,可发心跳/任务
M.STATE_WAIT_RESP       = 7   -- 等待业务响应
M.STATE_NONE            = 8   -- 流程结束

-- session 自增计数器
local session_counter = 0

-- 构造函数
function M:ctor(fd)
    self.fd = fd
    self.status = M.STATE_INIT

    self.session = 0          -- 当前请求的 session
    self.pending_proto = nil -- 当前等待响应的协议名(用于校验)

    self.sync_data = sync_data_mod.new()  -- 玩家数据缓存

    self.login_web_data = {}  -- Web 登录返回的账号凭证
    self.gateway_host = nil
    self.gateway_port = nil

    self.send_queue = {}      -- 待发送的完整包(已含 2 字节长度头)
    self.last_heartbeat = 0   -- 上次心跳时间(秒)
    self.last_request_time = 0   -- 上次请求发送时间(秒),用于 STATE_WAIT_RESP 超时检测
    self.last_confirm_time = 0   -- 上次发送 confirmNetMsg 时间(秒),用于冷却控制
    self._confirm_session = 0    -- 最近一次 fire-and-forget confirmNetMsg 的 session(响应过滤用)

    -- 业务任务管理器(延迟初始化,登录成功后注入)
    self.task_mgr = nil
end

----------------------------------------------------------------------
-- 启动客户端:保存 Web 登录数据,初始化 sproto 与 host
----------------------------------------------------------------------
function M:start(account)
    self.login_web_data = account or {}
    -- 协议对象已在 proto_util.init 时加载,这里取 host
    self.host = proto_util.get_host()
    -- 生成请求闭包:host:attach 返回 request(name, args, session, ud)
    self.request_fn = self.host:attach(proto_util.get_pb())
    self.status = M.STATE_REQLOGIN
    -- 入队首包:reqlogin(字段对应 c2s.sproto 的 reqlogin request)
    -- reqlogin 字段对齐原项目 com.py loginServer: 登录默认不需要密码
    -- create_new_role=false 时仅发 account + sdkToken(原项目 del serverId/createNewRole)
    -- create_new_role=true 时附带 serverId + createNewRole
    local reqlogin_args = {
        account = self.login_web_data.account or "",
        sdkToken = config.sdk_token or "",
    }
    if config.create_new_role then
        reqlogin_args.serverId = config.server_id or 0
        reqlogin_args.createNewRole = true
    end
    self:_enqueue_request("reqlogin", reqlogin_args)
    self.status = M.STATE_WAIT_LOGIN
end

----------------------------------------------------------------------
-- 内部:发起一个请求并入队
-- proto_name: 协议名(如 "reqlogin" / "heartBeat" / "trainArmy")
-- args: 请求字段表
-- 返回本次 session
----------------------------------------------------------------------
function M:_enqueue_request(proto_name, args, is_keepalive)
    session_counter = session_counter + 1
    local session = session_counter
    -- attach 闭包会登记 session -> response 类型(供 dispatch 回查)
    -- pcall 防御:协议未注册或参数编码失败会抛错并静默中断 writeable 状态机,
    -- 这里捕获后打印协议名并返回 nil,交由调用方推进管线
    local ok, packed = pcall(self.request_fn, proto_name, args or {}, session, 0)
    if not ok then
        io.stderr:write(string.format("[dbg] encode failed fd=%d proto=%s err=%s\n",
            self.fd, tostring(proto_name), tostring(packed)))
        io.stderr:flush()
        session_counter = session_counter - 1
        return nil
    end
    -- 加 2 字节大端长度头
    local len = #packed
    local frame = string.char(math.floor(len / 256), len % 256) .. packed
    self.send_queue[#self.send_queue + 1] = frame
    self.session = session
    -- 仅业务/登录/鉴权请求记录等待 session,供 _handle_response 校验响应归属
    -- confirmNetMsg 等保活请求不覆盖 _wait_session,避免误过滤真正的业务响应
    if not is_keepalive then
        self._wait_session = session
    end
    -- 仅业务请求记录等待起始时间,保活请求(confirmNetMsg)不刷新,
    -- 否则会重置 STATE_WAIT_RESP 超时计时导致永不超时推进
    if not is_keepalive then
        self.pending_proto = proto_name
        self.last_request_time = os.time()
    end
    return session
end

----------------------------------------------------------------------
-- 可写回调:从发送队列取一帧返回
-- 返回: (data, proto_id, over)
--   proto_id == -2: raw 模式, data 为已含长度头的完整帧,由 main 直接发送
--   proto_id == -1: 无数据可发
--   over == true: 连接应关闭
----------------------------------------------------------------------
function M:writeable()
    -- 诊断:打印每次 writeable 调用及当前 status(限频+debug 开关双重控制)
    if dbg then
        local now_ms = os.clock() * 1000
        if not self._last_dbg_ms or now_ms - self._last_dbg_ms >= 1000 then
            self._last_dbg_ms = now_ms
            io.stderr:write(string.format("[dbg] writeable fd=%d status=%d q=%d\n",
                self.fd, self.status, #self.send_queue))
            io.stderr:flush()
        end
    end

    -- 发送队列优先
    if #self.send_queue > 0 then
        local frame = table.remove(self.send_queue, 1)
        return frame, -2, false
    end

    -- 请求超时检测:覆盖所有等待响应状态,超过 request_timeout 秒无响应则重试/推进
    -- 避免连接卡死在等待状态(含登录阶段),使后续业务任务/心跳能继续产出,保证业务流量
    local is_waiting = (self.status == M.STATE_WAIT_LOGIN
                      or self.status == M.STATE_WAIT_AUTH
                      or self.status == M.STATE_WAIT_RESP)
    if is_waiting and self.last_request_time > 0 then
        local timeout = config.request_timeout or 5
        local elapsed = os.time() - self.last_request_time
        if elapsed >= timeout then
            local timed_out_proto = self.pending_proto
            io.stderr:write(string.format("[dbg] TIMEOUT fd=%d status=%d proto=%s\n",
                self.fd, self.status, tostring(timed_out_proto)))
            io.stderr:flush()
            self.pending_proto = nil
            if self.status == M.STATE_WAIT_RESP then
                -- 业务阶段超时:回退 IDLE,推进下一用例
                self.status = M.STATE_IDLE
                if self.task_mgr and timed_out_proto then
                    self.task_mgr:record_response(timed_out_proto, nil, -1)
                end
            elseif self.status == M.STATE_WAIT_AUTH then
                -- 鉴权阶段超时:不 reauth(reauth 会更新 _wait_session,旧 reqAuth 响应到达时被 session 校验拦截形成死循环)
                -- 前 2 次仅重置计时器继续等待(网关高峰期响应延迟属正常现象);
                -- 第 3 次标记 _abandoned 放弃该账号,由 check_all_done 轮换下一账号或进入终态,
                -- 避免 reqAuth 永久无响应时连接卡死、阻塞线程 report_done 导致无法提前结束压测
                self.wait_auth_retries = (self.wait_auth_retries or 0) + 1
                if self.wait_auth_retries <= 2 then
                    io.stderr:write(string.format("[dbg] fd=%d reqAuth still waiting (%d), no reauth\n",
                        self.fd, self.wait_auth_retries))
                    io.stderr:flush()
                    self.last_request_time = os.time()
                    self.status = M.STATE_WAIT_AUTH
                else
                    print(string.format("fd=%d reqAuth no response x%d, abandon account=%s",
                        self.fd, self.wait_auth_retries,
                        tostring(self.login_web_data and self.login_web_data.account)))
                    self.pending_proto = nil
                    self.status = M.STATE_NONE
                    self._abandoned = true
                end
            else
                -- 登录阶段(WAIT_LOGIN)超时:有界升级,避免 reqlogin 无响应时永久卡死
                -- (卡死会阻塞账号轮换与 early stop,连接只能空转到 duration 结束)。
                -- 前 2 次仅重置计时器继续等待(登录服高峰期响应延迟属正常现象);
                -- 第 3 次置升级标记,由 main_bw 在下一轮可写回调重建连接重发 reqlogin
                -- (不能在 next_payload 内直接 reconnect:返回帧会被 C 层发往已关闭的旧 fd);
                -- 重建后仍无响应则标记 _abandoned 放弃该账号,
                -- 由 check_all_done 决定轮换下一账号或进入终态放行 early stop
                self.wait_login_retries = (self.wait_login_retries or 0) + 1
                if self.wait_login_retries <= 2 then
                    io.stderr:write(string.format("[dbg] fd=%d reqlogin still waiting (%d), no relogin\n",
                        self.fd, self.wait_login_retries))
                    io.stderr:flush()
                    self.last_request_time = os.time()
                    self.status = M.STATE_WAIT_LOGIN
                elseif self.wait_login_retries == 3 then
                    print(string.format("fd=%d reqlogin no response x%d, escalate: rebuild connection",
                        self.fd, self.wait_login_retries))
                    self.wait_login_escalate = true
                    self.last_request_time = os.time()
                    self.status = M.STATE_WAIT_LOGIN
                else
                    print(string.format("fd=%d reqlogin no response after rebuild, abandon account=%s",
                        self.fd, tostring(self.login_web_data and self.login_web_data.account)))
                    self.pending_proto = nil
                    self.status = M.STATE_NONE
                    self._abandoned = true
                end
            end
        elseif self.status == M.STATE_WAIT_RESP then
            -- 未超时时发送 confirmNetMsg 保持可写事件活跃,
            -- 否则 AE_WRITABLE 会被移除,超时检测无法触发
            -- confirmNetMsg 为 fire-and-forget 保活:不更新 last_request_time(避免重置业务超时),
            -- 不改 pending/status,其响应(若有)由 _confirm_session 过滤,防止误吞业务响应
            local confirm_session = self:_enqueue_request("confirmNetMsg", { sessionResponse = 0, sessionSync = 0 }, true)
            if confirm_session then
                self._confirm_session = confirm_session
                local frame = table.remove(self.send_queue, 1)
                return frame, -2, false
            end
        end
    end

    -- 状态机驱动:空闲时按状态产出下一帧
    if self.status == M.STATE_IDLE then
        -- 1) 业务任务调度优先(若启用)
        if config.enable_tasks and self.task_mgr then
            -- pcall 防御:用例执行(变量替换/if/cheat)抛错时不中断状态机
            local ok, proto_name, args = pcall(self.task_mgr.next_request, self.task_mgr, self.sync_data)
            if not ok then
                io.stderr:write("[dbg] next_request error: " .. tostring(proto_name) .. "\n")
                io.stderr:flush()
                -- 清理可能挂起的等待态,解锁管线
                pcall(self.task_mgr.record_response, self.task_mgr, "unknown", nil, -1)
                proto_name = nil
            end
            if proto_name then
                local session = self:_enqueue_request(proto_name, args or {})
                if session then
                    self.status = M.STATE_WAIT_RESP
                    self.pending_proto = proto_name
                    local frame = table.remove(self.send_queue, 1)
                    return frame, -2, false
                end
                -- 编码失败(协议未注册/参数错误):记录失败结果,解锁管线推进下一用例
                self.task_mgr:record_response(proto_name, nil, -1)
            end
        end

        -- 2) 无业务任务时,回退心跳保活(wrk 为 req/resp 模型,需维持 ping-pong)
        local now = os.time()
        if now - self.last_heartbeat >= (config.heartbeat_interval or 10) then
            self.last_heartbeat = now
            self:_enqueue_request("heartBeat", {})
            self.status = M.STATE_WAIT_RESP
            self.pending_proto = "heartBeat"
            local frame = table.remove(self.send_queue, 1)
            return frame, -2, false
        end

        -- 仅 STATE_WAIT_RESP 状态走 confirmNetMsg 保活分支(登录阶段不发保活包)
        -- 心跳未到且无任务:按冷却间隔发 confirmNetMsg 维持连接活性
        -- 冷却内不发,避免频繁占位请求挤占业务带宽
        -- confirmNetMsg 作为保活请求,不更新 last_request_time
        local now_confirm = os.time()
        local confirm_cd = config.confirm_cooldown or 3
        if now_confirm - self.last_confirm_time >= confirm_cd then
            self.last_confirm_time = now_confirm
            -- IDLE 态 confirm 保活保持 IDLE 不变(纯 fire-and-forget):
            -- 服务器不回 confirm 响应,置 WAIT_RESP 会因幽灵超时卡死状态机
            local confirm_session = self:_enqueue_request("confirmNetMsg", { sessionResponse = 0, sessionSync = 0 }, true)
            if confirm_session then
                self._confirm_session = confirm_session
                local frame = table.remove(self.send_queue, 1)
                return frame, -2, false
            end
        end

        -- 冷却中且无业务/心跳:无数据可发
        return "", -1, false
    end

    -- 其它非 IDLE 态且队列空:无数据可发
    return "", -1, false
end

----------------------------------------------------------------------
-- 可读回调:处理一条已拆包的 payload(sproto_pack'd 二进制)
-- payload: Lua 字符串(netpack.unpackraw 转出)
-- 返回: 0 表示正常, -1 表示异常
----------------------------------------------------------------------
function M:readable(payload)
    if not payload or #payload == 0 then
        if dbg then
            io.stderr:write(string.format("[dbg] readable fd=%d EMPTY\n", self.fd))
            io.stderr:flush()
        end
        return -1
    end

    if dbg then
        io.stderr:write(string.format("[dbg] readable fd=%d len=%d status=%d\n",
            self.fd, #payload, self.status))
        io.stderr:flush()
    end

    -- 用 host:dispatch 解包
    -- 返回: "REQUEST", name, result, response_fn, ud  或  "RESPONSE", session, result, ud
    local ok, kind, a, b, c, d = pcall(function()
        return self.host:dispatch(payload)
    end)
    if not ok then
        -- c2s host 查不到 tag:可能为服务器推送(s2c schema),用 s2c host 重试
        local s2c_host = proto_util.get_s2c_host()
        if s2c_host then
            local ok2, kind2, a2, b2, c2, d2 = pcall(s2c_host.dispatch, s2c_host, payload)
            if ok2 and kind2 == "REQUEST" then
                if dbg then
                    io.stderr:write(string.format("[dbg] dispatch fd=%d kind=REQUEST(s2c) name=%s\n",
                        self.fd, tostring(a2)))
                    io.stderr:flush()
                end
                return self:_handle_push(a2, b2, d2)
            end
        end
        -- pcall 失败时:kind 是错误消息,a/b/c/d 均为 nil
        -- 打印真正的错误消息 + payload 前16字节十六进制,诊断网关数据为何解析失败
        local hex = ""
        for i = 1, math.min(16, #payload) do
            hex = hex .. string.format("%02x ", string.byte(payload, i))
        end
        io.stderr:write(string.format("[dbg] dispatch ERR fd=%d msg=%s hex=%s len=%d\n",
            self.fd, tostring(kind), hex, #payload))
        io.stderr:flush()
        return -1
    end
    if dbg then
        io.stderr:write(string.format("[dbg] dispatch fd=%d kind=%s name/sess=%s\n",
            self.fd, tostring(kind), tostring(a)))
        io.stderr:flush()
    end

    if kind == "RESPONSE" then
        -- a = session, b = result, c = ud
        local session = a
        local result = b
        local ud = c or 0
        return self:_handle_response(session, result, ud)
    elseif kind == "REQUEST" then
        -- a = name(推送协议名), b = result(推送内容), c = response_fn(回包闭包,可空), d = ud
        local push_name = a
        local push_msg = b
        return self:_handle_push(push_name, push_msg, d)
    end
    return -1
end

----------------------------------------------------------------------
-- 处理响应:根据当前状态推进状态机
----------------------------------------------------------------------
function M:_handle_response(session, result, ud)
    -- ud 在响应中通常用作错误码(c2s.sproto: ud 2 : integer # response:用于错误码)
    local err_code = ud or 0
    local status = self.status

    -- session 校验:多连接共享同一 sproto host,dispatch 按 session 解码后投递给当前 fd,
    -- 但响应可能属于其他连接的请求(如其他连接 confirmNetMsg 的保活响应 session 与本连接 reqAuth 的 session 不同)。
    -- 若不校验,会把其他请求的响应当作当前等待的响应处理,触发误报 err=105 等错误。
    -- 仅 WAIT_AUTH 阶段校验:防止其他连接的 confirmNetMsg 保活响应串扰到 reqAuth 等待状态触发 err=105。
    -- WAIT_LOGIN 不校验:relogin 会用同账号重发 reqlogin 并更新 _wait_session,
    -- 服务器对同账号重复 reqlogin 可能不回响应,形成 relogin→旧响应被拦→新响应不来 死循环。
    -- 不校验时,旧 reqlogin 响应(同账号内容一致)到达也能正确推进状态机。
    -- WAIT_RESP 不校验:confirmNetMsg 保活响应由 _confirm_session 分支过滤,加校验会被拦截。
    if status == M.STATE_WAIT_AUTH then
        if session ~= self._wait_session then
            -- 非当前等待的响应(其他连接串扰),直接忽略,不推进状态机
            return 0
        end
    end

    if status == M.STATE_WAIT_LOGIN then
        -- reqlogin 响应:登录成功,重置超时升级计数
        self.wait_login_retries = 0
        if not result or result.sucess ~= true then
            print("reqlogin failed, err=" .. tostring(err_code))
            self.status = M.STATE_NONE
            return -1
        end
        -- 取网关地址
        self.gateway_host = result.gatewayHost or config.gateway_host
        self.gateway_port = result.gatewayPort or config.gateway_port
        self.uid = result.uid
        self.game_token = result.gameToken
        io.stderr:write(string.format("[dbg] reqlogin resp fd=%d gw=%s:%s uid=%s token_len=%s\n",
            self.fd, tostring(self.gateway_host), tostring(self.gateway_port),
            tostring(self.uid), tostring(self.game_token and #self.game_token or -1)))
        io.stderr:flush()
        -- 将 uid 传递给任务管理器(供 protocol_task 的 funVar.uid 使用)
        if self.task_mgr and self.task_mgr.set_uid then
            self.task_mgr:set_uid(self.uid)
        end
        -- 将账号名传递给任务管理器(供 protocol_task 的 save 文件名区分)
        if self.task_mgr and self.task_mgr.set_account then
            self.task_mgr:set_account(self.login_web_data.account)
        end
        -- 切换连接到网关(模拟 Python:reqlogin 后关闭登录服连接,新建网关连接发 reqAuth)
        -- wrk.reconnect 是 C 层暴露的函数,关闭旧 fd 并建新 fd 到 gatewayHost:gatewayPort
        local newfd = wrk and wrk.reconnect(self.fd, self.gateway_host, self.gateway_port)
        if newfd then
            io.stderr:write(string.format("[dbg] reconnect fd=%d -> %d gw=%s:%s\n",
                self.fd, newfd, tostring(self.gateway_host), tostring(self.gateway_port)))
            io.stderr:flush()
            -- 迁移 client 映射到新 fd,旧 fd 置空(由 main.connected 回调识别已存在而跳过重建)
            -- 注意必须用点调用:self:_on_reconnect(...) 会隐式传 self 作第一参,
            -- 闭包的 oldfd 将收到 table 而非 fd,迁移静默失效(fd 复用时侥幸不可见,
            -- fd 变化时 clients[newfd] 为空,writeable/readable 全部丢 client)
            if self._on_reconnect then self._on_reconnect(self.fd, newfd) end
            self.fd = newfd
            self.last_request_time = 0
        else
            print("reconnect to gateway failed")
            self.status = M.STATE_NONE
            return -1
        end
        -- 进入网关验证:reqAuth 已入队(_enqueue_request 已设 pending_proto/last_request_time),
        -- 由 writeable 队列优先分支发出。直接置 WAIT_AUTH(与 reqlogin 置 WAIT_LOGIN 一致),
        -- 使响应到来时能匹配 _handle_response 的 WAIT_AUTH 分支推进到 IDLE
        self:_enqueue_request("reqAuth", {
            uid = self.uid or 0,
            gameToken = self.game_token or "",
            isReconnect = false,
        })
        self.status = M.STATE_WAIT_AUTH
        return 0

    elseif status == M.STATE_WAIT_AUTH then
        -- reqAuth 响应
        if err_code ~= 0 then
            print("reqAuth failed, err=" .. tostring(err_code))
            self.status = M.STATE_NONE
            return -1
        end
        -- 登录完成,进入空闲态,等同步数据推送(由 _handle_push 处理)
        self.status = M.STATE_IDLE
        self.last_heartbeat = os.time()
        return 0

    elseif status == M.STATE_WAIT_RESP then
        -- fire-and-forget confirmNetMsg 的响应:按 session 过滤直接忽略,
        -- 防止误吞业务响应
        if self._confirm_session and session == self._confirm_session then
            self._confirm_session = 0
            return 0
        end
        -- 业务/心跳响应:回写数据到 sync_data,然后回空闲
        if self.pending_proto == "heartBeat" and result and result.time then
            self.sync_data:set_server_time(math.floor(result.time))
        end
        -- 把响应结果交给任务管理器记录
        if self.task_mgr and self.pending_proto then
            self.task_mgr:record_response(self.pending_proto, result, err_code)
        end
        self.pending_proto = nil
        self.status = M.STATE_IDLE
        return 0
    end

    -- 其它状态:忽略
    return 0
end

----------------------------------------------------------------------
-- 处理服务器推送:更新 sync_data
-- push_name: 推送协议名(如 "syncData" / "troopInfo" 等)
-- push_msg: 推送内容
-- ud: 用户包确认 session
----------------------------------------------------------------------
function M:_handle_push(push_name, push_msg, ud)
    if not push_name then
        return 0
    end
    -- 把推送交给 sync_data 的 PushHandler 路由
    local handler = self.sync_data.push_handler
    if handler then
        handler:controller(push_name, push_msg)
    end
    return 0
end

----------------------------------------------------------------------
-- 切换后台
----------------------------------------------------------------------
function M:switch_background(is_bg)
    self:_enqueue_request("switchBackground", { isBackground = is_bg })
    if self.status == M.STATE_IDLE then
        self.status = M.STATE_WAIT_RESP
        self.pending_proto = "switchBackground"
    end
end

----------------------------------------------------------------------
-- 重新登录(支持账号切换)
-- new_account: 新账号信息(含 account 字段),为 nil 时使用原账号
----------------------------------------------------------------------
function M:relogin(new_account)
    -- 清空待发送队列,重置状态
    self.send_queue = {}
    self.pending_proto = nil
    self.wait_auth_retries = 0
    self.status = M.STATE_REQLOGIN
    -- 超时升级计数:仅切换到新账号(new_account 非空)时才重置(新账号是新尝试)。
    -- relogin(nil) 用作升级重建场景必须保留原计数,否则 retries==4 的 abandon
    -- 分支永远无法触达,process_login_escalations 会反复调用 relogin(nil) 形成
    -- 无限循环(服务器对同账号重复 reqlogin 不响应时尤甚)
    if new_account then
        self.wait_login_retries = 0
    end
    self.wait_login_escalate = nil

    -- 更新账号信息
    if new_account then
        if type(new_account) == "string" then
            self.login_web_data = { account = new_account }
        else
            self.login_web_data = new_account
        end
    end

    -- 轮换/账号切换场景:当前连接可能仍停留在网关上(业务阶段必然已切到网关),
    -- 而 reqlogin 只能发往登录服,直接在网关连接上发会被拒绝(reqlogin failed, err=0),
    -- 客户端卡死在 STATE_NONE 不再轮换。已切到过网关(gateway_host 非空)且已知
    -- 登录服地址(login_host 由 main.connected 注入根 config 的 host/port)时,
    -- 先切回登录服再发 reqlogin,迁移动作与网关切换完全一致
    if self.gateway_host and self.login_host and wrk and wrk.reconnect then
        local oldfd = self.fd
        local newfd = wrk.reconnect(oldfd, self.login_host, self.login_port)
        if newfd then
            io.stderr:write(string.format("[dbg] relogin reconnect fd=%d -> %d login=%s:%s\n",
                oldfd, newfd, tostring(self.login_host), tostring(self.login_port)))
            io.stderr:flush()
            -- 迁移 client 映射到新 fd(必须点调用,见网关切换处的说明),并更新自身 fd
            if self._on_reconnect then self._on_reconnect(oldfd, newfd) end
            self.fd = newfd
            self.last_request_time = 0
        else
            print("relogin reconnect to login server failed, account=" .. tostring(self.login_web_data.account))
            self.status = M.STATE_NONE
            return
        end
    end

    -- 重新发起 reqlogin
    local reqlogin_args = {
        account = self.login_web_data.account or "",
        sdkToken = config.sdk_token or "",
    }
    if config.create_new_role then
        reqlogin_args.serverId = config.server_id or 0
        reqlogin_args.createNewRole = true
    end
    self:_enqueue_request("reqlogin", reqlogin_args)
    self.status = M.STATE_WAIT_LOGIN
    print("sproto_client relogin, account=" .. tostring(self.login_web_data.account))
end

----------------------------------------------------------------------
-- 服务器包确认(confirmNetMsg)
----------------------------------------------------------------------
function M:confirm_net_msg(session_response, session_sync)
    self:_enqueue_request("confirmNetMsg", {
        sessionResponse = session_response or 0,
        sessionSync = session_sync or 0,
    })
end

----------------------------------------------------------------------
-- 注入任务管理器
----------------------------------------------------------------------
function M:set_task_manager(mgr)
    self.task_mgr = mgr
end

return M