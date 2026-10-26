-- 联盟积分活动 6001 ~ 6100
local activityAllianceScoreProto = {}

activityAllianceScoreProto.struct = [[
    .ComSyncActivityAllianceScore {
        news 0: ComActivityAllianceScore
        changes 1: ComActivityAllianceScore
    }

    .ComActivityAllianceScoreParams {
        configId 0: integer  # 任务组id
        allianceRankCfgId 1: integer # 联盟积分榜
        personRankCfgId 2: integer # 联盟内个人积分榜
    }

    .ComActivityAllianceScore {
        round 0: integer             # 轮次
        actId 1: integer             # 活动id
        params 2: ComActivityAllianceScoreParams  # 活动配置参数
        curDayAid 4: integer # 本日提供过积分的联盟id
        curDaySendScoreTime 5: integer # 本日提供过积分的时间
        scoreClaimData 6: ComActivityScoreClaimData # 积分数据
        personalScoreClaimData 7: ComActivityScoreClaimData # 活动数据
    }
]]

activityAllianceScoreProto.c2s = activityAllianceScoreProto.struct..[[
reqClaimAllianceScoreReward 6001 { # 请求领取奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 槽位下标
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

reqClaimAlliancePersonalScoreReward 6005 { # 请求领取奖励
    request {
        actId 0: uint32 # 活动id
        index 1: uint32 # 槽位下标
    }
    response {
        dropRes 0: *ComRes              # 获得的奖励
        newClaimList 1: *ComIntInt()    # 领取情况增量更新
    }
}

]]

activityAllianceScoreProto.s2c = activityAllianceScoreProto.struct..[[
syncActivityAllianceScore 6002 { # 同步联盟积分活动个人积分部分
    request {
        activityId 0: integer # 活动id
        score 1: integer # 活动积分
    }
}

syncActivityAllianceScoreAddScoreAidNTime 6003 { # 同步联盟积分活动本日贡献积分的联盟与刷新时间
    request {
        activityId 0: integer # 活动id
        curDayAid 1: integer # 本日加过积分的aid
        lastCheckNewDayTime 2: integer # 刷新时间
    }
}

syncActivityAllianceScoreQuitAlliance 6004 { # 通知退盟
    request {
        activityId 0: integer # 活动id
    }
}

]]

return activityAllianceScoreProto