-- 首充奖励 6501 ~ 6510
local _M = {}

_M.struct = [[
    .PayFirstRewardInfo {
        firstPayTime 0 : integer                            #首充时间戳
        lastRewardTime 1 : integer                          #最近一次领奖时间
        rewardDays 2 : *integer                             #已领哪些天的奖励
        extraPayCount 3 : integer                           #额外充值次数
        finish 4 : boolean                                  #是否完成
    }
]]

_M.c2s = _M.struct..[[

reqPayFirstReward 6501 { # 领取首充奖励
    request {
        day 0 : uint32 # 领取第几天的奖励
    }
    response {
        dropRes 0 : *ComRes      # 领取的奖励
    }
}

]]

_M.s2c = _M.struct..[[

]]

return _M