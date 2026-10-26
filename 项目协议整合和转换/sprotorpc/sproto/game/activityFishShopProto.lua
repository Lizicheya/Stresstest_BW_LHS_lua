-- 钓鱼商店活动 9051 ~ 9080
local activityFishShopProto = {}

activityFishShopProto.struct = [[
    .ComActFishShop {          # 活动信息
        actId 0: integer       # 活动id
        round 1: integer       # 轮次
        state 2: integer
        isOver 3: boolean
    }
    
    .ComSyncActFishShop {
        news 0: *ComActFishShop(actId)
        changes 1: *ComActFishShop(actId)
        removes 2: *integer
    }
]]

activityFishShopProto.c2s = activityFishShopProto.struct .. [[
]]

activityFishShopProto.s2c = activityFishShopProto.struct .. [[
]]

return activityFishShopProto
