-- game_bw 任务管理器
-- 对应 Python PressureTest_BW_LHS/modules/pressure/task_manager.py 的 TaskManager
-- 职责:聚合各业务 task 模块、按权重随机选任务、产出请求、记录响应统计

local util = require "util"
local config = require "config"

local M = {}
M.__index = M

-- 各业务任务模块(每个模块导出 all_tasks = { {name,weight,generate_request}, ... })
local task_modules = {
    army = require "task.army_task",
    hero = require "task.hero_task",
    backpack = require "task.backpack_task",
    produce = require "task.produce_task",
    heart = require "task.heart_task",
    -- login 模块仅占位,不参与调度
    -- login = require "task.login_task",
}

-- 构造 TaskManager
function M.new()
    local self = setmetatable({}, M)
    self.tasks = {}        -- 任务定义列表 {name, weight, generate_request}
    self.total_weight = 0  -- 权重总和
    self.stats = {}        -- 统计: name -> {count, success, fail, total_duration}
    self:load_default_tasks()
    return self
end

-- 加载默认任务:把各业务模块的 all_tasks 注册进来
function M:load_default_tasks()
    for _, mod in pairs(task_modules) do
        for _, task in ipairs(mod.all_tasks or {}) do
            self:add_task(task)
        end
    end
end

-- 添加任务
function M:add_task(task)
    if not task or (task.weight or 0) <= 0 then return end
    self.tasks[#self.tasks + 1] = task
    self.total_weight = self.total_weight + (task.weight or 0)
    self.stats[task.name] = { count = 0, success = 0, fail = 0, total_duration = 0 }
end

-- 清空任务
function M:clear_tasks()
    self.tasks = {}
    self.total_weight = 0
    self.stats = {}
end

-- 按权重随机选一个任务
function M:select_task()
    if self.total_weight <= 0 then return nil end
    local r = math.random(1, self.total_weight)
    local cur = 0
    for _, t in ipairs(self.tasks) do
        cur = cur + (t.weight or 0)
        if r <= cur then return t end
    end
    return self.tasks[#self.tasks]
end

----------------------------------------------------------------------
-- 产出下一个请求:对应 Python execute_random_task 的请求生成部分
-- 返回: (proto_name, args) 或 nil(无可执行任务)
----------------------------------------------------------------------
function M:next_request(sync_data)
    -- 尝试最多 8 次选出能产出请求的任务(任务前置条件不满足时多试几次)
    for _ = 1, 8 do
        local task = self:select_task()
        if not task then return nil end
        local proto_name, args = task.generate_request(sync_data)
        if proto_name then
            self.stats[task.name].count = self.stats[task.name].count + 1
            self._current_task_name = task.name
            self._current_start = util.now_ms()
            return proto_name, args
        end
    end
    return nil
end

-- 记录响应:对应 Python Task.record_execution
function M:record_response(proto_name, result, err_code)
    local name = self._current_task_name or proto_name
    local st = self.stats[name]
    if not st then return end
    local duration = util.now_ms() - (self._current_start or util.now_ms())
    if err_code == 0 then
        st.success = st.success + 1
    else
        st.fail = st.fail + 1
    end
    st.total_duration = st.total_duration + duration
    self._current_task_name = nil
    self._current_start = nil
end

-- 取所有统计:对应 Python get_all_stats
function M:get_all_stats()
    return self.stats
end

-- 重置统计
function M:reset_stats()
    for _, st in pairs(self.stats) do
        st.count = 0
        st.success = 0
        st.fail = 0
        st.total_duration = 0
    end
end

----------------------------------------------------------------------
-- 任务预设:对应 Python TaskPresets
-- 通过修改各任务的 weight 来实现不同负载场景
----------------------------------------------------------------------
local presets = {
    -- 轻负载:心跳为主,少量生产
    light = function(mgr)
        for _, t in ipairs(mgr.tasks) do
            if t.name == "confirmNetMsg" then t.weight = 5
            elseif t.name == "collectResource" then t.weight = 2
            else t.weight = 1 end
        end
    end,
    -- 正常负载:均衡
    normal = function(mgr)
        for _, t in ipairs(mgr.tasks) do
            t.weight = 2
        end
    end,
    -- 重负载:训练/采集为主
    heavy = function(mgr)
        for _, t in ipairs(mgr.tasks) do
            if t.name == "trainArmy" then t.weight = 5
            elseif t.name == "collectResource" then t.weight = 5
            elseif t.name == "collectArmy" then t.weight = 3
            else t.weight = 1 end
        end
    end,
    -- 战斗侧重
    combat = function(mgr)
        for _, t in ipairs(mgr.tasks) do
            if t.name == "upgradeHeroStarLv" then t.weight = 5
            elseif t.name == "upgradeHeroLv" then t.weight = 4
            elseif t.name == "healWoundedArmy" then t.weight = 3
            else t.weight = 1 end
        end
    end,
    -- 采集侧重
    gather = function(mgr)
        for _, t in ipairs(mgr.tasks) do
            if t.name == "collectResource" then t.weight = 6
            elseif t.name == "collectSpeedUp" then t.weight = 3
            else t.weight = 1 end
        end
    end,
}

-- 应用预设:重新计算 total_weight
function M:apply_preset(name)
    local fn = presets[name]
    if not fn then
        print("task_manager: unknown preset " .. tostring(name))
        return
    end
    fn(self)
    self.total_weight = 0
    for _, t in ipairs(self.tasks) do
        self.total_weight = self.total_weight + (t.weight or 0)
    end
end

return M
