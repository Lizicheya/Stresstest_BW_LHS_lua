-- 活动 总签到领奖 组件 5301 ~ 5400
local activityTotalSignInCompProto = {}

activityTotalSignInCompProto.struct = [[
    .ComActivityTotalSignIn {
        round 0: integer                            # 轮次
        actId 1: integer                            # 活动id
        configId 2: integer                         # 活动配置参数(本组件指向ActivityNewbieGrowthReward-activityId字段)
        scoreClaimData 4: ComActivityScoreClaimData # 积分数据
    }

    .ComSyncActivityTotalSignIn {
        news 0: *ComActivityTotalSignIn(actId)
        changes 1: *ComActivityTotalSignIn(actId)
        removes 2: *integer
    }
]]

activityTotalSignInCompProto.c2s = activityTotalSignInCompProto.struct..[[
reqClaimTotalSignInReward 5301 { # 获取签到奖励
    request {
        actId 0: uint32 # 活动id
        day 1: uint32 # 第几天
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

reqClaimTotalSignInRewardOneKey 5302 { # 一键获取签到奖励
    request {
        actId 0: uint32 # 活动id
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

]]

activityTotalSignInCompProto.s2c = activityTotalSignInCompProto.struct..[[
    syncActivityTotalSignInScore 5302 { # 同步活动积分
    request {
        activityId 0: integer # 活动id
        score 1: integer # 活动积分
    }
}

]]

return activityTotalSignInCompProto