--英雄装备 3101~3200
local equipProto = {}

equipProto.struct = [[
    .ComCostItem {
        itemCfgId 0: uint32   #消耗的物品配置ID
        num 1: uint32 #消耗物品的数量
    }

    .ComCostEquip {
        id 0: uint32   #消耗的装备唯一ID(物品唯一ID)
        num 1: uint32  # 堆叠多个需要传数量，否则默认1
    }
    
    .ComEquipData {
        equipResetCount 0: uint32
        lastRefreshTS 2: uint32
    }
]]

equipProto.c2s = equipProto.struct..[[

equipLvUp 3101 { #装备等级提升
    request {
        id 0: uint32   #装备ID
        costItems 1: *ComCostItem
        costEquips 2: *ComCostEquip
    }
    response {
    }
}

equipRankLvUp 3102 { #装备等阶提升
    request {
        id 0: uint32   #装备ID
        costItems 1: *ComCostItem
        costEquips 2: *ComCostEquip
    }
    response {
    }
}

equipReset 3103 { #装备重置
    request {
        id 0: uint32   #装备ID
    }
    response {
        returnAssets 0: *ComRes
    }
}

equipWear 3104 { #穿装备
    request {
        id 0: uint32   #装备ID
        heroId 1: uint32 #英雄ID
    }
    response {
    }
}

equipTakeOff 3105 { #脱装备
    request {
        id 0: uint32   #装备ID
    }
    response {
    }
}

equipUnlock 3106 { #装备解锁
    request {
        id 0: uint32   #装备ID
        unlock 1: boolean
    }
    response {
    }
}

equipWearMultiple 3107 { #装备穿戴多个
    request {
        equips 0: *uint32  #每个位置对应的装备ID
        heroId 1: uint32   #英雄ID
    }
    response {
    }
}

equipTakeOffAll 3108 { #脱所有装备
    request {
        heroId 0: uint32 #英雄ID
    }
    response {
    }
}

equipResetLv 3109 { #装备重置等级
    request {
        id 0: uint32   #装备ID
    }
    response {
        returnAssets 0: *ComRes
    }
}

equipResetRankLv 3110 { #装备重置阶级
    request {
        id 0: uint32   #装备ID
    }
    response {
        returnAssets 0: *ComRes
    }
}

equipDecompose 3111 {  #装备分解
    request {
        id2num 0: *ComUint32Uint32() # 分解数量(装备唯一ID->分解数量)
    }
    response {
        returnAssets 0: *ComRes
    }
}
]]

equipProto.s2c = equipProto.struct..[[

]]

return equipProto