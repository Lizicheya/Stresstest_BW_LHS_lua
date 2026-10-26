--士兵模块 1001~1100
local armyProto = {}

armyProto.struct = [[
    .ComPendingArmy {
        armyCfgId 1: integer                                        # 士兵配置id
        num 2: integer                                              # 士兵数量
        armyType 3: integer                                         # 士兵类型
    }
]]

armyProto.c2s = armyProto.struct..[[

trainArmy 1001 { # 训练
    request {
        armyCfgId 0: uint32                                        # 配置表id
        num 1: uint32                                              # 数量
        trainItemCfgId 2: uint32                                   # 使用的爆兵道具配置id
        trainExchangeCfgId 3: uint32                               # 兑换爆兵兑换表配置id
        immediately 4: boolean                                      # 是否立即完成
        resExchanges 5: *ComUint32Uint32()                          # 资源兑换(资源兑换配置id->兑换数量)
        items2use 6: *ComUint32Uint32()                             # 使用的道具(道具id->使用数量)
        optionalItems2use 7: *ComOptionalItem2use                   # 自选道具
    }
    response {
        id2num 0: *ComIntInt()                                      # 立即训练得到到的训练士兵配置id->数量
    }
}

collectArmy 1002 { # 收集
    request {
        armyType 0: uint32                                         # 士兵类型
    }
    response {
        id2num 0: *ComIntInt()                                      # 收集到的训练士兵配置id->数量
    }
}

reduceArmy 1003 { # 减员
    request {
        armyCfgId 0: uint32                                        # 配置表id
        num 1: uint32                                              # 数量
    }
    response {
    }
}

upgradeArmy 1004 { # 升级
    request {
        oldArmyCfgId 0: uint32                                     # 升级前配置表id
        armyCfgId 1: uint32                                        # 升级后配置表id
        num 2: uint32                                              # 数量
        immediately 3: boolean                                      # 是否立即完成
        resExchanges 4: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 5: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 6: *ComOptionalItem2use                   # 自选道具
    }
    response {
        id2num 0: *ComIntInt()                                      # 立即训练得到到的训练士兵配置id->数量
    }
}

healWoundedArmy 1005 { # 治疗伤兵
    request {
        id2num 0: *ComUint32Uint32()                                      # 要治疗的伤兵配置id->数量
        immediately 1: boolean                                      # 是否立即完成
        resExchanges 2: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 3: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 4: *ComOptionalItem2use                   # 自选道具
    }
    response {
        id2num 0: *ComIntInt()                                      # 立即训练得到到的训练士兵配置id->数量
    }
}

reduceWoundedArmy 1006 { # 遣散伤兵
    request {
        id2num 0: *ComUint32Uint32()                                      # 要遣散的伤兵配置id->数量
    }
    response {
    }
}

collectHealArmy 1007 { # 收集治疗士兵
    request {
    }
    response {
        id2num 0: *ComIntInt()                                      # 收集到的治疗伤兵配置id->数量
    }
}

resurrectDeadArmy 1008 { # 复活死亡士兵
    request {
        id2num 0: *ComUint32Uint32()                                # 要复活的死亡士兵配置id->数量
        immediately 1: boolean                                      # 是否立即完成
        resExchanges 2: *ComUint32Uint32()                          # 资源兑换(资源兑换配置id->兑换数量)
        items2use 3: *ComUint32Uint32()                             # 使用的道具(道具id->使用数量)
        optionalItems2use 4: *ComOptionalItem2use                   # 自选道具
    }
    response {
        id2num 0: *ComIntInt()                                      # 立即训练得到的训练士兵配置id->数量
    }
}

reduceDeadArmy 1009 { # 遣散死亡士兵
    request {
        id2num 0: *ComUint32Uint32()                                # 要遣散的死亡士兵配置id->数量
    }
    response {
    }
}

collectResurrectDeadArmy 1010 { # 收集复活士兵
    request {
    }
    response {
        id2num 0: *ComIntInt()                                      # 收集到的复活士兵配置id->数量
    }
}

]]

armyProto.s2c = armyProto.struct..[[

]]

return armyProto