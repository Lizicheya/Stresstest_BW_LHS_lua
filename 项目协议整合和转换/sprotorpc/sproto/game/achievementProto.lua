-- 成就模块 4401~4500
local achievementProto = {}

achievementProto.struct = [[
]]

achievementProto.c2s = achievementProto.struct..[[

awardAchievementBox 4401 { #领取成就宝箱奖励
    request {
        boxId 1: uint32     #宝箱ID
    }
    response {
        ress 0: *ComRes     # 获得的资源
    }
}

setAchievementBadges 4402 { #设置成就徽章展示
    request {
       list 0: *uint32     #成就展示列表
    }
    response {
    }
}


]]

achievementProto.s2c = achievementProto.struct..[[

]]

return achievementProto