-- 物品模块 201~300
local itemProto = {}

itemProto.struct = [[
    .ComResProtectInfo {
        itemCfgId 1: integer                                    # 资源配置表id
        numProtect 2: integer                                   # 额外保护数量
    }

    .ComEquip {
        lv 1: integer                                           #装备等级
        rankLv 2: integer                                       #装备阶数
        lvExp 3: integer                                        #装备等级经验
        rankLvExp 4: integer                                    #装备等阶经验
        attrs 5: *ComIntInt()                                   #加成属性
        skills 6 : *integer                                     #技能ID
        power 7: integer                                        #战斗力
        bLock 8: boolean                                        #是否锁住
    }
    
    .ComTalentCard {
        lv 1: integer                                           # 天赋卡牌等级
        lvExp 2: integer                                        # 当前经验
        attrSourceIds 3: *integer                               # 加成源id列表
        talentSkillId 4: integer                                # 卡牌技能id
    }
    
    .ComItem {
        id 0: integer                                           # id(每个玩家的物品id唯一)
        itemCfgId 1: integer                                    # 配置表id
        num 2: integer                                          # 数量
        expired 3: integer                                      # 过期时间戳
        equip 4: ComEquip                                       # 装备私有数据
        slot 5: integer                                         # 插槽
        talentCard 6: ComTalentCard                             # 天赋卡牌
    }
    
    #客户端协议使用部分需要使用uint32
    .ComOptionalChestParams {                                   # 自选宝箱参数
        index 0: uint32                                         # 选取掉落的位置ID
    }
    
    .ComSpeedUpQueueParams {
        queueCfgId 0: uint32                                    # 队列配置表id
    }
    
    .ComOptionalAssetsParams {
        index 0: uint32                                         # 资产序号
    }
    
    .ComHeroExpParam {
        heroCfgId 0: uint32                                     # 英雄配置ID
    }
    
    .ComUseItemParams {
        optionalChestParams 0: ComOptionalChestParams           # 自选宝箱参数
        speedUpQueueParams 1: ComSpeedUpQueueParams             # 加速队列参数
        optionalAssetsParams 2: ComOptionalAssetsParams         # 自选资产参数
        heroExpParam       3: ComHeroExpParam                   # 英雄经验书参数
    }
    
    .ComOptionalItem2use {                                      # 自选道具 
        itemCfgId 0: uint32                                     # 道具配置id
        num 1: uint32                                           # 数量
        params 2: ComUseItemParams                              # 使用参数
    }
]]

itemProto.c2s = itemProto.struct..[[

useItem 201 {                                                   #使用物品 如果传id以id为主，没有传id找itemCfgId,id和itemCfgId互斥
    request {
        id 0: uint32                                            # id(每个玩家的物品id唯一)
        itemCfgId 1: uint32                                     # itemCfgId配置id
        num 2: uint32                                           # 数量
        params 3: ComUseItemParams                              # 使用参数
    }
    response {
        obtainResources 0: *ComRes                              # 获得的资源
    }
}

useItems 202 {                                                  # 批量使用物品
    request {
        items2use 0: *ComUint32Uint32()                         # 使用的道具(道具id->使用数量)
        optionalItems2use 1: *ComOptionalItem2use               # 自选道具
    }
    response {
        obtainResources 0: *ComRes                              # 获得的资源
    }
}

useItemsAndExchangeUseItems 203 {                               # 批量使用物品和交换物品并使用
    request {
        items2use 0: *ComUint32Uint32()                         # 使用的道具(道具id->使用数量)
        optionalItems2use 1: *ComOptionalItem2use               # 自选道具
        exchanges 3 : *ComUint32Uint32()                        # 交换的物品(物品id->交换数量)
        exchangesParams 4: ComUseItemParams                     # 使用参数
    }
    response {
        obtainResources 0: *ComRes                              # 获得的资源
    }
}

recallItems 204 {                                               # 回收道具
    request {
        items 0: *ComUint32Uint32()                             # 道具(道具id->使用数量)
    }
    response {
        ress 0: *ComRes                                         # 获得的资源
    }
}
]]

itemProto.s2c = itemProto.struct..[[

]]

return itemProto