-- 英雄训练活动 8631 ～ 8680
local activityHeroTrainProto = {}

activityHeroTrainProto.struct = [[
    .ComActHeroTrainStat { # 英雄训练活动统计信息
        statCfgId 0: integer
        count 1: integer
    }

    .ComActHeroTrain {     # 英雄训练活动信息
        actId 0: integer   # 活动id
        round 1: integer   # 轮次
        state 2: integer
        isOver 3: boolean
        groupId 4: integer
        gainList 5: *ComIntInt()
        stat 6: *ComActHeroTrainStat(statCfgId)
    }

    .ComSyncActHeroTrain {
        news 0: *ComActHeroTrain(actId)
        changes 1: *ComActHeroTrain(actId)
        removes 2: *integer
    }
]]

activityHeroTrainProto.c2s = activityHeroTrainProto.struct .. [[
    reqActivityHeroTrainReward 8631 {  # 请求领取英雄训练活动奖励
        request {
            actId 0: uint32       # 活动id
            id 1: uint32          # 配置表id
        }
        response {
            dropRes 0: *ComRes    # 获得的奖励
        }
    }
]]

activityHeroTrainProto.s2c = activityHeroTrainProto.struct .. [[
]]

return activityHeroTrainProto
