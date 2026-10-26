--
-- author: TQING<tqing1128@gmail.com>
-- date: 2023-09-20 11:38:40
--

local activityProto = {}

activityProto.struct = [[
    .ActivityComponentState {
        id 0 : integer # 组件 id
        state 1 : integer # 组件状态
    }

    .Activity {
        actId 0 : integer # 活动 id
        uniqueId 1 : integer # 活动唯一 id
        round 2 : integer # 活动轮次
        state 3 : integer # 当前活动状态
        startTimestamp 4 : integer # 活动开始时间戳
        stagesDuration 5 : *integer # 活动阶段持续时间
        over 6 : boolean # 活动是否结束
        weight 7 : integer # 活动权重
        specialShow 8 : boolean # 是否特殊展示
        uiParam 9 : integer # 活动 ui 参数 id
        join 10 : boolean # 是否参与
    }

    .ActivityAgenda {
        agendaId 0 : string # 日程 id
        actId 1 : integer # 活动 id
        triggerTimestamp 2 : integer # 活动触发时间戳
        duration 3 : integer # 活动持续时间
        weight 4 : integer # 活动权重
        uiParam 5 : integer # 活动 ui 参数 id
        showTime 6 : integer # 活动展示时间
        .Array {
            key 0 : integer
            value 1 : *integer
        }
        calendar 7 : *Array() # 活动日历展示时间
    }
]]

activityProto.c2s = activityProto.struct .. [[
    
]]

activityProto.s2c = activityProto.struct .. [[

]]

return activityProto