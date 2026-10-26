--  商店模块 2601~2700
local shopProto = {}

shopProto.struct = [[
    .ComShopSlot {
        shopItemId 1: integer               # 物品ID
        buyCount 2: integer                 # 购买数量
        limitCount 3: integer               # 限制数量
        disaccountPrice 4: *ComRes          # 折扣价格
        originalPrice 5: *ComRes            # 原价
        disaccount 6: integer               # 折扣
        flag 7: integer                     # 标志
        items 8 : *ComRes                   # 获得的物品
        slotId 9: integer                   # 槽位ID
        conditions 10: *ComCondition        # 条件数据
        buyMaxCount 11: integer             # 最大购买限制
        sheet 12: integer                   # 子页签
        showCount 13: integer               # 是否显示库存
        itemSort 14: integer                # 排序因子
        freeTimes 15: integer               # 剩余免费购买次数
    }

    .ComShop {
        id 1: integer                           # 商店id
        manualRefreshCount 2: integer           # 商店手动刷新次数
        slots 3: *ComShopSlot(slotId)           # 商城槽位信息
        nextAutoRefreshTime 4:integer           # 下一次自动刷新时间
        attrManualRefreshCount 5:integer        # 属性手动刷新次数
    }

    .ComActivityShopStat { # 活动商店统计信息
        statCfgId 0: integer
        count 1: integer
    }

    .ComActivityShop {
        activityId 0: integer                   # 活动
        shopId 1: integer                       # 商店id
        items 2: *ComIntInt()                   # 购买信息
        nextAutoRefreshTime 4:integer           # 下一次自动刷新时间
        nextDailyFreeItemsTime 5: *ComIntInt()  # 下次商品可以免费领的时间戳（秒）
        gainList 6: *ComIntInt()                # 已经领取过的进度奖励列表
        stat 7: *ComActivityShopStat(statCfgId) # 统计进度
    }
    
    .ComShopRefresh {
        shopId 0: integer                       # 商店Id
        freeCountAttr 1: integer                # 商店免费刷新次数属性id
        freeManualRefreshCount 2: integer       # 商店免费刷新次数
        version 3: integer                      # 版本号
    }
    
    .ComShopFreeSlot {
        shopId 0: integer                       # 商店Id
        version 1: integer                      # 版本号
        freeSlotIds 2: *integer                 # 免费槽
    }
]]

shopProto.c2s = shopProto.struct..[[

buyShopItem 2601 { #购买商店物品
    request {
        shopId 0: uint32                   # 商店ID
        slotId 1: uint32                   # 槽位ID
        count 2: uint32                    # 购买商品次数               
    }
    response {
        shopId 0: integer                   # 商店ID
        slot 1: ComShopSlot                 # 商品槽更新信息
        ress 2: *ComRes                     # 获得的资源
    }
}

refreshShop 2602 { #刷新商店
    request {
        shopId 0: uint32                   # 商店ID
    }
    response {
        shop 0: ComShop                     #商店数据同步
    }
}

getShopInfo 2603 { #获取商店信息
    request {
        shopId 0: uint32                   # 商店ID
    }
    response {
        shop 0: ComShop                     #商店数据同步
    }
}

buyActivityShopItem 2604 { #购买活动商店物品
    request {
        activiyId 0: uint32                #活动ID
        itemId 1: uint32                   #购买物品ID
        count 2: uint32                    #购买商品次数        
    }
    response {
        ress 2: *ComRes                     # 获得的资源
    }
} 

getActivityShopFreeItem 2605 {             # 领取活动商店每日免费物品
    request {
        activiyId 0: uint32                # 活动ID
        itemId 1: uint32                   # 购买物品ID
    }
    response {
        ress 0: *ComRes                    # 获得的资源
    }
}

getActivityShopProgressReward 2606 {       # 领取活动商店进度奖励
    request {
        activiyId 0: uint32                # 活动ID
        id 1: uint32                       # 进度奖励配置ID
    }
    response {
        ress 0: *ComRes                    # 获得的资源
    }
}

shopFreeItem 2607 {                        # 免费获得商店物品
    request {
        shopId 0: uint32                   # 商店ID
        slotId 1: uint32                   # 槽位ID
    }
    response {
        shopId 0: integer                   # 商店ID
        slot 1: ComShopSlot                 # 商品槽更新信息
        ress 2: *ComRes                     # 获得的资源
    }
}

]]

shopProto.s2c = shopProto.struct..[[
    shopChangeNotice 2604 {                 #商城数据更新通知
    request {
        shopId 0: integer                   #商店ID
    }
    response {
    }
}
]]

return shopProto