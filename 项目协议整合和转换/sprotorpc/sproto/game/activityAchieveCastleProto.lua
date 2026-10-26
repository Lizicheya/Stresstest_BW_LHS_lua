-- 城堡等级达标活动 5801 ~ 5900
local activityAchieveCastleProto = {}

activityAchieveCastleProto.struct = [[
    .ComSyncActivityAchieveCastle {
        news 0: ComActivityAchieveCastle
        changes 1: ComActivityAchieveCastle
    }

    .ComActivityAchieveCastleParams {
        taskGroupId 0: integer  # 任务组id
        rankCfgId 1: integer    # 展示阶段前的排行榜
    }

    .ComActivityAchieveCastle {
        round 0: integer             # 轮次
        actId 1: integer             # 活动id
        params 2: ComActivityAchieveCastleParams  # 活动配置参数
        recordValue 3: integer      # 达成条件
    }
]]

activityAchieveCastleProto.c2s = activityAchieveCastleProto.struct..[[
reqClaimAchieveCastleReward 5801 { # 请求领取奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 槽位下标
        taskId 2: uint32 # 任务id
    }
    response {
        ress 0: *ComRes                     # 获得的资源
        rewardType 1: integer # 本次领取的奖励类型
    }
}

]]

activityAchieveCastleProto.s2c = activityAchieveCastleProto.struct..[[
    syncActivityAchieveCastleRecordValue 5802 { # 同步记录值
    request {
        actId 0: integer # 活动id
        recordValue 1: integer # 记录值
    }
    response {
    }
}
    
]]

return activityAchieveCastleProto