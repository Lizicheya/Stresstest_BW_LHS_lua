-- 雷达 3401~3500
local radarProto = {}

radarProto.struct = [[
    #雷达不同类型信息
    .ComRadarTypeBase {
        radarType 0: integer        # 雷达类型
        queueCounts 1: integer      # 队列个中的数

        progressClaimList 2: *ComIntInt() # 进度奖励领取列表
        finishCount 3: uint32             # 完成任务数量
    }

    .ComSyncRadarTypeBase {
        news 1: *ComRadarTypeBase(radarType)
        changes 2: *ComRadarTypeBase(radarType)
        removes 3: *integer
    }

    #雷达事件
    .ComRadarEvent {
        id 0: integer                   # id(雷达唯一id)
        eventId 1: integer              # 事件ID
        status 2:  integer              # 事件状态
        sceneObjId 3: integer           # 场景的实例ID
        posX       4 : integer          # 坐标X
        posY       5 : integer          # 坐标Y
        expireTime       6 : integer    # 超时时间
        power 7: integer                # 挑战怪拥有的战力
        allianceHelpUid 8 : integer     # 联盟帮助任务目标成员uid 
        rewardRess 9: *ComRes           # 奖励
    }

    #雷达基本数据
    .ComRadarBase {
        strengthLevel 0: integer                   # 实力等级
        refreshLevel 1: integer                    # 刷新等级
        refreshExp 2: integer                      # 刷新等级经验
        nextRefreshTime 3: integer                 # 下一次刷新时间
        lastRefreshTime 4: integer                 # 上一次刷新时间,=0表示未开启雷达功能

        nextDailyRefreshTime 5: integer            # 下次每日刷新时间戳（秒）
        gainDailyAttrEventFlag 6: boolean          # 每日属性雷达事件领取状态
    }

    .ComGetRadarRewardArg {
        id 0: integer                   # id(雷达唯一id)
        eventId 1: integer              # 事件ID
    }
]]

radarProto.c2s = radarProto.struct .. [[

upStrengthLevel 3401 { #升级实力等级
    request {
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getRadarReward 3402 { #获得雷达奖励
    request {
        id 0: uint32                   # id(雷达唯一id)
        eventId 1: uint32              # id(雷达事件ID)
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getMultiRadarReward 3403 { #获得多个雷达奖励
    request {
        events 0: *ComGetRadarRewardArg # 多个雷达奖励请求参数
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

refreshRadarAllianceHelpPos 3404 { # 更新联盟帮助对象主堡坐标
    request {
        id 0: uint32                   # id(雷达唯一id)
        eventId 1: uint32              # id(雷达事件ID)
    }
    response {
    }
}

gainDailyRadarEvent 3405 { # 领取每日免费雷达事件
    request {
    }
    response {
    }
}

gainRadarProgressReward 3406 {    # 领取雷达进度奖励
    request {
        radarType 0: uint32       # 雷达类型
    }
    response {
        ress 0: *ComRes           # 获得的资源
    }
}

]]

radarProto.s2c = radarProto.struct .. [[
notifyRadarRefreshLv 3451 {          # 雷达刷新等级提供给的奖励 
    request {
        refreshLevel 0: integer      # 刷新等级
        ress 1: *ComRes              # 获得的资源
    }
}

]]

return radarProto