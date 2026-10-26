--访问社区奖励  6931 ~ 6940
local communityProto = {}

communityProto.struct = [[
    .ComCommunity {
        accessTS 1: integer             # 上次访问社区时间戳
        firstReward 3: integer          # 首次奖励状态 0=无状态，1=可领奖，2=已领奖
        commonReward 4: integer         # 普通奖励状态 0=无状态，1=可领奖，2=已领奖
    }
]]

communityProto.c2s = communityProto.struct..[[
    reqMarkReward 6931 { # 访问标记
        request {
        }
        response {
        }
    }

    reqFirstReward 6932 { # 领取首次奖励
        request {
        }
        response {
            ress 0: *ComRes # 奖励
        }
    }

    reqCommonReward 6933 { # 领取普通奖励
        request {
        }
        response {
            ress 0: *ComRes # 奖励
        }
    }

]]

communityProto.s2c = communityProto.struct..[[
   
]]

return communityProto