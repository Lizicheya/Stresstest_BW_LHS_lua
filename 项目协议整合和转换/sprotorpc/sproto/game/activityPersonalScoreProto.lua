-- 活动 个人积分 5501 ~ 5600
local activityPersonalScoreProto = {}

activityPersonalScoreProto.struct = [[
    .ComActivityPersonalScoreParams {
        rankCfgId 0: integer    # 活动排行榜id
        configId 1: integer     # 对应配置表id(activityPointsRelation -> id)
    }

    .ComActivityPersonalScore {
        actId 0: integer                            # 活动id
        round 1: integer                            # 轮次
        params 2: ComActivityPersonalScoreParams    # 活动配置
        scoreClaimData 3: ComActivityScoreClaimData # 积分数据
        dayOfActOpen 4: integer                     # 开启活动的第几天了，0表示活动还没开启状态，这个数据没刷新
        buildLevelCfgId 5: integer                  # 根据主堡等级使用哪个配置的配置id
        lastRefreshIndex 6: integer                 # 上次刷新，在刷新配置中的（stagePointsTime字段）的数组下标
        curActPointCfgId 7: integer                 # 主题 因为可能自选改变主题，所以要记录
        dayScore 8: integer                         # 当前每日积分
        dayScoreClaimList 9: *ComIntInt()           # 每日积分进度奖励领取情况
        dayChgActPointCfgIdTimes 10: integer        # 当日更改主题次数
        dayTotalScoreOfActPoint 11: integer         # 当日所有主题累计总积分(就是scoreClaimData.score的总和)
    }

    .ComSyncActivityPersonalScore {
        news 0: *ComActivityPersonalScore(actId)
        changes 1: *ComActivityPersonalScore(actId)
    }
    
    .ComActivityPersonal {
        lastDayResetTime 0: integer           # 上次每日刷新时间戳
    }
]]

activityPersonalScoreProto.c2s = activityPersonalScoreProto.struct .. [[
reqClaimPersonalScoreReward 5501 { # 个人积分奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 积分奖励列表下标
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

reqChgPersonalScoreRule 5502 { # 更改个人积分获得积分规则
    request {
        actId 0: uint32        # 活动id
        actPointsId 1: uint32  # 新选择id
    }
    response {
    }
}

queryPersonalScoreRank 5503 {                      # 查询排行榜
    request {
        actId 0: uint32                            # 排行榜配置id
    }
    response {
        selfRank 0: integer                        # 自己的排名
        rank 1: ComRankList                        # 排行榜信息
        selfScore 2: integer                       # 自己的排行值
    }
}

reqClaimPersonalScoreDayScoreReward 5504 { # 个人每日积分奖励
    request {
        actId 0: uint32                    # 活动id
        index 1: uint32                    # 每日积分奖励列表下标
    }
    response {
        dropRes 0: *ComRes                 # 获得的奖励
    }
}

reqClaimPersonalScoreAllDayScoreReward 5505 { # 一键领取个人每日积分奖励
    request {
        actId 0: uint32                       # 活动id
    }
    response {
        dropRes 0: *ComRes                    # 获得的奖励
    }
}

]]

activityPersonalScoreProto.s2c = activityPersonalScoreProto.struct .. [[
    syncActivityPersonalScoreScore 5502 { # 同步活动积分
    request {
        activityId 0: integer             # 活动id
        score 1: integer                  # 活动当前途径的积分
        dayTotalScoreOfActPoint 2: integer # 活动当前每日累计总积分

        dayScore 3: integer               # 活动当前每日积分
        dayScoreClaimList 4: *ComIntInt() # 每日积分进度奖励领取情况
    }
}
]]

return activityPersonalScoreProto