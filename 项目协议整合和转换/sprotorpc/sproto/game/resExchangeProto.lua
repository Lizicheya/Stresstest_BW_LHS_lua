-- 合成模块 2801~2900
local resExchange = {}

resExchange.struct = [[
    .ComCompose {
        id 0: integer
        count 1: integer
    }
]]

resExchange.c2s = resExchange.struct..[[

resExchangeOne 2801 { #交换一个物品
    request {
        id 0: uint32                   # id(合成配置ID)
        count 1: uint32                # 合成数量
    }
    response {
        obtainResources 0: *ComRes      # 获得的资源
    }
}

resExchangeMultiple 2802 { #交换多个物品
    request {
        exchanges 0 : *ComUint32Uint32()
    }
    response {
        obtainResources 0: *ComRes      # 获得的资源
    }
}

resExchangeMultipleAndUse 2803 { #交换多个物品并且使用
    request {
        exchanges 0 : *ComUint32Uint32()
        params 1: ComUseItemParams      # 使用参数
    }
    response {
        obtainResources 0: *ComRes      # 获得的资源
    }
}

]]

resExchange.s2c = resExchange.struct..[[

]]

return resExchange