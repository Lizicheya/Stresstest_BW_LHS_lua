-- 拼图活动 8721 ～ 8750
local activityPuzzleProto = {}

activityPuzzleProto.struct = [[
    .ComActPuzzleStat { # 拼图活动统计信息
        statCfgId 0: integer
        count 1: integer
    }

    .ComActPuzzle {        # 拼图活动信息
        actId 0: integer   # 活动id
        round 1: integer   # 轮次
        state 2: integer
        isOver 3: boolean
        groupId 4: integer

        gainList 5: *ComIntInt()
        statGainList 6: *ComIntInt()
        stat 7: *ComActPuzzleStat(statCfgId)
    }

    .ComSyncActPuzzle {
        news 0: *ComActPuzzle(actId)
        changes 1: *ComActPuzzle(actId)
        removes 2: *integer
    }
]]

activityPuzzleProto.c2s = activityPuzzleProto.struct .. [[
    reqActivityPuzzleReward 8721 {  # 请求领取拼图活动奖励
        request {
            actId 0: uint32         # 活动id
            id 1: uint32            # 配置表id
        }
        response {
            dropRes 0: *ComRes      # 获得的奖励
        }
    }

    reqActivityPuzzleStatReward 8722 {  # 请求领取拼图活动统计奖励
        request {
            actId 0: uint32             # 活动id
            id 1: uint32                # 配置表id
        }
        response {
            dropRes 0: *ComRes          # 获得的奖励
        }
    }
]]

activityPuzzleProto.s2c = activityPuzzleProto.struct .. [[
]]

return activityPuzzleProto
