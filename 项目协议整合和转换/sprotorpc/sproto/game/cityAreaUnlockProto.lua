-- 区域解锁 5701 ~ 5800
local cityAreaUnlockProto = {}

cityAreaUnlockProto.struct = [[
    .ComUnlockFlags {
        key 0: integer                                  # 索引
        value 1: *integer                               # 解锁标记,8字节整数,每个整数64位,表示64个点
    }
    .ComCityAreaUnlock {
        areaCfgId 0: integer                            # id(innerCityArea表id)
        status 1: integer                               # 状态(CityAreaStatusType)
        statusTs 2: integer                             # 状态开始时间
        #arrRectUnlockFlags 3: *ComUnlockFlags()        # 矩形解锁标记
        event 3: integer                                # 事件 0=事件已完成  1=事件未完成
    }
]]

cityAreaUnlockProto.c2s = cityAreaUnlockProto.struct..[[

batchUnlockCityArea 5701 { # 解锁区域
    request {
        areaCfgId 0: uint32                            # 区域配置id
    }
    response {
    }
}

getUnlockCityAreaReward 5702 { # 领取事件奖励
    request {
        areaCfgId 0: uint32                            # 区域配置id
    }
    response {
        ress 0 : *ComRes                                # 奖励列表
    }
}

getUnlockCityAreaMonster 5703 { # 领取事件野怪信息
    request {
        areaCfgId 0: uint32                            # 区域配置id
    }
    response {
        objId 0: integer                                # 场景对象id
    }
}

]]

cityAreaUnlockProto.s2c = cityAreaUnlockProto.struct..[[

]]

return cityAreaUnlockProto