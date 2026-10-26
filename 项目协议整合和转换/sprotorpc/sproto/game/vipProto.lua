--vip 4601 ~ 4700
local vipProto = {}

vipProto.struct = [[

]]

vipProto.c2s = vipProto.struct..[[

reqVipDayGift 4601 { # 领取vip每日礼物
    request {
       
    }
    response {
        dayGiftTS 0: integer    # 每日礼物领取时间更新
        dropRes 1: *ComRes      # 本次奖励
    }
}

reqVipDayExp 4603 { # 领取vip每日经验
    request {
    }
    response {
        dayVipExpTS 0: integer  # 每日经验领取时间更新
        exp 1: uint32           # 本次获得的 exp
    }
}

]]

vipProto.s2c = vipProto.struct..[[

syncVipActive 4602 { # 同步激活状态
    request {
        bActive 0: boolean  # boolean
    }
    response {
    }
}

]]

return vipProto