-- 活动 副本额外奖励 5401 ~ 5500
local activityDungeonRewardProto = {}

activityDungeonRewardProto.struct = [[
    .ComActivityDungeonReward {
        round 0: integer                            # 轮次
        actId 1: integer                            # 活动id
        taskGroupId 2: integer                      # 活动配置参数(activityChapterTaskCfg-group字段)
    }
    .ComSyncActivityDungeonReward {
        news 0: ComActivityDungeonReward
        changes 1: ComActivityDungeonReward
    }
]]

activityDungeonRewardProto.c2s = activityDungeonRewardProto.struct .. [[
    reqClaimDungeonReward 5401 { # 领取副本额外奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 配置表中的下标
    }
    response {
        ress 0: *ComRes # 获得的资源
    }
}
]]

activityDungeonRewardProto.s2c = activityDungeonRewardProto.struct .. [[

]]

return activityDungeonRewardProto