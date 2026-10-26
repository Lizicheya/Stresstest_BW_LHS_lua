-- 钓鱼联盟宴会活动 8951 ~ 8980
local activityFishAllianceRewardProto = {}

activityFishAllianceRewardProto.struct = [[
    .ComActFishAllianceRewardParam {
        rankCfgId 0: integer # 排行榜配置id
        groupId 1: integer # 宴会组id
    }

    .ComActFishAllianceRewardAllianceReward {
        aid 0: integer # 联盟id
        rank 1: integer # 排行榜排名
        flag 2: boolean # 是否已经领取排行榜奖励（创建联盟建筑）标记

        flagOpen 3: boolean # 宴会已经开启标志
        openTime 4: integer # 预约开启时间戳
    }

    .ComActFishAllianceReward {
        actId 0: integer
        round 1: integer
        state 2: integer
        isOver 3: boolean
        actOverTimestamp 4: integer
        param 5: ComActFishAllianceRewardParam

        allianceReward 6: *ComActFishAllianceRewardAllianceReward(aid)
    }

    .ComSyncActFishAllianceReward {
        news 0: *ComActFishAllianceReward(actId)
        changes 1: *ComActFishAllianceReward(actId)
        removes 2: *integer
    }

    .ComActFishAllianceRewardAllianceGiftTableLog { # 加餐记录
        id 0: integer
        uid 1: integer
        buildCfgId 2: integer  # 餐桌配置id
        time 3: integer        # 时间戳（秒）
        buildId 4: integer     # 联盟餐桌建筑动态id


        nickName 10: string       # 玩家昵称
        headId 11: integer        # 头像
        headFrameId 12: integer   # 头像框
        customHead 13: string     # 自定义头像
    }

    .ComActFishAllianceRewardAllianceTableGiftLog { # 餐桌就餐记录
        uid 0: integer
        ress 1: *ComRes       # 获得的资源
        createTime 2: integer # 创建时间戳（秒）

        nickName 10: string       # 玩家昵称
        headId 11: integer        # 头像
        headFrameId 12: integer   # 头像框
        customHead 13: string     # 自定义头像
    }

    .ComActFishAllianceRewardAllianceUserGiftLog { # 玩家就餐记录
        buildCfgId 0: integer # 餐桌建筑配置id
        ress 1: *ComRes
        createTime 2: integer # 创建时间戳（秒）
        fromUid 3: integer    # 玩家uid，如果是玩家购买礼包刷的才有

        nickName 10: string       # 玩家昵称
        headId 11: integer        # 头像
        headFrameId 12: integer   # 头像框
        customHead 13: string     # 自定义头像
    }
]]

activityFishAllianceRewardProto.c2s = activityFishAllianceRewardProto.struct .. [[
    reqActFishAllianceReward 8951 {     # 请求活动钓鱼联盟宴会排行榜奖励
        request {
            actId 0: uint32             # 活动id
        }
        response {
        }
    }
    
    reqOpenActFishAlliance 8952 {       # （预约）开启宴会
        request {
            actId 0: uint32             # 活动id
            openTime 1: uint32          # 开启时间戳（秒），传 0 就是马上开启
        }
        response {
        }
    }

    reqGiftTableLog 8953 {              # 请求加餐记录
        request {
            actId 0: uint32             # 活动id
        }
        response {
            list 0: *ComActFishAllianceRewardAllianceGiftTableLog(id)
        }
    }

    reqGainTableGiftLog 8954 {          # 请求餐桌就餐记录
        request {
            actId 0: uint32             # 活动id
            buildId 1: integer          # 餐桌id，ComSceneAllianceFishTable 里的 id
        }
        response {
            list 0: *ComActFishAllianceRewardAllianceTableGiftLog(uid)
            fromUid 1: integer          # 玩家uid，如果是玩家购买礼包刷的才有
            createTime 2: integer       # 创建时间戳（秒）

            nickName 10: string       # 玩家昵称
            headId 11: integer        # 头像
            headFrameId 12: integer   # 头像框
            customHead 13: string     # 自定义头像
        }
    }

    reqUserGainGiftLog 8955 {          # 请求玩家就餐记录
        request {
            actId 0: uint32            # 活动id
        }
        response {
            list 0: *ComActFishAllianceRewardAllianceUserGiftLog
        }
    }
]]

activityFishAllianceRewardProto.s2c = activityFishAllianceRewardProto.struct .. [[
]]

return activityFishAllianceRewardProto
