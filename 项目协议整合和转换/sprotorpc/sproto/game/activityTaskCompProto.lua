-- 战力达标活动 4801 ~ 4900
local activityTaskCompProto = {}

activityTaskCompProto.struct = [[
    .ComActivityTaskCompCell {
        index 0: integer  
        claimType 1: integer        # 对该槽位领取类型 已领取才有相关数据 activityTaskCompRewardType
        claimedNum 2: integer       # 已经被领取数量
    }

    .ComActivityTaskCompParams {
        taskGroupId 0: integer  # 任务组id
        rankCfgId 1: integer # 展示阶段前的排行榜
    }

    .ComActivityTaskComp {
        round 0: integer             # 轮次
        cellList 1: *ComActivityTaskCompCell(index)
        actId 2: integer             # 活动id
        params 3: ComActivityTaskCompParams  # 活动配置参数
        recordValue 4: integer      # 达成条件
    }

    .ComSyncActivityTaskComp {
        news 0: *ComActivityTaskComp(actId)
        changes 1: *ComActivityTaskComp(actId)
    }

]]

activityTaskCompProto.c2s = activityTaskCompProto.struct .. [[

reqActivityTaskCompLimitReward 4801 { # 获取限制奖励已领取情况列表
    request {
        actId 0: uint32 # 活动id
    }
    response {
    }
}

reqActivityTaskCompClaimReward 4802 { # 领取奖励
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

activityTaskCompProto.s2c = activityTaskCompProto.struct .. [[
syncActivityTaskCompRecordValue 4803 { # 同步限制奖励已领取情况记录值
    request {
        actId 0: integer # 活动id
        recordValue 1: integer # 记录值
    }
    response {
    }
}
    
]]

return activityTaskCompProto