-- 特权卡 6601 ～6300
local privilegeCardProto = {}

privilegeCardProto.struct = [[
    .ComPrivilegeCard {
        cfgId 0: integer                        # 配置id
        bActive 1: boolean                      # 是否激活状态
        endTime 2: integer                      # 激活结束时间
        lastRewardTime 3: integer               # 上次发送奖励时间（手动领奖、过天自动发奖都会更新本时间）
        continueDay 4:  integer                 # 已经连续领取的天数（根据这个判断奖池）
        activeTime 5: integer                   # 本卡激活时间
        payGiftCount 6 : integer                # 本特权卡已经通过礼包激活次数（根据这个判断下次礼包激活是获得什么奖励）
        unClaimRechargeReward 7: *integer       # 未领取的礼包激活特权卡奖励列表（奖池id列表）
    }
]]

privilegeCardProto.c2s = privilegeCardProto.struct..[[

reqPrivilegeCardReward 6601 { # 优先判断privilegeCardType字段，privilegeCardType字段存在默认一键领取
    request {
        privilegeCardCfgId 0: uint32   # 特权卡id
        privilegeCardType 1: uint32   # 特权卡类型
    }
    response {
        dropRes 0: *ComRes      # 本次奖励
    }
}

]]

privilegeCardProto.s2c = privilegeCardProto.struct..[[


]]

return privilegeCardProto