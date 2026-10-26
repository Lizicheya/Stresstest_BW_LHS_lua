-- 飞刀活动 8751 ～ 8780
local activityDaggerThrowingProto = {}

activityDaggerThrowingProto.struct = [[
    .ComActDaggerThrowing {    # 飞刀活动信息
        actId 0: integer       # 活动id
        round 1: integer       # 轮次
        state 2: integer
        isOver 3: boolean
        groupId 4: integer

        level 10: integer                    # 层（轮）数
        count 11: integer                    # 本层（轮）已经抽奖的次数
        hisCount 12: integer                 # 历史抽奖次数
        specialReward 13: integer            # 本层（轮）抽奖,大奖的奖励，未抽出前都可以换
        specialRewardList 14: *ComIntInt()   # 大奖剩余可以抽出的次数，整个活动周期内不重置的
        ressStorage 15: *ComRes              # 存取来未领取的奖励
        ressHistory 16: *ComRes              # 已领取过的奖励
        commonRewardList 17: *ComIntInt()    # 还可以抽出的普通奖励配置 id set，每层（轮重置）,1 可以抽出，0 不行
        gainLevelRewardList 18: *ComIntInt() # 已领取的层数奖励
    }

    .ComSyncActDaggerThrowing {
        news 0: *ComActDaggerThrowing(actId)
        changes 1: *ComActDaggerThrowing(actId)
        removes 2: *integer
    }

    .ComDaggerThrowing2WinResult {
        specialReward 0: boolean # 本次抽奖抽出的是大奖奖励
        rewardList 1: *ComRes
    }
]]

activityDaggerThrowingProto.c2s = activityDaggerThrowingProto.struct .. [[
    selectSpecialReward 8751 {      # 选择飞刀活动大奖
        request {
            actId 0: uint32         # 活动id
            rewardId 1: uint32      # 大奖配置id
        }
        response {
        }
    }

    daggerThrowing 8752 {            # 飞刀抽奖一次
        request {
            actId 0: uint32          # 活动id
        }
        response {
            specialReward 0: boolean # 本次抽奖抽出的是大奖奖励
            dropRes 1: *ComRes       # 获得的奖励
        }
    }

    daggerThrowing2Win 8753 {        # 飞刀连续抽直到抽出大奖
        request {
            actId 0: uint32          # 活动id
            maxTimes 1: uint32       # 最多抽奖次数
        }
        response {
            list 0: *ComDaggerThrowing2WinResult
        }
    }

    receiveActDaggerThrowingReward 8754 { # 领取飞刀活动存起来的奖励
        request {
            actId 0: uint32          # 活动id
        }
        response {
            rewardList 0: *ComRes
        }
    }

    gainActDaggerThrowingLevelReward 8755 { # 领取飞刀活动通过层数奖励
        request {
            actId 0: uint32          # 活动id
            cfgId 1: uint32          # 奖励的配置id
        }
        response {
            rewardList 0: *ComRes
        }
    }
]]

activityDaggerThrowingProto.s2c = activityDaggerThrowingProto.struct .. [[
]]

return activityDaggerThrowingProto
