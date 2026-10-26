-- 内城地块 7971 ~ 8000
local innerCityBlockProto = {}

innerCityBlockProto.struct = [[
    .ComInnerCityAreaUnlock { # 内城区域数据
        id 1: integer # 区域配置id
        status 2: integer # 状态(InnerCityAreaStatus)
    }

    .ComInnerCityBolckUnlock { # 内城地块数据
        id 1: integer # 地块配置id
        status 2: integer # 状态(InnerCityBlockStatus)
        index 3: integer # 事件索引值(默认0)
    }

    .ComSyncInnerCityAreaUnlock {  # 内城区域数据同步
        news 1: *ComInnerCityAreaUnlock(id)
        changes 2: *ComInnerCityAreaUnlock(id)
        removes 3: *integer
    }

    .ComSyncInnerCityBlockUnlock { # 内城地块数据同步
        news 1: *ComInnerCityBolckUnlock(id)
        changes 2: *ComInnerCityBolckUnlock(id)
        removes 3: *integer
    }

    .ComInnerCityBlockData {
        areaList 1: *ComInnerCityAreaUnlock(id) # 区域信息
        blockList 2: *ComInnerCityBolckUnlock(id) # 地块信息
    }

    .ComSyncInnerCityBlockData {
        areaList 1: ComSyncInnerCityAreaUnlock # 区域信息同步
        blockList 2: ComSyncInnerCityBlockUnlock # 地块信息同步
    }
    
]]

innerCityBlockProto.c2s = innerCityBlockProto.struct .. [[
unlockInnerCityArea 7971 { # 请求解锁内城区域
    request {
        cfgId 1: uint32 # 区域配置id
    }
    response {
        
    }
}

completeInnerCityBlockEvent 7972 { #完成内城地块事件
    request {
        cfgId 1: uint32 # 地块配置id
    }
    response {
        ress 1: *ComRes # 奖励列表
    }
}

]]

innerCityBlockProto.s2c = innerCityBlockProto.struct .. [[
syncInnerCityBlockEventReward 7973 { # 地块事件奖励同步
    request {
        id 1: uint32      # 地块配置id
        ress 2: *ComRes   # 奖励列表
    }
}

]]

return innerCityBlockProto