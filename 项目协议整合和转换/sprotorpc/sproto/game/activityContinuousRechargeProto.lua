-- 连续充值 6521 ～6530
local _M = {}

_M.struct = [[
    .ContinuousRechargeData {
        actDay 0 : integer # 当前激活第几天
        totalScoreDayList 1 : *integer # -- key=天，value=充值总积分
        todayAddScoreTime 2 : integer # 每天第一次获得积分的时间戳，重置积分时判断依据
        boxRewardGetTime 3 : integer # 宝箱奖励领取时间
        boxRewardCount 4 : integer # 宝箱领取次数
        rechargePlan 5 : integer # 充值宝箱奖励进度
        isGotPlanReward 6 : boolean # 宝箱进度奖励是否已领取
    }

    .ContinuousRechargeParam {
        groupId 0 : integer # 活动配置组 Id
    }

    .ContinuousRechargeInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        param 3 : ContinuousRechargeParam # 参数
        data 4 : ContinuousRechargeData
    }
]]

_M.c2s = _M.struct..[[

reqGetContinuousRechargePlanReward 6521 { # 领取宝箱进度奖励
    request {
        actId 0 : uint32 # 活动 id
    }
    response {
        dropRes 0 : *ComRes      # 领取的奖励
    }
}

reqGetContinuousRechargeBoxReward 6522 { # 领取宝箱奖励
    request {
        actId 0 : uint32 # 活动 id
    }
    response {
        dropRes 0 : *ComRes      # 领取的奖励
    }
}

]]

_M.s2c = _M.struct..[[

]]

return _M