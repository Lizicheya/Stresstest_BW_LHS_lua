--招募 2901~3000
local recruitProto = {}

recruitProto.struct = [[

    .ComRecruitInfo {
        id 0: integer                       #招募ID
        nextDayFreeRecruitTimeSec 2: integer #下一次免费招募时间戳
        totalRecruitCount 4: integer        #总的招募次数
        dayResetTime 5: integer             #每天次数的重置时间
        guaranteeCount 6: integer           #保底进行的次数
        isOpen 7: boolean                   #招募是否开启
        expireTime 8: integer               #到期时间
        discount 9: integer                 #折扣
    }

    .ComSyncRecruitInfo {
        news 1: *ComRecruitInfo(id)
        changes 2: *ComRecruitInfo(id)
        removes 3: *integer
    }

    #招募组件
    .ComRecruitComp {
        activityId 0: integer               #活动ID
        recruitId 1: integer                #招募配置ID
        recruitDiscount 2: integer          #招募折扣
        scoreClaimData 4:                   ComActivityScoreClaimData #积分数据
    }
]]

recruitProto.c2s = recruitProto.struct..[[

recruitOne 2901 {                            #招募一次
    request {
        id 0: uint32                         #招募ID
        resExchanges 2: *ComUint32Uint32()   # 资源兑换(资源兑换配置id->兑换数量)
        bItem 3:boolean                      #是否使用道具
    }
    response {
        ress 0: *ComRes
        recruitInfo  1: ComRecruitInfo       # 招募信息
    }
}

recruitMultiple 2902 {                           #招募多次
    request {
        id 0: uint32                             #招募ID
        resExchanges 2: *ComUint32Uint32()       #资源兑换(资源兑换配置id->兑换数量)
        num 3: uint32                            #数量
    }
    response {
        ress 0: *ComRes                             
        recruitInfo  1: ComRecruitInfo       # 招募信息
    }
}

getRecruitBoxReward 2903 {                   #获取招募宝箱奖励
    request {
        num 0: uint32                        #数量
    }
    response {
        ress 0: *ComRes
    }
}

getRecruitConfig 2904 {                   #获取招募配置ID
    request {
    }
    response {
        id2CfgId 0: *ComRecruitInfo(id)   #招募配置ID
        boxCfgId 1: integer               #招募随机宝箱配置ID
    }
}

reqActivityRecruitScoreReward 2905 {
    request {
        actId 0: uint32                             #活动ID
        boxId 1: uint32                             #宝箱ID
    }

    response {
        ress 0: *ComRes
    }
}

]]

recruitProto.s2c = recruitProto.struct..[[

]]

return recruitProto