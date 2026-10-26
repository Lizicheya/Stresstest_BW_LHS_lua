-- 钓鱼图鉴 8861 ~ 8890
local fishGuideProto = {}

fishGuideProto.struct = [[

    .ComFishType2GainList {
        fishType 0: uint32
        ganList 1: *ComIntInt()
    }

    .ComFishGuideBase {                     # 钓鱼图鉴系统的信息
        fishPoint 0: uint32                 # 垂钓积分
        fishPointGainList 1: *ComIntInt()   # 垂钓积分奖励领取状态

        fishType2GainList 2: *ComFishType2GainList(fishType) # 鱼大类下 不同鱼全图鉴奖励领取状态
    }

    .ComFishGuide {            # 一条鱼的图鉴信息
        id 0: uint32           # 鱼配置id
        awardFlag 1: uint32    # 鱼图鉴解锁奖励领取标记 =1 已领取
        createTime 2: integer  # 创建时间戳（秒），就是第一次钓到这种鱼的时间
    }

    .ComSyncFishGuide {
        news 1: *ComFishGuide(id)
        changes 2: *ComFishGuide(id)
        removes 3: *integer
    }
]]

fishGuideProto.c2s = fishGuideProto.struct .. [[
    reqFishGuideAward 8861 {   # 领取单条鱼图鉴解锁奖励
        request {
            id 0: uint32       # 鱼配置id
        }
        response {
            ress 0: *ComRes
        }
    }

    reqFishCuideFishPointAward 8862 { # 领取可领取的 垂钓积分奖励
        request {
            cfgId 0: uint32           # 要领取的奖励配置 id，传 0 领取全部奖励
        }
        response {
            ress 0: *ComRes
        }
    }

    reqFishCuideUnlockAward 8863 {  # 领取鱼图鉴的全收集奖励
        request {
            fishType 0: uint32      # 鱼的大类
            index 1: uint32         # 要领取奖励配置id
        }
        response {
            ress 0: *ComRes
        }
    }
]]

fishGuideProto.s2c = fishGuideProto.struct .. [[
]]

return fishGuideProto
