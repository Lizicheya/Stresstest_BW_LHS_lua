--联盟兑换 4301 ~ 4400
local allianceProto = {}

allianceProto.struct = [[


]]

allianceProto.c2s = allianceProto.struct .. [[
  
allianceResExchangeOne 4301 { #交换一个物品
    request {
        id 0: uint32                   # id(合成配置ID)
        count 1: uint32                # 合成数量
    }
    response {
        obtainResources 0: *ComRes      # 获得的资源
    }
}

allianceResExchangeMultiple 4302 { #交换多个物品
    request {
        exchanges 0 : *ComUint32Uint32()
    }
    response {
        obtainResources 0: *ComRes      # 获得的资源
    }
}

]]

allianceProto.s2c = allianceProto.struct .. [[


]]

return allianceProto