-- 克拉肯的复仇活动 5901 ~ 6000
local activityKrakenProto = {}

activityKrakenProto.struct = [[    

    .ComActivityKrakenParams {
        statGroupId 0: integer     # 统计组
        rewardGroupId 1: integer    # 积分奖励组
    }

    .ComActivityScoreClaimData {
        score 0: integer            # 积分
        claimList 1: *ComIntInt()   # 领取情况
    }

    .ComActivityKraken {
        round 0: integer             # 轮次
        actId 1: integer             # 活动id
        params 2: ComActivityKrakenParams  # 活动配置参数
        scoreClaimData 3: ComActivityScoreClaimData # 积分数据
        partCount 4: integer         # 每日参与集结次数
    }

    .ComSyncActivityKraken {
        news 0: *ComActivityKraken(actId)
        changes 1: *ComActivityKraken(actId)
        removes 2: *uint32
    }
]]

activityKrakenProto.c2s = activityKrakenProto.struct..[[
    reqClaimKrakenReward 5901 { # 请求领取奖励
        request {
            actId 0: uint32 # 活动id
            index 1: uint32 # 槽位下标
        }
        response {
            dropRes 0: *ComRes              # 获得的奖励
        }
    }

    findKrakenObj 5902 {
        request {
            npcCfgId 1: uint32
        }
        response {
            pos 1: ComPoint
        }
    }
]]

activityKrakenProto.s2c = activityKrakenProto.struct..[[
    
]]

return activityKrakenProto