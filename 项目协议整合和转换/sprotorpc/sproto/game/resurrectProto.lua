-- 复活-募兵营 7401 ~ 7425
local resurrectProto = {}

resurrectProto.struct = [[
    #复活信息
    .ComResurrectInfo {
        loyaltyTs 0: integer      #忠诚度结算时间
        loyaltySpeed 1: integer   #忠诚度恢复速度/3600
        loyaltySpeedMax 2: integer   #忠诚度恢复速度max/3600
        freeArmyCd 3: integer     #免费士兵领取cd
    }
 ]]

resurrectProto.c2s = resurrectProto.struct .. [[

 getFreeResurrectArmy 7401 { #领取免费复活士兵
    request {
    }
    response {
        ress 0: *ComRes
    }
 }

  getPaidResurrectArmy 7402 { #领取付费复活士兵
    request {
        army 0: *ComArmyIdAndNum()           # 士兵
        items2use 1: *ComUint32Uint32()            # 使用的道具(道具id->使用数量)
    }
    response {
        ress 0: *ComRes
    }
 }

]]

resurrectProto.s2c = resurrectProto.struct .. [[

]]

return resurrectProto
