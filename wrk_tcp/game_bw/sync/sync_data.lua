-- game_bw 数据同步中心
-- 对应 Python PressureTest_BW_LHS/modules/syncData/sync_data.py 的 SyncData 类
-- 维护玩家全量缓存数据(领主/英雄/兵种/建筑/物品/雷达/科技/部队等)
-- 提供 update_xxx 系列同步入口、通用同步路由 update_sync_module_data、推送分发 PushHandler

local util = require "util"
local tinsert = table.insert
local M = {}

----------------------------------------------------------------------
-- PushHandler:推送分发器
-- 对应 Python sync_data.py 的 PushHandler 类
-- methods: 推送名 -> 处理函数
-- controller: 主分发函数
----------------------------------------------------------------------
local PushHandler = {}
PushHandler.__index = PushHandler

-- 构造 PushHandler
function PushHandler.new(sync_data)
    local self = setmetatable({}, PushHandler)
    self.sync_data = sync_data
    -- 推送处理函数表:推送协议名 -> function(self, msg)
    self.methods = {
        -- 资源/物品/英雄等通用增删改推送
        dictUpdate = function(this, msg) this.sync_data:handle_dict_update(msg) end,
        -- 通用:无匹配处理时仅记录
        default = function(this, msg)
            -- 默认无操作,真实实现按需扩展
        end,
    }
    return self
end

-- 主分发:按推送名路由
-- push_name: 推送协议名
-- msg: 解码后的字段表
function PushHandler:controller(push_name, msg)
    local fn = self.methods[push_name] or self.methods.default
    fn(self, msg)
end

----------------------------------------------------------------------
-- SyncData 类:玩家数据缓存与同步
----------------------------------------------------------------------
local SyncData = {}
SyncData.__index = SyncData

-- 构造 SyncData 实例
function SyncData.new()
    local self = setmetatable({}, SyncData)
    self.server_time = 0          -- 服务器时间(秒)
    self.lord = {}                -- 领主信息
    self.heros = {}               -- 英雄表: heroCfgId -> ComHero
    self.armys = {}               -- 兵种表: armyCfgId -> num
    self.wounded_armys = {}       -- 伤兵表
    self.buildings = {}           -- 建筑表: buildId -> info
    self.items = {}               -- 物品表: itemId -> info
    self.queues = {}              -- 队列表
    self.radar_events = {}        -- 雷达事件表
    self.techs = {}               -- 科技表
    self.alliance = {}            -- 联盟信息
    self.troops = {}              -- 自己的部队表: troopId -> info
    self.mass_troops = {}         -- 集结部队表
    self.task_table = {}          -- 任务表
    self.guide_table = {}         -- 引导表
    self.login_info = {}          -- 登录同步的全量数据
    self.push_handler = PushHandler.new(self)
    return self
end

-- 服务器时间设置(由心跳回包更新)
function SyncData:set_server_time(t)
    self.server_time = t
end

function SyncData:get_server_time()
    return self.server_time
end

----------------------------------------------------------------------
-- 通用同步入口:对应 Python 的 update_sync_module_data
-- sproto_name: 推送/响应中的类型名(如 "ComLord" / "ComHero")
-- source_dict: 推送的源数据表
-- target_key:  要同步到的目标字段名(如 "lord" / "heros")
-- check_key:   用于判定增删改的子键(如 "heroCfgId")
----------------------------------------------------------------------
function SyncData:update_sync_module_data(sproto_name, source_dict, target_key, check_key)
    if not source_dict then return end
    local target = self[target_key] or {}
    self[target_key] = target

    -- 1) news: 新增项
    local news = source_dict.news
    if news then
        for _, item in ipairs(news) do
            local k = item[check_key] or item.id
            target[k] = item
        end
    end

    -- 2) changes: 修改项(按 check_key 合并字段)
    local changes = source_dict.changes
    if changes then
        for _, item in ipairs(changes) do
            local k = item[check_key] or item.id
            local old = target[k] or {}
            for fk, fv in pairs(item) do
                old[fk] = fv
            end
            target[k] = old
        end
    end

    -- 3) removes: 删除项
    local removes = source_dict.removes
    if removes then
        for _, k in ipairs(removes) do
            target[k] = nil
        end
    end
end

-- 路由:根据 target_key 调用对应 update_xxx
function SyncData:update_module(target_key, sproto_name, source_dict, check_key)
    local fn = self["update_" .. target_key]
    if fn then
        fn(self, sproto_name, source_dict, check_key)
    else
        -- 无专用函数则走通用同步
        self:update_sync_module_data(sproto_name, source_dict, target_key, check_key or "id")
    end
end

----------------------------------------------------------------------
-- 操作类型分发:对应 Python handle_operation_type
-- op_type: 1=new 2=update 3=remove
-- target_key / item / check_key
----------------------------------------------------------------------
function SyncData:handle_operation_type(op_type, target_key, item, check_key)
    local target = self[target_key] or {}
    self[target_key] = target
    local k = item[check_key] or item.id
    if op_type == 1 then
        target[k] = item
    elseif op_type == 2 then
        local old = target[k] or {}
        for fk, fv in pairs(item) do old[fk] = fv end
        target[k] = old
    elseif op_type == 3 then
        target[k] = nil
    end
end

-- 通用异常/递归键提取(对应 Python extract_keys_recursive)
function SyncData:extract_keys_recursive(tbl, key_chain)
    key_chain = key_chain or {}
    if type(tbl) ~= "table" then return key_chain end
    for k, v in pairs(tbl) do
        tinsert(key_chain, k)
        if type(v) == "table" then
            self:extract_keys_recursive(v, key_chain)
        end
    end
    return key_chain
end

-- 通用 dict 更新推送入口(由 PushHandler 调用)
function SyncData:handle_dict_update(msg)
    -- msg 形如 { target_key = { news=..., changes=..., removes=... } }
    if type(msg) ~= "table" then return end
    for tk, payload in pairs(msg) do
        if type(payload) == "table" and (payload.news or payload.changes or payload.removes) then
            self:update_module(tk, nil, payload, payload.check_key or "id")
        end
    end
end

----------------------------------------------------------------------
-- 各业务 update_xxx 系列方法
-- 这里实现常用业务的高频同步入口,其余沿用通用 update_module
----------------------------------------------------------------------

-- 领主信息同步:对应 Python update_lord
function SyncData:update_lord(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.lord[k] = v
    end
end

-- 英雄同步:对应 Python update_heros,check_key = heroCfgId
function SyncData:update_heros(_, source_dict, check_key)
    self:update_sync_module_data("ComHero", source_dict, "heros", check_key or "heroCfgId")
end

-- 兵种同步:对应 Python update_armys
function SyncData:update_armys(_, source_dict, check_key)
    self:update_sync_module_data("ComArmyIdAndNum", source_dict, "armys", check_key or "id")
end

-- 伤兵同步
function SyncData:update_wounded_armys(_, source_dict, check_key)
    self:update_sync_module_data("ComArmyIdAndNum", source_dict, "wounded_armys", check_key or "id")
end

-- 建筑同步
function SyncData:update_buildings(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "buildings", check_key or "buildId")
end

-- 物品同步
function SyncData:update_items(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "items", check_key or "itemId")
end

-- 队列同步
function SyncData:update_queues(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "queues", check_key or "id")
end

-- 雷达事件同步
function SyncData:update_radar_events(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "radar_events", check_key or "id")
end

-- 科技同步
function SyncData:update_techs(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "techs", check_key or "id")
end

-- 联盟同步
function SyncData:update_alliance(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.alliance[k] = v
    end
end

-- 任务同步
function SyncData:update_tasks(_, source_dict, check_key)
    self:update_sync_module_data(nil, source_dict, "task_table", check_key or "id")
end

-- 引导同步
function SyncData:update_guide(_, source_dict)
    if not source_dict then return end
    for k, v in pairs(source_dict) do
        self.guide_table[k] = v
    end
end

----------------------------------------------------------------------
-- 查询接口
----------------------------------------------------------------------

-- 取领主信息
function SyncData:get_lord_info()
    return self.lord
end

-- 取领主等级
function SyncData:get_lord_lv()
    return self.lord.lv or 0
end

-- 取英雄列表
function SyncData:get_hero_info()
    return self.heros
end

-- 取指定英雄
function SyncData:get_hero(hero_cfg_id)
    return self.heros[hero_cfg_id]
end

-- 取兵种数量
function SyncData:get_army_num(army_cfg_id)
    return self.armys[army_cfg_id] or 0
end

-- 取全部兵种
function SyncData:get_all_armys()
    return self.armys
end

-- 取建筑列表
function SyncData:get_building_list()
    return self.buildings
end

-- 取指定建筑
function SyncData:get_building(build_id)
    return self.buildings[build_id]
end

-- 取物品列表
function SyncData:get_all_items()
    return self.items
end

-- 取指定物品
function SyncData:get_item(item_id)
    return self.items[item_id]
end

-- 取物品数量
function SyncData:get_item_count(item_id)
    local it = self.items[item_id]
    if not it then return 0 end
    return it.num or 0
end

-- 取队列
function SyncData:get_queue(qid)
    return self.queues[qid]
end

-- 取雷达事件
function SyncData:get_radar_events()
    return self.radar_events
end

-- 取科技等级
function SyncData:get_tech_lv(tech_id)
    local t = self.techs[tech_id]
    return t and t.lv or 0
end

-- 取部队
function SyncData:get_troop(troop_id)
    return self.troops[troop_id]
end

-- 取全部部队表
function SyncData:get_all_troops()
    return self.troops
end

-- 取全部部队数量
function SyncData:get_all_troop_num()
    local n = 0
    for _ in pairs(self.troops) do n = n + 1 end
    return n
end

-- 取联盟信息
function SyncData:get_alliance_info()
    return self.alliance
end

----------------------------------------------------------------------
-- 部队/英雄使用情况跟踪(对应 Python 的 add_check_troop 等)
----------------------------------------------------------------------

-- 添加部队到跟踪表
function SyncData:add_check_troop(troop_id, info)
    self.troops[troop_id] = info
end

-- 更新跟踪的部队
function SyncData:update_check_troop(troop_id, info)
    local old = self.troops[troop_id] or {}
    for k, v in pairs(info) do old[k] = v end
    self.troops[troop_id] = old
end

-- 移除跟踪的部队
function SyncData:remove_check_troop(troop_id)
    self.troops[troop_id] = nil
end

-- 添加集结部队
function SyncData:add_mass_troop(troop_id, info)
    self.mass_troops[troop_id] = info
end

-- 更新集结部队
function SyncData:update_mass_troop_info(troop_id, info)
    local old = self.mass_troops[troop_id] or {}
    for k, v in pairs(info) do old[k] = v end
    self.mass_troops[troop_id] = old
end

-- 移除集结部队
function SyncData:remove_mass_troop(troop_id)
    self.mass_troops[troop_id] = nil
end

-- 初始化所有自己部队(对应 init_all_self_troop)
function SyncData:init_all_self_troop(troop_list)
    self.troops = {}
    if not troop_list then return end
    for _, t in ipairs(troop_list) do
        self.troops[t.troopId or t.id] = t
    end
end

-- 更新所有自己部队
function SyncData:update_all_self_troop(troop_list)
    if not troop_list then return end
    for _, t in ipairs(troop_list) do
        local tid = t.troopId or t.id
        local old = self.troops[tid] or {}
        for k, v in pairs(t) do old[k] = v end
        self.troops[tid] = old
    end
end

-- 从全部部队表里移除
function SyncData:remove_from_all_self_troop(troop_id)
    self:remove_check_troop(troop_id)
end

----------------------------------------------------------------------
-- 登录同步:对应 Python set_login_global_sync / get_module_login_info
----------------------------------------------------------------------
function SyncData:set_login_global_sync(login_data)
    self.login_info = login_data or {}
    -- 把常用字段直接映射到对应缓存表
    if login_data.lord then self:update_lord(nil, login_data.lord) end
    if login_data.heros then self.heros = login_data.heros end
    if login_data.armys then self.armys = login_data.armys end
    if login_data.buildings then self.buildings = login_data.buildings end
    if login_data.items then self.items = login_data.items end
    if login_data.queues then self.queues = login_data.queues end
    if login_data.radarEvents then self.radar_events = login_data.radarEvents end
    if login_data.techs then self.techs = login_data.techs end
    if login_data.alliance then self.alliance = login_data.alliance end
    if login_data.troops then self:init_all_self_troop(login_data.troops) end
    if login_data.tasks then self.task_table = login_data.tasks end
    if login_data.guides then self.guide_table = login_data.guides end
end

function SyncData:get_module_login_info()
    return self.login_info
end

function SyncData:del_login_global_sync()
    self.login_info = {}
end

function SyncData:get_base_info()
    return self.login_info
end

function SyncData:get_server_time()
    return self.server_time
end

----------------------------------------------------------------------
-- 取本模块导出
----------------------------------------------------------------------
M.SyncData = SyncData
M.PushHandler = PushHandler

-- 工厂函数:快捷创建 SyncData 实例
function M.new()
    return SyncData.new()
end

return M
