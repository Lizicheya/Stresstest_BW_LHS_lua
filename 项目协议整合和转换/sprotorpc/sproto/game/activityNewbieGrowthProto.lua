-- 活动 任务&积分 组件 5201 ~ 5300
local activityNewbieGrowthProto = {}

activityNewbieGrowthProto.struct = [[
    .ComActivityNewbieGrowth {
        round 0: integer                            # 轮次
        actId 1: integer                            # 活动id
        taskGroupId 2: integer                      # 活动配置参数(使用哪个任务组)
        progressRewardGroupID 3: integer            # 活动配置参数(使用哪个奖励组)
        scoreClaimData 4: ComActivityScoreClaimData # 积分数据
    }

    .ComSyncActivityNewbieGrowth {
        news 0: *ComActivityNewbieGrowth(actId)
        changes 1: *ComActivityNewbieGrowth(actId)
    }
]]

activityNewbieGrowthProto.c2s = activityNewbieGrowthProto.struct..[[

reqClaimTaskReward 5201 { # 领取任务奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # ActivityNewbieGrowthTaskCfg 配置表的 id
    }
    response {
        ress 0: *ComRes  # 获得的资源
    }
}

reqClaimProcessReward 5202 { # 获取积分进度奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 配置表配置项下标（槽位）
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

]]

activityNewbieGrowthProto.s2c = activityNewbieGrowthProto.struct..[[

]]

return activityNewbieGrowthProto