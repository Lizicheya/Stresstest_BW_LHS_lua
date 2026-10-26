-- 累计充值 6511 ～6520
local _M = {}

_M.struct =
    [[
    .AccumulateRechargeData {
        totalScore 0 : integer # 充值总积分
        todayAddScoreTime 1 : integer # 每天第一次获得积分的时间戳，重置积分时判断依据
        gotGradeRewards 2 : *integer # 已领取哪些档次的奖励
        boxRewardGetTime 3 : integer # 宝箱奖励领取时间
        boxRewardCount 4 : integer # 宝箱领取次数
    }

    .AccumulateRechargeParam {
        groupId 0 : integer # 活动配置组 Id
    }

    .AccumulateRechargeInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        param 3 : AccumulateRechargeParam # 参数
        data 4 : AccumulateRechargeData
    }
]]

_M.c2s =
    _M.struct ..
    [[

reqGetAccumulateRechargeReward 6511 { # 领取累充奖励
    request {
        actId 0 : uint32 # 活动 id
        grade 1 : uint32 # 哪一档奖励
    }
    response {
        dropRes 0 : *ComRes      # 领取的奖励
    }
}

reqGetAccumulateRechargeBoxReward 6512 { # 领取宝箱奖励
    request {
        actId 0 : uint32 # 活动 id
    }
    response {
        dropRes 0 : *ComRes      # 领取的奖励
    }
}

]]

_M.s2c = _M.struct .. [[

]]

return _M
