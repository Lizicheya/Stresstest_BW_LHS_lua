-- 联盟建筑 3601 ~ 3700
local allianceProto = {}

allianceProto.struct = [[
    .ComBuildingData {
        durability 0: integer #当前耐久度
        buildSpeed 1: double #建造速度 N/h
        speedTime 2: integer  #当前速度的时间戳
        endTime 3: integer    #建造结束时间戳
        brokenTime 4: integer #损毁截止时间
        destroySpeed 5: double #敌方拆除速度
        destroyTime 6: integer #当前拆除速度的时间戳
        destroyEndTime 7: integer #敌方拆除完成时间戳
        terrArea 8: integer #领地值
        buildStage 9: integer #建造or扩建

    }

    .ComAltar {
        level 0: integer #等级
        exp 1: integer   #经验
        stage 2: integer #阶段 1准备 2召唤 3试炼
        stageEndTime 3: integer #阶段时间戳
        monsterId 4: integer #祭坛boss
        summonTime 5: integer #召唤时间
        alliancePoint 6: ComPoint # 建造时联盟集合点坐标
    }

    .ComHonorMine {
        lifeTime  1: integer                                #到期回收时间戳
        remainResource 2: integer                           #剩余资源
        collectSpeed  3: double                             #当前采集速度
        collectSpeedTime  4: integer                        #当前采集速度开始时间戳
        collectTroopIds 5: *ComIntInt()                     #采集部队 [uid]=troopId 
    }

    .ComAllianceFish {
    }

    .ComAllianceBuild {
        id 0: integer #建筑id,联盟内唯一
        bid 1: integer #建筑配置id
        x 2: integer #x坐标 
        y 3: integer #y坐标
        status 4: integer #建筑状态 AllianceBuildStatusType
        isAct 5: boolean #是否有效
        sn 6: integer #sn值,判断地块归属,sn值小的拥有地块所有权
        isGarrison 7: boolean #是否驻防
        isDismantle 8: boolean #是否拆除中 
        dismantleTime 9: integer #开始拆除时间戳
        buildingData 10: ComBuildingData
        allianceAltar 11: ComAltar #祭坛
        allianceBlockMine 12: ComHonorMine #联盟积木矿
        allianceFish 13: ComAllianceFish #联盟钓鱼宴会建筑
    }

]]

allianceProto.c2s = allianceProto.struct .. [[
    buildAllianceBuild 3601 {                                   # 创建联盟建筑
        request {
            mapId 0: uint32                                    # 地图id
            bid 1: uint32                                      # 建筑配置id
            x 2: uint32                                        # x坐标
            y 3: uint32                                        # y坐标
        }
        response {

        }
    }

    moveAllianceBuild 3602 {                                    # 移动联盟建筑
        request {
            mapId 0: uint32                                    # 地图id
            id 1: uint32                                       # 建筑id
            x 2: uint32                                        # x坐标
            y 3: uint32                                        # y坐标

        }
        response {

        }
    }

    dismantleAllianceBuild 3603 {                               # 拆除联盟建筑
        request {
            mapId 0: uint32                                    # 地图id
            id 1: uint32                                       # 建筑id                            
        }
        response {
            
        }
    }

    cancelDismantleAllianceBuild 3604 {                          # 取消拆除联盟建筑
        request {
            mapId 0: uint32                                     # 地图id
            id 1: uint32                                        # 建筑id
        }
        response {

        }
    }

    

]]

allianceProto.s2c = allianceProto.struct .. [[

    

]]

return allianceProto