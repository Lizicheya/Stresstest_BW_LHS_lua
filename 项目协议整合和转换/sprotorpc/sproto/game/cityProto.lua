--# 内城模块 301~400
local cityProto = {}

cityProto.struct = [[
    .ComBuild {
        id 0: integer                                               # id(每个玩家的建筑id唯一)
        buildCfgId 1: integer                                       # 配置表id
        status 2: integer                                           # 状态
        x 3: integer                                                # 位置x
        y 4: integer                                                # 位置y
        lv 5:integer                                                # 等级
        workers 6:integer                                           # 工人数量
    }

    .ComBuildPos {
        id 0: uint32                                               # id(每个玩家的建筑id唯一)
        x 3: uint32                                                # 位置x
        y 4: uint32                                                # 位置y
    }

    .ComBlockInfo {                                                 # 生产积木信息
        startTs 0: integer                                          # 生产开始时间
        endTs 1: integer                                            # 生产结束时间
        totalTs 2: integer                                          # 生产总时间
        totalNum 3: integer                                         # 生产总数量
        genNum 4: integer                                           # 已生产数量
        auto 5: boolean                                             # 是否自动生产
    }

    .ComWaterInfo {                                                 # 水位信息
        flooded 0: boolean                                          # 是否淹没
        cnt 1: integer                                              # 淹没次数
        startTs 2: integer                                          # 开始时间
        endTs 3: integer                                            # 结束时间
        failMonsters 4: *integer                                    # 失败时怪物(TideRuins表ID)
    }

    .ComCityBlock {
        blockInfo 0 : ComBlockInfo
        waterInfo 3 : ComWaterInfo
    }

    .ComFurniture {
        buildId 0: integer # 建筑唯一id
        id 1: integer # 家具唯一id
        cfgId 2: integer # 家具配置表id
        lv 3: integer # 家具等级
    }
]]

cityProto.c2s = cityProto.struct..[[

build 301 { #建造
    request {
        buildCfgId 0: uint32                                       # 配置表id
        x 3: uint32                                                # 位置x
        y 4: uint32                                                # 位置y
        immediately 5: boolean                                      # 是否立即完成
        resExchanges 6: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 7: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 8: *ComOptionalItem2use                   # 自选道具
        isHeroAttr 9: boolean
    }
    response {
    }
}

upgrade 302 { #升级
    request {
        id 0: uint32                   # 建筑id
        immediately 1: boolean                                      # 是否立即完成
        resExchanges 2: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 3: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 4: *ComOptionalItem2use                   # 自选道具
        isTimeReduce 5: boolean                                     # 拼图完成可减少升级时间
        isHeroAttr 6: boolean
    }
    response {
    }
}

changeBuildPos 303 { #更改建筑位置
    request {
        id 0: uint32                   # 建筑id
        x 1: uint32                    # 位置x
        y 2: uint32                    # 位置y
    }
    response {
    }
}

recycleBuild 304 { #回收建筑
    request {
        id 0: uint32                   # 建筑id
    }
    response {
    }
}

batchChangeBuildPos 305 { #更改建筑位置
    request {
        arrBuildPos 0: *ComBuildPos   # 建筑位置
    }
    response {
    }
}

batchRecycleBuild 306 { #回收建筑
    request {
        ids 0: *uint32                 # 建筑id
    }
    response {
    }
}

removeBuild 307 { #删除建筑
    request {
        id 0: uint32                   # 建筑id
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

produceBlock 308 { #生产积木【废弃】
    request {
        id 0: uint32                                               # 建筑id
        productTime 1: uint32                                      # 时长
        immediately 2: boolean                                      # 是否立即完成
        resExchanges 3: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 4: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 5: *ComOptionalItem2use                   # 自选道具
    }
    response {
    }
}

produceDefenderPart 311 { #生产积木防御者部件
    request {
        id 0: uint32                                               # 建筑id
        itemId 1: uint32                                           # 图纸id
        num 2: uint32                                              # 数量
        resExchanges 3: *ComUint32Uint32()                                # 资源兑换(资源兑换配置id->兑换数量)
        items2use 4: *ComUint32Uint32()                                   # 使用的道具(道具id->使用数量)
        optionalItems2use 5: *ComOptionalItem2use                   # 自选道具
    }
    response {
    }
}

buyWaterTime 318 { #购买内城水位时长
    request {
        mins 0: uint32                                              # 购买时长
    }
    response {
        waterInfo 0 : ComWaterInfo
    }
}

syncWaterInfo 319 { #同步内城水位状态
    request {
        flooded 0: boolean                                          # 是否淹没
        cnt 1: uint32                                               # 淹没次数
    }
    response {
        waterInfo 0 : ComWaterInfo
    }
}

endWaterFail 320 { #点掉怪物
    request {
        k 0 : uint32                                                # failMonster数组下标
    }
    response {
        k 0 : integer                                               # failMonster数组下标
        ress 1 : *ComRes                                            # 奖励列表
        waterInfo 2 : ComWaterInfo
    }
}

setBuildWorker 321 { #给资源建筑设置工人
    request {
        ids 0: *ComIntInt()  # 建筑id - 工人数量
    }
    response {
    }
}

upgradeFurniture 322 { #家具升级
    request {
        buildId 0: uint32 # 建筑唯一id
        furnitureId 1: uint32 # 家具唯一id
    }
    response {
    }
}

]]

cityProto.s2c = cityProto.struct..[[

]]

return cityProto