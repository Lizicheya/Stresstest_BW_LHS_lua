-- 系统解锁模块 2701~2800
local systemOpenProto = {}

systemOpenProto.struct = [[
]]

systemOpenProto.c2s = systemOpenProto.struct..[[

    awardSystem 2701 { #领取系统奖励
        request {
            systemType 0: uint32           # 系统类型(PlayerSystemType)
        }
        response {
            ress 0: *ComRes                 # 获得的资源
        }
    }

]]

systemOpenProto.s2c = systemOpenProto.struct..[[
    systemOpenNotice 2701 { #系统开启客户端表现用
        request {
            id 0: integer            # id(系统ID)
        }
        response {
        }
    }
]]

return systemOpenProto