-- 连续签到活动 8921 ~ 8950
local activityConsecutiveSignInProto = {}

activityConsecutiveSignInProto.struct = [[
    .ComActConsecutiveSignInDaySelectSlot {
        slot 0: integer                  # 槽位
        cfgIndex 1: integer              # 配置索引
    }

    .ComActConsecutiveSignInDay {
        day 0: integer                  # 天数
        awardSignIn 1: boolean          # 是否签到（领取签到奖励）

        selectSlot 2: *ComActConsecutiveSignInDaySelectSlot(slot)
        awardSlot 3: boolean             # 是否已领取祈福奖励
    }

    .ComActConsecutiveSignIn {              # 连续签到活动信息
        actId 0: integer                    # 活动id
        round 1: integer                    # 轮次
        state 2: integer
        isOver 3: boolean
        groupId 4: integer
        startTimestamp 5: integer           # 活动开始时间戳（秒）

        signInDays 6: *ComActConsecutiveSignInDay(day)
    }

    .ComSyncActConsecutiveSignIn {
        news 0: *ComActConsecutiveSignIn(actId)
        changes 1: *ComActConsecutiveSignIn(actId)
        removes 2: *integer
    }
]]

activityConsecutiveSignInProto.c2s = activityConsecutiveSignInProto.struct .. [[
    reqActConsecutiveSignIn 8921 { # 签到
        request {
            actId 0: uint32        # 活动id
            day 1: uint32          # 天数，传过去的天数就是补签
        }
        response {
            ress 0: *ComRes        # 领取的奖励
        }
    }

    reqActConsecutiveSignInSlot 8922 {   # 获得祈福奖励
        request {
            actId 0: uint32              # 活动id
            day 1: uint32                # 天数
        }
        response {
            ress 0: *ComRes              # 领取的奖励
        }
    }

    selectActConsecutiveSignInSlot 8923 { # 选择祈福奖励
        request {
            actId 0: uint32               # 活动id
            day 1: uint32                 # 天数
            slot 2: *ComUint32Uint32()    # 槽位选择 => 配置索引
        }
        response {
        }
    }
]]

activityConsecutiveSignInProto.s2c = activityConsecutiveSignInProto.struct .. [[
]]

return activityConsecutiveSignInProto
