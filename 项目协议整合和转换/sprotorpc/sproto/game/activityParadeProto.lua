-- 游园会活动 7601 ～ 7650
local activityParadeProto = {}

activityParadeProto.struct = [[
    .ComParadeParam {
        configId 1: uint32 #活动配置ID
    }

    .ComParamGameInfo {
        gameId 1: uint32          # 游戏ID
        score 2: uint32           # 游戏历史最高分
        achieveIdList 3: *ComIntBool()  # 小游戏已领取成就ID列表
    }

    .ComParadeActInfo {
        actId 0: uint32        # 活动id
        round 1: uint32        # 活动轮次
        param 2: ComParadeParam # 活动参数
        gameInfo 3: *ComParamGameInfo(gameId)
    }

    .ComSyncActivityParade {
        new 0: ComParadeActInfo
        change 1: ComParadeActInfo
        remove 2: ComParadeActInfo
    }
]]

activityParadeProto.c2s = activityParadeProto.struct .. [[
    reqActivityParameGameReward 7601 {
        request {
            actId 1: uint32      # 活动id
            gameId 2: uint32     # 小游戏id
        }
        response {
            ress 1: *ComRes
        }
    }
]]

activityParadeProto.s2c = activityParadeProto.struct .. [[

]]

return activityParadeProto