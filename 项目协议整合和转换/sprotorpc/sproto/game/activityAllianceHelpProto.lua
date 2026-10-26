-- 联盟帮助活动 9211 ～ 9240
local activityAllianceHelpProto = {}

activityAllianceHelpProto.struct = [[
    .ComActivityAllianceHelp {
        state 0: integer # 活动状态 0:未开始 1:进行中 2:已结束
        startTimestamp 1: integer # 活动开始时间戳
        endTimestamp 2: integer # 活动结束时间戳
        over 3: boolean # 活动是否结束
        stageList 4: *ComIntBool() # 已领取奖励列表
        totalTime 5: integer # 总帮助时长（秒）
    }
]]

activityAllianceHelpProto.c2s = activityAllianceHelpProto.struct .. [[
    activityAllianceHelpGetStageReward 9211 { # 领取档位奖励
        request {
            stageId 1: uint32
        }
        response {
            ress 1: *ComRes
        }
    }
]]

activityAllianceHelpProto.s2c = activityAllianceHelpProto.struct .. [[
]]

return activityAllianceHelpProto
