-- 队列模块 401~500
local queueProto = {}

queueProto.struct = [[
    .ComBuildData{
        id 0: integer                           # 建筑id
        lv 1: integer                           # 当前等级
        buildCfgId 2: integer                   # 建筑类型
    }
    
    .ComTrainArmyData{
        isUpgrade 0: boolean                    # 是否是升级
        oldArmyCfgId 1: integer                 # 升级前的id
        armyCfgId 2: integer                    # 士兵id
        num 3: integer                          # 士兵数量
    }
    
    .ComHealArmyData{
        id2num 0: *ComArmyIdAndNum()            # 士兵id<->士兵数量
    }

    .ComTechnologyData{
        id 0: integer                           # 科技id
        lv 1: integer                           # 当前等级
    }

    .ComAreaUnlock {
        areaCfgId 0: integer                    # 区域id
    }

    .ComProduceDefenderPart {
        itemId 0: integer
        tss 1: *integer
    }

    .ComResurrectDeadArmyData {
        id2num 0: *ComArmyIdAndNum()            # 士兵id<->士兵数量
    }

    .ComQueueData {
        buildData 0: ComBuildData               # 建造数据
        trainArmyData 1: ComTrainArmyData       # 训练数据
        healArmyData 2: ComHealArmyData         # 治疗数据
        technologyData 3: ComTechnologyData     # 科技数据
        areaUnlock 4: ComAreaUnlock             # 地块铺设数据
        produceDefenderPart 5: ComProduceDefenderPart # 生产防御者升级部件
        blockInfo 6: ComBlockInfo               # 生产积木数据
        resurrectDeadArmyData 7: ComResurrectDeadArmyData # 复活死亡士兵数据
    }

    .ComQueue {
        queueCfgId 0: integer                   # 队列配置id
        expiredTs 1: double                     # 完成时间
        data 2: ComQueueData                    # 队列数据
        isReqHelp 3: boolean                    # 是否已经请求过帮助
        startTs 4: double                       # 开始时间
        totalTime 5: double                     # 总时间
        helpReduceTime 6: double                # 联盟帮助减少的总时间
    }

    .ComSyncQueueTry {
        news 1: *ComIntInt()
        changes 2: *ComIntInt()
        removes 3: *integer
    }
]]

queueProto.c2s = queueProto.struct..[[

speedupQueue 401 { #加速队列
    request {
        queueCfgId 0: uint32                   # 配置表id
        items 1: *ComUint32Uint32()                   # 加速道具id->数量
        resExchanges 2: *ComUint32Uint32()            # 资源兑换(资源兑换配置id->兑换数量)
    }
    response {
    }
}

cancelQueue 402 { #取消队列
    request {
        queueCfgId 0: uint32                   # 配置表id
    }
    response {
    }
}

reqAllianceHelp 403 { #请求联盟帮助
    request {
        queueCfgId 0: uint32                   # 配置表id
    }
    response {
    }
}

speedupQueueByHeroAttr 404 { #英雄属性加速队列
    request {
        queueCfgId 0: uint32                   # 配置表id
    }
    response {
    }
}

reqQueueTry 405 { # 限时队列试用
    request {
    }
    response {
    }
}

]]

queueProto.s2c = queueProto.struct..[[

]]

return queueProto