-- 礼包累计给奖 8611 ～ 8630
local payCumulativeProto = {}

payCumulativeProto.struct = [[
    .ComPayCumulative {           # 礼包累计给奖
        goodsId 0: integer        # 礼包id
        startTime 1: integer      # 礼包可以购买开始时间戳（秒）
        gainList 2: *ComIntInt()  # 已领取奖励列表，key:第几天，value:1已领取
        isOver 3: boolean         # 礼包是否已经结束
    }
    
    .ComSyncPayCumulative {
        news 0: *ComPayCumulative(goodsId)
        changes 1: *ComPayCumulative(goodsId)
        removes 2: *integer
    }
]]

payCumulativeProto.c2s = payCumulativeProto.struct .. [[
    gainPayCumulativeAward 8611 { # 领取奖励
        request {
            goodsId 0: uint32   # id
            day 1: uint32       # 第几天
        }
        response {
            ress 1: *ComRes
        }
    }

    gainPayCumulativeAllAward 8612 { # 一键领取当前可领取奖励（领不到不报错的）
        request {
            goodsId 0: uint32        # id
        }
        response {
            ress 1: *ComRes
        }
    }
]]

payCumulativeProto.s2c = payCumulativeProto.struct .. [[
]]

return payCumulativeProto
