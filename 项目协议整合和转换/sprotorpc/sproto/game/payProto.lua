--
-- author: TQING<tqing1128@gmail.com>
-- date: 2023-11-07 16:55:16
--

local activityProto = {}

activityProto.struct = [[
    .PayGameOrderParam {
        selectContent 0 : *uint32 # 选择内容
    }

    .PayGoodsData {
        startTime 1 : integer # 开始时间
        duration 2 : integer # 持续时间
        nextRefreshTime 3 : integer # 下次刷新时间
        purchasedCount 4 : integer # 已购买次数
        isPopup 5 : boolean # 是否弹窗
        enable 6 : boolean # 是否可购买

        # 宝石模块类型数据
        isDouble 7 : boolean # 是否双倍
        # 多选一礼包类型数据
        selectGoodsId 8 : integer # 选择的商品 id
    }

    .PayGoods {
        goodsId 0 : integer # 礼包 id
        goodsData 1 : PayGoodsData # 礼包数据
    }
]]

activityProto.c2s = activityProto.struct .. [[

payCreateGameOrder 5601 { # 创建游戏订单
    request {
        goodsId 0 : uint32 # 商品 id
        param 1 : PayGameOrderParam # 游戏订单参数
        useToken 2 : boolean # 是否使用代币
    }
    response {
        gameOrderId 0 : string # 游戏订单 id
    }
}

]]

activityProto.s2c = activityProto.struct .. [[

payDeliver 5601 { # 发货
    request {
        code 0 : integer # 错误码
        goodsId 1 : integer # 商品 id
        result 2 : *ComRes  # 结果
    }
}

]]

return activityProto