-- 内城模块 1500~1600
local technologyProto = {}

technologyProto.struct = [[
    .ComTechnology {
        id 0: integer                   # id(科技唯一id-配置ID)
        status 1: integer               # 状态
        lv 2:integer                    # 等级
    }
]]

technologyProto.c2s = technologyProto.struct..[[

upgradeTechnology 1501 { #升级
    request {
        id 0: uint32                   # 科技唯一id
        immediately 5: boolean                                      # 是否立即完成
        resExchanges 6: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 7: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 8: *ComOptionalItem2use                   # 自选道具
        queueCfgId 9: uint32                                       # 指定的队列配置ID
    }
    response {
    }
}

]]

technologyProto.s2c = technologyProto.struct..[[

]]

return technologyProto