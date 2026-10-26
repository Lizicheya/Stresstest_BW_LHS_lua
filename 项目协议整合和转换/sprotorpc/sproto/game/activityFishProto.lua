-- 钓鱼活动 8891 ~ 8920
local activityFishProto = {}

activityFishProto.struct = [[

    .ComActFishCacheDepthListItem {  # 每个深度配置的鱼的信息
        id 0: uint32                 # 在 activityFishingRefresh 配置表中的 id
        fishCfgIdList 1: *uint32     # 刷出来的鱼的配置id列表
    }

    .ComActFishCache {               # 待钓的鱼的信息
        pondType 0: uint32           # 钓鱼类型 1=普通钓饵 2=特质钓饵
        depthList 1: *ComActFishCacheDepthListItem(id)

        searchLight 2: boolean       # 使用探照灯
        swimBladder 3: boolean       # 使用感应鱼鳔
        fishHook 4: boolean          # 使用特质鱼钩
        fishDetector 5: boolean      # 使用水下探测器
        fishCfgId 6: uint32          # 使用水下探测器选择的鱼
    }

    .ComFishGear {               # 渔具
        fishGearType 0: uint32   # 渔具类型
        lv 1: uint32
    }

    .ComActFish {              # 活动信息
        actId 0: integer       # 活动id
        round 1: integer       # 轮次
        state 2: integer
        isOver 3: boolean
        groupId 4: integer

        fishGear 5: *ComFishGear(fishGearType)
        fishCache 6: ComActFishCache
        cached 7: boolean         # 是否有钓鱼缓存

        fishCoin 8: uint32        # 钓鱼币
        rankPoint 9: uint32       # 排行榜积分
        fishCommonBait 10: uint32 # 普通鱼饵
        achieveDepth 11: uint32   # 达到的深度
    }

    .ComSyncActFish {
        news 0: *ComActFish(actId)
        changes 1: *ComActFish(actId)
        removes 2: *integer
    }

    .ComActFishBase {                      # 钓鱼活动基本信息
        nextRestoreBaitTime 0: integer     # 下一次恢复鱼饵时间戳（秒）
        lastRestoreBaitTime 1: integer     # 上一次恢复鱼饵时间戳（秒）
    }
]]

activityFishProto.c2s = activityFishProto.struct .. [[
    reqFishing 8891 {                 # 请求钓鱼
        request {
            actId 0: uint32           # 活动id
            pondType 1: uint32        # 钓鱼类型 1=普通钓饵 2=特质钓饵
            searchLight 2: boolean    # 使用探照灯
            swimBladder 3: boolean    # 使用感应鱼鳔
            fishHook 4: boolean       # 使用特质鱼钩
            fishDetector 5: boolean   # 使用水下探测器
            fishCfgId 6: uint32       # 使用水下探测器选择的鱼
        }
        response {
            fishCache 0: ComActFishCache
        }
    }

    fishingResult 8892 {                # 钓鱼结果
        request {
            actId 0: uint32             # 活动id
            fish 1: *ComUint32Uint32()  # 钓到的鱼 fishCfgId => num
            mulit 2: uint32             # 额外多倍奖励
            achieveDepth 3: uint32      # 达到的深度
        }
        response {
        }
    }
    
    fishGearUpLv 8893 {                 # 渔具升级
        request {
            actId 0: uint32             # 活动id
            fishGearType 1: uint32      # 渔具类型
        }
        response {
        }
    }

    retFishTaskReward 8894 {            # 领取钓鱼任务奖励
        request {
            actId 0: uint32             # 活动 id
            taskId 1: uint32            # 任务 id
        }
        response {
            ress 0: *ComRes
        }
    }
]]

activityFishProto.s2c = activityFishProto.struct .. [[
]]

return activityFishProto
