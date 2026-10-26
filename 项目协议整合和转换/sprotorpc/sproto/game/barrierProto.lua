--
-- author: TQING<tqing1128@gmail.com>
-- date: 2023-07-03 10:37:49
--

local barrierProto = {}

barrierProto.struct = [[
    .ComBarrierData {
        id 0 : integer                                      # 副本 ID
        pass 1 : boolean                                    # 是否通过主线
        claimedEventsChests 2 : *integer                    # 已领取事件宝箱
    }

    .ComBarrierModuleData {
        challengedCount 0 : integer                         # 已挑战次数
        currentOpenBarrier 1 : integer                      # 当前开启的副本
        latestCompletedBarrier 2 : integer                  # 最新的完成的副本
        claimedProgressChests 3 : *integer                  # 已领取进度宝箱
        barrierData 4 : *ComBarrierData(id)                 # 副本数据
    }
]]

barrierProto.c2s = barrierProto.struct .. [[
    challengeBarrier 3301 {                                 # 挑战副本
        request {
            barrierID 0 : uint32                           # 副本 ID
        }
        response {
        }
    }

    settleBarrier 3302 {                                    # 结算副本
        request {
            barrierID 0 : uint32                           # 副本 ID
            pass 1 : boolean                                # 是否通过主线
        }
        response {
            reward 0 : *ComRes                              # 奖励，只有首次通关才有
        }
    }

    claimBarrierEventChest 3303 {                          # 领取副本事件宝箱
        request {
            barrierID 0 : uint32                           # 副本 ID
            chestID 1 : uint32                             # 宝箱 ID
        }
        response {
            reward 0 : *ComRes                              # 奖励
        }
    }

    claimBarrierProgressChest 3304 {                       # 领取副本进度宝箱
        request {
            chestID 0 : uint32                            # 进度宝箱 ID
        }
        response {
            reward 0 : *ComRes                              # 奖励
        }
    }
]]

barrierProto.s2c = barrierProto.struct .. [[
]]

return barrierProto