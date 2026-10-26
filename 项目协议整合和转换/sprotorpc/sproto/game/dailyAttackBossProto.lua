-- 每日打boss 8301 ~ 8330
local dailyAttackBossProto = {}

dailyAttackBossProto.struct = [[
    .ComDailyAttackBossBase {
        daySpecialAwardFlag 0: boolean # 每日特殊奖励领取标记
        lastDayResetTime 1: uint32 # 上次每日重置时间 秒
    }
]]

dailyAttackBossProto.c2s = dailyAttackBossProto.struct .. [[
getDailyAttackBossAward 8301 { # 获取每日打boss任务奖励
    request {
        taskId 0: uint32
    }
    response {
        ress 0: *ComRes
    }
}

getDailyAttackBossAwardAll 8302 { # 一键领取每日打boss任务奖励
    request {
    }
    response {
        ress 0: *ComRes
    }
}

getDailyAttackBossSpecialAward 8303 { # 获取每日打boss特殊奖励
    request {
    }
    response {
        ress 0: *ComRes
    }
}

]]

dailyAttackBossProto.s2c = dailyAttackBossProto.struct .. [[

]]

return dailyAttackBossProto
