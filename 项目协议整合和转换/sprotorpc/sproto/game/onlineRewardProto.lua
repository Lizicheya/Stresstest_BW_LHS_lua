-- 在线奖励 7211 ~ 7220
local onlineRewardProto = {}

onlineRewardProto.struct = [[
    .ComOnlineRewardData {
        unlockGroup 0: integer    # 当前解锁的最高分组
        curReward 1: integer # 当前在第几级奖励
        nextRewardTime 2: integer # 可领奖时间戳
    }
]]

onlineRewardProto.c2s = onlineRewardProto.struct..[[

getOnlineReward 7211 { # 领取在线奖励
    request {
       
    }
    response {
        ress 1: *ComRes      # 本次奖励
    }
}

]]

onlineRewardProto.s2c = onlineRewardProto.struct..[[

]]

return onlineRewardProto