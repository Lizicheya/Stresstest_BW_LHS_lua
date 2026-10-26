--
-- author: TQING<tqing1128@gmail.com>
-- date: 2024-03-08 09:18:42
--

local activityGiftProto = {}

activityGiftProto.struct = [[    
]]

activityGiftProto.c2s = activityGiftProto.struct .. [[
    claimActivityGiftFreeReward 6881 { # 请求免费宝箱奖励
        request {
            actId 0 : uint32 # 活动 id
        }
        response {
        }
    }
]]

activityGiftProto.s2c = activityGiftProto.struct .. [[

]]

return activityGiftProto