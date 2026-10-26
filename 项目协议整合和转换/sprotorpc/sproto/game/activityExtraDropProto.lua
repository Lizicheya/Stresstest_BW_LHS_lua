-- 活动 掉落活动 6101 ~ 6200
local activityExtraDropProto = {}

activityExtraDropProto.struct = [[
    .activityExtraDropParams {
        group 1: integer     # 对应配置表id(extraDrop-group)
    }

    .activityExtraDrop {
        round 0: integer                            # 轮次
        actId 1: integer                            # 活动id
        params 2: activityExtraDropParams           # 活动配置
    }

    .ComSyncActivityExtraDrop {
        news 0: *activityExtraDrop(actId)
        removes 3: *integer
    }
    
]]

activityExtraDropProto.c2s = activityExtraDropProto.struct .. [[

]]

activityExtraDropProto.s2c = activityExtraDropProto.struct .. [[

]]

return activityExtraDropProto