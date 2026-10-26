-- 押运货车 8111～8150
local escortTruckProto = {}

escortTruckProto.struct = [[
.ComEscortHero {  # 护卫英雄
    key 0: uint32                                  # 位置
    value 1: ComHero                               # 英雄数据
}

.ComTruckSlot { # 槽位
    slotId 0: uint32 # 槽位id
    status 1: uint32 # 槽位状态
    formation 2: *ComEscortHero() # 保存的编队
    freeNum 3: uint32 # 剩余免费刷新次数
    truckQuality 4: uint32 # 车辆品质 # 空闲状态下，下一次刷新的车辆品质
} 

.ComTruckInfo { # 车辆
    truckId 0: uint32 # 车辆id
    slotId 1: uint32 # 所在的槽位id
    cfgId 2: uint32 # 车辆配置表id
    awardCfgId 3: uint32 # 车辆奖励配置表id
    status 4: uint32 # 车辆状态
    carryRess 5: *ComRes # 携带的资源
    robbedRess 6: *ComRes # 被抢的资源
    robbedNum 7: uint32 # 被抢夺次数
    arriveTs 8: uint32 # 到达时间戳 默认0
    formation 9: *ComEscortHero() # 护卫队伍 不包含兵力数据
    totalPower 10: uint32 # 护卫队伍总战力 英雄+兵力
    looter 11: boolean # 是否掠夺者的车辆
    
    uid 12: uint32                                   # 玩家uid
    nickName 13: string                              # 玩家昵称
    headId 14: uint32                                # 头像
    headFrameId 15: uint32                           # 头像框
    customHead 16: string                            # 自定义头像
    serverId 17: uint32                              # 所属服务器
    castleLv 18: uint32                              # 主堡等级/领主等级
    abbName 19: string                               # 联盟简称

    id 20: uint32    # 玩家唯一id
    
    startTime 21: uint32 # 发车时间
    sceneObjId 22: integer # 沙盘对象id
    path 23: *ComPath # 起点开始途径坐标点
    speed 24: double # 移动速度

    army 25: *ComArmyIdAndNum()                  # 各兵种数量
    escortTime 26: integer # 运输时间
}

.ComEscortTruck {
    isUnlock 0: boolean # 功能是否解锁
    slots 1: *ComTruckSlot(slotId) # 槽位信息
    trucks 2: *ComTruckInfo(truckId) # 车辆信息
    escortNum 3: uint32 # 今日护送次数(车辆发出+1)
    lootNum 4: uint32 # 今日掠夺次数(掠夺成功+1)
}

.ComSyncEscortTruck {
    isUnlock 0: boolean # 功能是否解锁
    slots 1: ComSyncTruckSlot # 槽位信息同步
    trucks 2: ComSyncTruckInfo # 车辆信息同步
    escortNum 3: uint32 # 今日护送次数
    lootNum 4: uint32 # 今日掠夺次数
}

.ComSyncTruckSlot { # 槽位同步
    news 1: *ComTruckSlot(slotId)
    changes 2: *ComTruckSlot(slotId)
    removes 3: *integer
}

.ComSyncTruckInfo { # 车辆同步
    news 1: *ComTruckInfo(truckId)
    changes 2: *ComTruckInfo(truckId)
    removes 3: *integer
}

.ComEscortTruckEscortDetail { # 押运记录
    id 1: uint32 # 押运id
    cfgId 2: uint32 # 车辆配置表id
    awardCfgId 3: uint32 # 车辆奖励配置表id
    status 4: uint32 # 车辆状态
    carryRess 5: *ComRes # 携带的资源
    robbedRess 6: *ComRes # 被抢的资源
    robbedNum 7: uint32 # 被抢夺次数
    arriveTs 8: uint32 # 到达时间戳 默认0
    formation 9: *ComEscortHero() # 护卫队伍 不包含兵力数据
    totalPower 10: uint32 # 护卫队伍总战力
}

.ComEscortTruckLootDetail { # 掠夺记录详情
    id 0: uint32                                    # 掠夺id
    uid 1 : uint32                                  # 玩家uid
    nickName 2: string                              # 玩家昵称
    serverId 3: uint32                              # 所属服务器
    abbName 4: string                               # 联盟简称
    succ 5: boolean                                 # 是否掠夺成功
    ress 6: *ComRes                                 # 掠夺成功，获得的资源
    time 7: uint32                                  # 时间戳
    kill 8: uint32                                  # 击败士兵数量
}

.ComEscortTruckFightDetail { # 战斗记录详情
    uid 0 : uint32                                  # 玩家uid
    nickName 1: string                              # 玩家昵称
    headId 2: uint32                                # 头像
    headFrameId 3: uint32                           # 头像框
    customHead 4: string                            # 自定义头像
    totalPower 5: uint32                            # 玩家护卫队伍战力
    serverId 6: uint32                              # 所属服务器
    abbName 7: string                               # 联盟简称
    succ 8: boolean                                 # 是否防守成功
    ress 9: *ComRes                                 # 防守失败，损失的资源
    time 10: uint32                                 # 时间戳
}




]]



escortTruckProto.c2s = escortTruckProto.struct .. [[

escortTruckRreshSlot 8111 { # 请求刷新车位上的车辆
    request {
        slotId 0: uint32 # 车位id
        isGem 1: boolean # true:消耗钻石 false:消耗道具
    }
    response {

    }
}

escortTruckSaveFormation 8112 { # 保存护送队伍
    request {
        slotId 0: uint32                               # 车辆槽位
        formation 1: *ComUint32Uint32()                # 编队 [pos] = heroCfgId
    }
    response {

    }
}

escortTruckAddTroop 8113 { # 发车
    request {
        slotId 0: uint32
        formation 1: *ComUint32Uint32()               # 编队 [pos] = heroCfgId
        army 2: *ComArmyIdAndNum()                  # 各兵种数量
    }
    response {

    }
}

escortTruckRecvTransportReward 8114 { # 领取车辆奖励
    request {
        truckId 0: uint32
    }
    response {
        ress 1: *ComRes               # 资源奖励
    }
}

escortTruckLootTruck 8115 { # 掠夺车辆
    request {
        targetId 0: uint32            # 目标uid
        kid 1: uint32                 # 目标所在王国id
        truckId 2: uint32             # 目标车辆id
        formation 3: *ComUint32Uint32()  # 上阵编队 [pos] = heroCfgId
        army 4: *ComArmyIdAndNum()    # 各兵种数量
    }
    response {
        isWin 0: boolean              # 是否掠夺成功
        ress 1: *ComRes               # 掠夺到的资源
        result 2: ComBattleResult
    }
}

escortTruckRefreshLootTrucks 8116 { # 刷新可掠夺车辆
    request {
        isBlock 1: boolean # 是否屏蔽本服(当前版本不支持跨服)
    }
    response {
        trucks 1: *ComTruckInfo
    }
}

escortTruckGetTruckFightRecord 8117 { # 获取车辆的战斗记录列表
    request {
        ownerId 0: uint32             # 目标uid
        kid 1: uint32                 # 目标所在王国id
        id 2: uint32                  # 目标车辆押运id
    }
    response {
        recordList 1: *ComEscortTruckFightDetail
    }
}

escortTruckGetLootRecord 8118 { # 获取自己的掠夺记录
    request {
    }
    response {
        recordList 1: *ComEscortTruckLootDetail(id)
    }
}

escortTruckGetEscortRecord 8119 { # 获取自己的押运记录
    request {
    }
    response {
        recordList 1: *ComEscortTruckEscortDetail(id)
    }
}

escortTruckGetTruckDetail 8120 { # 获取车辆的详细信息
    request {
        kid 1: uint32 
        truckId 2: uint32
    }
    response {
        truck 1: ComTruckInfo
        modifiedTankParts 2: *ComModifiedTankPart(partType)   # 改装车部位列表
        tankLv 3: uint32                # 改装车等级
    }
}

escortTruckGetRobReport 8121 { # 获取掠夺记录战报
    request {
       id 1: uint32 # 掠夺记录id
    }
    response {
        battleReport 1: ComMailBattleReport      #战报
    }
}


]]


escortTruckProto.s2c = escortTruckProto.struct .. [[

]]

return escortTruckProto