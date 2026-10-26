-- 通行证活动 6801 ~ 6850
local activityPassProto = {}

activityPassProto.struct = [[
    .ComActivityPassList {
        passType 0: integer    # 通行证类型
        gotRewardList 1: *ComIntInt() # key=等级，value=activityPassRewardType
        bUnlock 2: boolean # 是否已解锁
        groupId 3: integer # 奖励组 id，非0说明是要该子通行证，要用自己的奖励组
    }

    .ComActivityPassTaskRewardStatus { # 通行证奖励领取状态
        id 0: integer # 任务id
        base 1: integer # 基础的
        extra 2: integer # 高级的
    }

    .ComActivityPassData {
        passList 0: *ComActivityPassList(passType) # 通行证列表
        passScore 1: integer # 积分
        passLevel 2: integer # 等级
        taskRewardList 3 : *ComActivityPassTaskRewardStatus(id) # 任务奖励领取状态列表
        gainExtraRewardCount 4: integer # 满级后领取额外积分奖励次数
    }

    .ComActivityPassParam {
        configId 0: integer # 活动配置Id
    }

    .ComActivityPassInfo {
        actId 0: integer # 活动 id
        round 1: integer # 轮次
        state 2: integer # 状态
        param 3: ComActivityPassParam # 参数
        data 4: ComActivityPassData
    }
]]

activityPassProto.c2s = activityPassProto.struct .. [[
    reqExchangeScore 6801 { # 兑换积分
        request {
            actId 0: uint32 # 活动id
            exchangeCount 1: uint32 # 兑换几个
        }
        response {
        }
    }
    
    reqClaimPassLevelReward 6802 { # 一键领取通行证奖励
        request {
            actId 0: uint32 # 活动id
            level 1: uint32 # 领取哪个等级的奖励, 0 代表一键领取
        }
        response {
            ress 0: *ComRes     # 获得的资源
        }
    }

    reqClaimPassTaskReward 6803 { # 请求领取通行证任务奖励
        request {
            actId 0: uint32 # 活动id
            taskId 1: uint32 # 任务id
        }
        response {
            ress 0: *ComRes     # 获得的资源
        }
    }
    
    reqBuyLv 6804 { # 购买等级
        request {
            actId 0: uint32 # 活动id
            buyLv 1: uint32 # 购买的等级
        }
        response {
        }
    }

    gainPassExtraScoreAward 6805 {    # 领取额外积分奖励
        request {
            actId 0: uint32           # 活动id
        }
        response {
            ress 0: *ComRes           # 获得的资源
        }
    }
]]

activityPassProto.s2c = activityPassProto.struct .. [[

]]

return activityPassProto