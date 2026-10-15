-- protocol_task.lua
-- 对应 Python PressureTest_BW_LHS/modules/protocol/protocol_task.py
-- 从 xlsx 模板读取协议用例,登录后逐条执行,结果写回新 xlsx
-- 实现 task_mgr 兼容接口: next_request(sync_data) / record_response(proto, result, err_code)

local xlsx_util = require "protocol.xlsx_util"
local util = require "util"
local cjson = require "cjson"

local M = {}
M.__index = M

----------------------------------------------------------------------
-- 列名常量(对应 xlsx 表头)
----------------------------------------------------------------------
local COL = {
    user_id       = "robotUserId",
    cmd_module    = "cmdModule",
    msg_id        = "msgId",
    is_used       = "isUsed",
    is_received   = "isReceived",
    pkt           = "pkt",
    expect_err    = "expectErrId",
    actual_err    = "returnErrId",
    result        = "isPass",
    res           = "returnResult",
    is_ran        = "isRan",
    is_re_login   = "isReLogin",
    sleep_time    = "sleepTime",
    res_var       = "resVar",
    write_log     = "writeLog",
}

local BEGIN_ROW = 2  -- 结果写入起始行

----------------------------------------------------------------------
-- 列号转字母
----------------------------------------------------------------------
local function col_num_to_letters(n)
    local s = ""
    while n > 0 do
        local rem = (n - 1) % 26
        s = string.char(string.byte("A") + rem) .. s
        n = math.floor((n - 1) / 26)
    end
    return s
end

local function parse_cell_ref(ref)
    local letters, digits = string.match(ref, "^([A-Z]+)(%d+)$")
    if not letters then return nil, nil end
    local n = 0
    for i = 1, #letters do
        n = n * 26 + (string.byte(letters, i) - string.byte("A") + 1)
    end
    return n, tonumber(digits)
end

----------------------------------------------------------------------
-- 构造:加载模板 xlsx,解析控制页
----------------------------------------------------------------------
function M.new(opts)
    opts = opts or {}
    local self = setmetatable({}, M)

    self.template_path = opts.template_path or "game_bw/protocol/protocol_model-lhs.xlsx"
    self.output_path = opts.output_path

    -- pcall 包装:inflate 内部 error() 会抛错而非返回 nil+err,
    -- 缺失 pcall 时错误会传播到 M.writeable 被 C 层捕获,导致
    -- c->request 置 NULL、AE_WRITABLE 被删、thread Lua 状态损坏,
    -- 同 thread 其他连接全部永久 abandon(100 账号压测中 thread 3
    -- 的 5 个连接因单次 inflate 抛错坏掉,后续 23 个账号 abandon)
    local ok, wb, err = pcall(xlsx_util.read_xlsx, self.template_path)
    if not ok then
        wb, err = nil, wb
    end
    if not wb then
        -- 多线程并发 inflate 偶发抛错(nil at index N in concat),
        -- 此处不 error 否则会让 client.new 崩溃、连接无法跑登录链路。
        -- 降级:wb 留空、done=true、跳过 _parse_control_sheet,
        -- 连接仍走完整登录→网关→鉴权→心跳贡献压测流量,仅不产出业务请求
        self.wb = {}
        self.control_sheet_name = opts.control_sheet_name or "运行"
        self.run_case_sheet_list = {}
        self.run_times = 1
        self.fun_var_json = {}
        self.current_sheet_idx = 1
        self.current_run = 0
        self.current_case_idx = 0
        self.waiting_response = false
        self.done = true
        self.var_dic = {}
        self.results = {}
        self.client = nil
        self.next_available_time = 0
        self.pending_relogin = false
        -- 降级标记:xlsx 读取失败时任务立即 done,但不计入提前结束判定,
        -- 否则多线程 inflate 偶发失败会让全部连接秒级 done 触发压测提前退出
        self.degraded = true
        io.stderr:write(string.format("protocol_task: read xlsx failed, fallback to idle: %s\n", tostring(err)))
        io.stderr:flush()
        return self
    end
    self.wb = wb

    self.control_sheet_name = opts.control_sheet_name or "运行"
    self:_parse_control_sheet()

    self.current_sheet_idx = 1
    self.current_run = 0
    self.current_case_idx = 0
    self.waiting_response = false
    self.done = false

    self.var_dic = {}
    self.results = {}
    self.client = nil        -- sproto_client 引用(用于重新登录/账号切换)
    self.next_available_time = 0  -- sleep_time 非阻塞等待的解锁时间戳
    self.pending_relogin = false  -- 是否需要重新登录

    return self
end

----------------------------------------------------------------------
-- 解析控制页:runTaskList / RunTimes / funVar
----------------------------------------------------------------------
function M:_parse_control_sheet()
    local sheet = self.wb.sheets[self.control_sheet_name]
    if not sheet then
        error("protocol_task: control sheet not found: " .. self.control_sheet_name)
    end
    local cells = sheet.cells

    local header_map = {}
    local col = 1
    while true do
        local val = cells[col_num_to_letters(col) .. "1"]
        if val == nil then break end
        header_map[tostring(val)] = col
        col = col + 1
    end

    local function get_control(col_name)
        local c = header_map[col_name]
        if not c then return nil end
        return cells[col_num_to_letters(c) .. "3"]
    end

    local run_task_str = tostring(get_control("runTaskList") or "")
    self.run_case_sheet_list = {}
    for s in string.gmatch(run_task_str, "[^;]+") do
        s = string.gsub(s, "^%s*(.-)%s*$", "%1")
        if s ~= "" then
            self.run_case_sheet_list[#self.run_case_sheet_list + 1] = s
        end
    end

    self.run_times = tonumber(get_control("RunTimes")) or 1

    self.fun_var_json = {}
    local fun_var_str = get_control("funVar")
    if fun_var_str and type(fun_var_str) == "string" and fun_var_str ~= "" then
        local ok, parsed = pcall(cjson.decode, fun_var_str)
        if ok and type(parsed) == "table" then
            self.fun_var_json = parsed
        end
    end

    self.fun_var_parsed = {}
    for key, fun_value in pairs(self.fun_var_json) do
        local parts = {}
        for p in string.gmatch(tostring(fun_value), "[^.]+") do
            parts[#parts + 1] = p
        end
        if #parts >= 2 then
            self.fun_var_parsed[#self.fun_var_parsed + 1] = {
                key = key,
                fun_type = parts[2],
                param_str = parts[#parts],
            }
        end
    end

    print(string.format("protocol_task: sheets=%d, run_times=%d, fun_vars=%d",
        #self.run_case_sheet_list, self.run_times, #self.fun_var_parsed))
end

----------------------------------------------------------------------
-- 解析用例 sheet
----------------------------------------------------------------------
function M:_parse_case_sheet(sheet_name)
    local sheet = self.wb.sheets[sheet_name]
    if not sheet then
        print("protocol_task: case sheet not found: " .. sheet_name)
        return nil
    end
    local cells = sheet.cells

    local header_map = {}
    local col = 1
    while true do
        local val = cells[col_num_to_letters(col) .. "1"]
        if val == nil then break end
        header_map[tostring(val)] = col
        col = col + 1
    end

    local max_row = 1
    for ref, _ in pairs(cells) do
        local _, row = parse_cell_ref(ref)
        if row and row > max_row then max_row = row end
    end

    local cases = {}
    for row = BEGIN_ROW + 1, max_row do
        local function cellv(col_name)
            local c = header_map[col_name]
            if not c then return nil end
            return cells[col_num_to_letters(c) .. row]
        end

        local cmd_module = cellv(COL.cmd_module)
        if cmd_module == nil or cmd_module == "" then
            cmd_module = sheet_name
        end

        local pkt_raw = cellv(COL.pkt)
        local pkt = {}
        if pkt_raw and pkt_raw ~= "" then
            local ok, parsed = pcall(cjson.decode, tostring(pkt_raw))
            if ok and type(parsed) == "table" then
                pkt = parsed
            end
        end

        local expect_err = cellv(COL.expect_err)
        if expect_err == nil or expect_err == "" then expect_err = 0 end

        local res_var_raw = cellv(COL.res_var)
        local res_var = {}
        if res_var_raw and res_var_raw ~= "" then
            local ok, parsed = pcall(cjson.decode, tostring(res_var_raw))
            if ok and type(parsed) == "table" then
                res_var = parsed
            end
        end

        cases[#cases + 1] = {
            row         = row,
            user_id     = cellv(COL.user_id),
            cmd_module  = tostring(cmd_module),
            msg_id      = cellv(COL.msg_id),
            is_used     = (cellv(COL.is_used) and cellv(COL.is_used) ~= 0) and 1 or 0,
            is_received = (cellv(COL.is_received) == 0) and 0 or 1,
            pkt         = pkt,
            expect_err  = tonumber(expect_err) or 0,
            is_ran      = cellv(COL.is_ran),
            is_re_login = cellv(COL.is_re_login),
            sleep_time  = tonumber(cellv(COL.sleep_time)) or 0,
            res_var     = res_var,
            write_log   = cellv(COL.write_log) or 0,
        }
    end

    self._current_cols = {
        actual_err = header_map[COL.actual_err],
        result     = header_map[COL.result],
        res        = header_map[COL.res],
        is_ran     = header_map[COL.is_ran],
    }

    return cases
end

----------------------------------------------------------------------
-- 生成函数变量
----------------------------------------------------------------------
function M:_get_fun_var()
    for _, fv in ipairs(self.fun_var_parsed) do
        local key = fv.key
        local ftype = fv.fun_type
        local param = fv.param_str

        if ftype == "randint" then
            local p = string.gsub(param, "[()]", "")
            local lo, hi = string.match(p, "(-?%d+),(-?%d+)")
            if lo and hi then
                self.var_dic[key] = math.random(tonumber(lo), tonumber(hi))
            end
        elseif ftype == "randomChar" then
            local nums = {}
            for n in string.gmatch(param, "%d+%.?%d*") do
                nums[#nums + 1] = tonumber(n)
            end
            local len
            if #nums == 1 then len = nums[1]
            elseif #nums >= 2 then len = math.random(nums[1], nums[2])
            else len = 8 end
            local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            local s = ""
            for i = 1, len do
                local idx = math.random(1, #chars)
                s = s .. string.sub(chars, idx, idx)
            end
            self.var_dic[key] = s
        elseif ftype == "randomChoiceInt" then
            local nums = {}
            for n in string.gmatch(param, "%d+%.?%d*") do
                nums[#nums + 1] = tonumber(n)
            end
            if #nums > 0 then
                self.var_dic[key] = nums[math.random(1, #nums)]
            end
        elseif ftype == "randomChoiceChar" then
            local nums = {}
            for n in string.gmatch(param, "%d+%.?%d*") do
                nums[#nums + 1] = n
            end
            if #nums > 0 then
                self.var_dic[key] = nums[math.random(1, #nums)]
            end
        elseif ftype == "uid" then
            self.var_dic[key] = self.uid or 0
        end
    end
end

----------------------------------------------------------------------
-- 变量替换 ${var}
----------------------------------------------------------------------
function M:_substitute_vars(pkt)
    if type(pkt) ~= "table" then return pkt end
    local pkt_str = cjson.encode(pkt)
    if not string.find(pkt_str, "${", 1, true) then
        return pkt
    end
    local copy = util.deepcopy(pkt)
    local function replace_in_table(t)
        for k, v in pairs(t) do
            if type(v) == "table" then
                replace_in_table(v)
            elseif type(v) == "string" then
                t[k] = string.gsub(v, "%${([^}]+)}", function(varname)
                    local val = self.var_dic[varname]
                    if val == nil then return "${" .. varname .. "}" end
                    return tostring(val)
                end)
            end
        end
    end
    replace_in_table(copy)
    return copy
end

----------------------------------------------------------------------
-- 从响应提取变量
----------------------------------------------------------------------
function M:_extract_res_var(respond_value, res_var)
    if not res_var or type(res_var) ~= "table" then return end
    for var_name, json_path in pairs(res_var) do
        local value = respond_value
        for key in string.gmatch(tostring(json_path), "[^.]+") do
            if type(value) == "table" then
                value = value[key]
            else
                value = nil
                break
            end
        end
        self.var_dic[var_name] = value
    end
end

----------------------------------------------------------------------
-- task_mgr 接口:产出下一个请求
----------------------------------------------------------------------
function M:next_request(sync_data)
    if self.done or self.waiting_response then
        return nil
    end

    -- sleep_time 非阻塞等待:未到解锁时间则不产出请求
    if self.next_available_time > 0 and os.time() < self.next_available_time then
        return nil
    end
    self.next_available_time = 0

    -- 若有挂起的重新登录请求,先执行(不产出协议请求)
    if self.pending_relogin and self.client then
        self.pending_relogin = false
        if self.client.relogin then
            self.client:relogin(self.pending_account)
        end
        return nil
    end

    if not self._current_cases then
        self:_advance_sheet()
        if not self._current_cases then
            self.done = true
            return nil
        end
    end

    while self.current_case_idx <= #self._current_cases do
        self.current_case_idx = self.current_case_idx + 1
        if self.current_case_idx > #self._current_cases then break end

        local case = self._current_cases[self.current_case_idx]

        if case.is_ran then
            self:_record_result(case, "", "", "")
        elseif not case.is_used then
            self:_record_result(case, "not run", "success", "not run")
        else
            self._current_case = case
            self.waiting_response = true

            -- is_re_login:该用例执行后需重新登录
            if case.is_re_login then
                self.pending_relogin = true
            end

            -- robotUserId 账号切换:若指定了不同账号,切换后重新登录
            if case.user_id and case.user_id ~= "" then
                self.pending_relogin = true
                self.pending_account = case.user_id
            end

            -- sleep_time:记录等待时间戳(事件驱动下非阻塞)
            if case.sleep_time > 0 then
                self.next_available_time = os.time() + case.sleep_time
            end

            if case.cmd_module == "if" then
                return self:_handle_if(case)
            end

            local proto_name = case.cmd_module
            local pkt = self:_substitute_vars(case.pkt)

            -- cmdModule 分流:仅当形如 "前缀.方法" 时按下述规则分发,否则视为协议名正常发送
            -- 1) 前缀为纯小写 cheat:以 "方法" 作为作弊指令,走通用 cheat 接口(携带 data)
            -- 2) 前缀为 cheattask(大小写兼容):调用 cheattask 模块对应方法(内部完成作弊请求)
            -- 3) 前缀为 XXXTask:调用 task/xxxtask/xxx_task 模块对应方法,按返回的协议名/内容发送
            local prefix, method = string.match(proto_name, "^([^.]+)%.(.+)$")
            if prefix == "cheat" then
                print(string.format("protocol_task cheat matched: cmd_module=%s pkt=%s",
                    tostring(proto_name), cjson.encode(pkt or {})))
                return self:_handle_cheat(case, pkt, method)
            elseif prefix and string.lower(prefix) == "cheattask" then
                return self:_handle_cheattask(case, pkt, method)
            elseif prefix and string.find(string.lower(prefix), "task$") then
                return self:_handle_task_dispatch(case, pkt)
            end

            -- is_received == 0:只发不收,立即记录结果并继续下一个用例
            if case.is_received == 0 then
                self:_record_result(case, "not receive", "success", "not receive")
                self.waiting_response = false
                return proto_name, pkt  -- 发送协议但不等响应
            end

            return proto_name, pkt
        end
    end

    self:_finish_sheet()
    if self.done then return nil end
    return self:next_request(sync_data)
end

----------------------------------------------------------------------
-- if 控制语句
----------------------------------------------------------------------
function M:_handle_if(case)
    local pkt = self:_substitute_vars(case.pkt)
    local compare_result = false
    local expression = ""

    for k, v in pairs(pkt) do
        local key_str = tostring(k)
        local pkt_value
        if string.find(key_str, "${", 1, true) then
            local varname = string.match(key_str, "%${([^}]+)}")
            pkt_value = self.var_dic[varname]
        else
            pkt_value = k
        end
        local compare_value = v
        local op = tostring(case.msg_id)

        if op == ">" then compare_result = pkt_value > compare_value
        elseif op == "<" then compare_result = pkt_value < compare_value
        elseif op == "=" then compare_result = pkt_value == compare_value
        elseif op == ">=" then compare_result = pkt_value >= compare_value
        elseif op == "<=" then compare_result = pkt_value <= compare_value
        elseif op == "!=" then compare_result = pkt_value ~= compare_value
        end
        expression = tostring(pkt_value) .. op .. tostring(compare_value)
        break
    end

    local result_dic = { result = compare_result, expression = expression }
    self:_record_result(case, tostring(result_dic), "success", tostring(compare_result))
    self.waiting_response = false
    return self:next_request(nil)
end

----------------------------------------------------------------------
-- cheat 命令处理
----------------------------------------------------------------------
function M:_handle_cheat(case, pkt, cmd_str)
    local cheat_task = require "task.cheattask.cheat_task"
    if not cmd_str then
        _, cmd_str = string.match(case.cmd_module, "^([^.]+)%.(.+)$")
    end
    local result = "cheat failed"
    local err_code = 1

    -- data 注入 uid:对应 Python 版所有 GM 命令都强制携带 client.uid 的约定
    -- (服务端按 uid 定位玩家,缺 uid 时命令无法路由,报 cmd not found)
    -- xlsx pkt 已写 uid 时不覆盖,以用例显式配置为准
    local data = pkt or {}
    if data.uid == nil and self.uid then
        data.uid = self.uid
    end

    -- 发送前日志:输出实际执行的作弊命令与变量替换后的参数
    print(string.format("protocol_task cheat send: cmd=%s data=%s",
        tostring(cmd_str), cjson.encode(data)))

    -- 调用通用 cheat 接口(对应原 Python cheat_task.curl_cheat(cmd_str, pkt))
    local ok, res = pcall(cheat_task.curl_cheat, cmd_str, data)
    if ok and res then
        if type(res) == "table" and res.msg == "success" then
            err_code = 0
        end
        result = cjson.encode(res)
    end

    -- 结果日志:便于从运行日志直接确认 cheat 是否成功
    print(string.format("protocol_task cheat[%s] err=%d result=%s", case.cmd_module, err_code, result))
    self:_record_result(case, result, err_code == case.expect_err and "success" or "failed", tostring(err_code))
    self.waiting_response = false
    return self:next_request(nil)
end

----------------------------------------------------------------------
-- cheattask 命令处理:cmd_module 为 cheattask.yyy(前缀大小写兼容)
-- 加载 task/cheattask/cheat_task 模块,调用其 yyy 方法(方法内部完成作弊 HTTP 请求),
-- 不返回 sproto 协议,直接记录结果并继续下一个用例
----------------------------------------------------------------------
function M:_handle_cheattask(case, pkt, method)
    local mod_name = "task.cheattask.cheat_task"
    local ok_mod, mod = pcall(require, mod_name)
    if not ok_mod or type(mod) ~= "table" or type(mod[method]) ~= "function" then
        self:_record_result(case, "cheattask method not found: " .. tostring(mod_name) .. "." .. tostring(method), "failed", "1")
        self.waiting_response = false
        return self:next_request(nil)
    end
    -- 作弊命令需 uid 定位玩家,方法签名以 uid 作为参数,传入当前登录 uid;
    -- 同时传入 pkt(xlsx 用例数据),便于方法按用例指定作弊参数
    local ok, res = pcall(mod[method], self.uid, pkt)
    local err_code = ok and 0 or 1
    local result = ok and (res and cjson.encode(res) or "ok") or tostring(res)
    print(string.format("protocol_task cheattask[%s] err=%d result=%s", case.cmd_module, err_code, result))
    self:_record_result(case, result, err_code == case.expect_err and "success" or "failed", tostring(err_code))
    self.waiting_response = false
    return self:next_request(nil)
end

----------------------------------------------------------------------
-- 通用 Task 分发:cmd_module 为 XXXTask.yyy 格式,
-- 目录 task/xxxtask/ 下 xxx_task.lua(LordTask -> task/lordtask/lord_task),
-- 再调用模块的 yyy 方法。方法返回 (sproto_name, msg)
-- 兼容 next_request 的 (proto_name, pkt) 返回值
----------------------------------------------------------------------
function M:_handle_task_dispatch(case, pkt)
    local prefix, method = string.match(case.cmd_module, "^([^.]+)%.(.+)$")
    if not prefix or not method then
        self:_record_result(case, "invalid cmd_module: " .. tostring(case.cmd_module), "failed", "1")
        self.waiting_response = false
        return self:next_request(nil)
    end
    -- 前缀去除末尾 Task 后缀(大小写不敏感)转小写作为基名,再拼目录/文件:
    -- LordTask -> task/lordtask/lord_task.lua -> 模块 task.lordtask.lord_task
    local base = string.lower(string.gsub(prefix, "[Tt][Aa][Ss][Kk]$", ""))
    local mod_name = "task." .. base .. "task." .. base .. "_task"
    local ok_mod, mod = pcall(require, mod_name)
    if not ok_mod or type(mod) ~= "table" or type(mod[method]) ~= "function" then
        self:_record_result(case, "task method not found: " .. tostring(mod_name) .. "." .. tostring(method), "failed", "1")
        self.waiting_response = false
        return self:next_request(nil)
    end
    -- 调用 task 对应方法,参数:(self 即 protocol_task, case, pkt)
    local ok, sproto_name, msg = pcall(mod[method], self, case, pkt)
    if not ok or not sproto_name then
        local err = msg or sproto_name or "unknown"
        self:_record_result(case, "task dispatch error: " .. tostring(err), "failed", "1")
        self.waiting_response = false
        return self:next_request(nil)
    end
    -- 返回 (proto_name, pkt):与 next_request 主路径一致,sproto_client 编码后发送
    return sproto_name, msg or {}
end

----------------------------------------------------------------------
-- task_mgr 接口:记录响应
----------------------------------------------------------------------
function M:record_response(proto_name, result, err_code)
    if not self.waiting_response or not self._current_case then
        return
    end

    local case = self._current_case
    err_code = err_code or 0

    if case.res_var and next(case.res_var) and err_code == 0 then
        self:_extract_res_var(result, case.res_var)
    end

    local pass = (err_code == case.expect_err) and "success" or "failed"
    local res_str = ""
    if result then
        if type(result) == "table" then
            res_str = cjson.encode(result)
        else
            res_str = tostring(result)
        end
    end

    -- write_log:启用时打印该用例的响应结果
    if case.write_log and case.write_log ~= 0 then
        print(string.format("protocol_task[%s] err=%d result=%s",
            case.cmd_module, err_code, res_str))
    end

    self:_record_result(case, res_str, pass, tostring(err_code))
    self.waiting_response = false
    self._current_case = nil
end

----------------------------------------------------------------------
-- 记录结果
----------------------------------------------------------------------
function M:_record_result(case, res_str, pass, err_str)
    local sheet_name = self._current_sheet_name
    if not self.results[sheet_name] then
        self.results[sheet_name] = {
            res_err_list = {},
            result_list = {},
            success_res_list = {},
            is_ran_list = {},
        }
    end
    local r = self.results[sheet_name]
    local idx = case.row - BEGIN_ROW
    r.res_err_list[idx] = err_str
    r.result_list[idx] = pass
    r.success_res_list[idx] = res_str
    r.is_ran_list[idx] = "1"
end

----------------------------------------------------------------------
-- 推进到下一个 sheet
----------------------------------------------------------------------
function M:_advance_sheet()
    if self.current_sheet_idx > #self.run_case_sheet_list then
        self._current_cases = nil
        return
    end
    self._current_sheet_name = self.run_case_sheet_list[self.current_sheet_idx]
    self._current_cases = self:_parse_case_sheet(self._current_sheet_name)
    self.current_case_idx = 0
    self.current_run = 0
    self:_get_fun_var()
end

----------------------------------------------------------------------
-- 完成当前 sheet 的一轮用例
-- 若仍有剩余轮次(current_run < run_times - 1),则重置用例索引重新执行本轮;
-- 否则写入结果并切换到下一个 sheet
----------------------------------------------------------------------
function M:_finish_sheet()
    -- 判断是否还有剩余轮次需要执行
    if self.current_run < self.run_times - 1 then
        self.current_run = self.current_run + 1
        self.current_case_idx = 0
        -- 每轮重新生成函数变量(对应原 Python 每轮调用 get_fun_var)
        self:_get_fun_var()
        return
    end

    -- 所有轮次执行完毕,写入结果并进入下一个 sheet
    self:_write_sheet_results()

    self.current_sheet_idx = self.current_sheet_idx + 1
    if self.current_sheet_idx > #self.run_case_sheet_list then
        self.done = true
        self:save()
        return
    end
    self:_advance_sheet()
end

----------------------------------------------------------------------
-- 写入当前 sheet 结果
----------------------------------------------------------------------
function M:_write_sheet_results()
    local sheet_name = self._current_sheet_name
    local r = self.results[sheet_name]
    if not r then return end

    local cols = self._current_cols
    if not cols then return end

    for i = 1, #r.result_list do
        local row = i + BEGIN_ROW
        if cols.actual_err and r.res_err_list[i] ~= nil then
            xlsx_util.set_cell(self.wb, sheet_name, col_num_to_letters(cols.actual_err) .. row, r.res_err_list[i])
        end
        if cols.result and r.result_list[i] ~= nil then
            xlsx_util.set_cell(self.wb, sheet_name, col_num_to_letters(cols.result) .. row, r.result_list[i])
        end
        if cols.res and r.success_res_list[i] ~= nil then
            xlsx_util.set_cell(self.wb, sheet_name, col_num_to_letters(cols.res) .. row, r.success_res_list[i])
        end
        if cols.is_ran and r.is_ran_list[i] ~= nil then
            xlsx_util.set_cell(self.wb, sheet_name, col_num_to_letters(cols.is_ran) .. row, r.is_ran_list[i])
        end
    end
end

----------------------------------------------------------------------
-- 设置 sproto_client 引用(用于重新登录/账号切换)
----------------------------------------------------------------------
function M:set_client(client)
    self.client = client
end

----------------------------------------------------------------------
-- 设置 uid(登录后调用)
----------------------------------------------------------------------
function M:set_uid(uid)
    self.uid = uid
end

----------------------------------------------------------------------
-- 设置账号名(登录后由 sproto_client 注入,供 save 文件名区分)
----------------------------------------------------------------------
function M:set_account(account)
    self.account = account
end

----------------------------------------------------------------------
-- 保存结果 xlsx
----------------------------------------------------------------------
function M:save()
    if not self.output_path then
        local ts = os.date("%Y-%m-%d_%H-%M-%S")
        -- 文件名包含账号名,便于多连接压测时区分每个账号的结果
        -- account 为空时回退到 uid,两者都空时保持原 result_<ts> 格式
        local tag = self.account or (self.uid and tostring(self.uid)) or ""
        if tag ~= "" then
            self.output_path = "game_bw/protocol/result_" .. tag .. "_" .. ts .. ".xlsx"
        else
            self.output_path = "game_bw/protocol/result_" .. ts .. ".xlsx"
        end
    end
    local ok, err = xlsx_util.save_xlsx(self.wb, self.output_path)
    if ok then
        print("protocol_task: results saved to " .. self.output_path)
    else
        print("protocol_task: save failed: " .. tostring(err))
    end
    return ok
end

----------------------------------------------------------------------
-- 是否已完成
----------------------------------------------------------------------
function M:is_done()
    return self.done
end

return M