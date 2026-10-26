-- 末日宝藏手册 8681 ～ 8700
local activityContinuousStoredValueProto = {}
activityContinuousStoredValueProto.struct = [[
    .ContinuousStoredValueParam {
        groupId 1: integer
    }

    .ComContinuousStoredValue {
        actId 0 : integer # 活动 id
        param 1 : ContinuousStoredValueParam # 参数
        itemList 2: *ComIntInt()
        purchaseNum 3: integer # 今日已购买次数
    }
]]

activityContinuousStoredValueProto.c2s = activityContinuousStoredValueProto.struct .. [[
    reqContinuousStoredValueReward 8681 { # 领取奖励
        request {
            actId 0: uint32
            dayId 1: uint32
        }
        response {
            dayId 1: uint32
            ress 2: *ComRes
        }
    }
]]

activityContinuousStoredValueProto.s2c = activityContinuousStoredValueProto.struct .. [[
    
]]

return activityContinuousStoredValueProto