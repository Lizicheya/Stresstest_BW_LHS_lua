-- 场景模块 41~200
local sceneProto = {}

sceneProto.struct = [[
    .ComCastle {
        nickName 0: string
        castleLv 1: integer
        castlePosX 2: integer                              #主堡相对位置
        castlePosY 3: integer
        head 4: integer                                    #头像ID
        headFrame 5: integer                               #头像框ID
        shieldTs 6:integer                                 #保护罩到期时间
        isBurning 7:boolean                                #是否在燃烧
        isMaxDurability 8:boolean                          #当前城防值是否已满
        isMaxRobustness 9:boolean                          #当前坚固值是否已满
        maintainTs 10:integer                              #服务器维护到期时间
        skin            11:integer                         #主城装扮
        skinWing        12:integer                         #主城背饰	
        skinPendant     13:integer                         #主城挂件	
        skinCityEffect  14:integer                         #主城特效	
        skinHonor       15:integer                         #称号	
        skinMarch       16:integer                         #个人行军装扮	
        skinAssemble    17:integer                         #集结行军装扮	
        skinEffect      18:integer                         #攻击特效	
        skinHaloEffect  19:integer                         #光环特效	
        age             20:integer                         #时代
        isMovePos       21:boolean                         #是否移动位置
        officialId      22:integer                          #王战官职
        seasonGloryLv   23:integer                         #赛季荣耀最高等级

        spvpLastFreeMoveCastleTime 24:integer              #个人PVP上次免费迁城时间
        spvpMoveTimes 25:integer                           #个人PVP当前已迁城次数
        serverId 26: integer                               #原服务器ID
        officialId2      27:integer                         #跨服战官职
    }
    
    .ComCastle2 {
        nickName 0: string
        castleLv 1: integer
        shieldTs 6:integer                                 #保护罩到期时间
    }
        
    .ComCastle3 {
        castleLv 1: integer
        shieldTs 6:integer                                 #保护罩到期时间
    }
    .ComTroop {
        curX 3: double
        curY 4: double
        capacity 5:integer                                  #部队容量 集结部队和建筑驻防部队会用到
        nickName 6: string                                  #显示名称
        moving 9: boolean
        path 10: *ComPath
        startWalkRate 11: double                            # 当前位置点对应的时间
        startWalkRateTS 12: double
        totalDist 13: double                                # 行走总距离 服务器重启时恢复部队状态用
        rallyTargetId 14: integer                           # 集结目标 服务器重启时恢复部队状态用
        stopDistance 15: double                             # 停止距离
        initArmy 16: *ComArmyIdAndNum()                     # 初始兵量
        heros 17: *ComIntInt()
        totalArmyNum 18: integer
        army 19: *ComArmyIdAndNum()
        truceArmy 20: *ComArmyIdAndNum()                    # 轻伤士兵
        battleInfo 21: ComTroopBattleInfo
        targetId 22: integer
        totalTime 23: double
        targetAid 24: integer                               #目标aid
        inBattle 26: boolean
        showLine 27: boolean
        dir 28: integer
        isDead 29: boolean                                  # 是否死亡溃败回城
        lifeTime  30: integer                               # 怪物生存时间戳

        collectedResCfgId 31:integer                        # 采集资源配置id 用于服务器重启时还原
        maxLoadResource 32: integer                         # 最大资源负载
        collectedResource 33: *ComIntInt()                  # 已采集资源量
        startCollectTime 34: integer                        # 开始采集时间
        stopCollectTime 35: integer                         # 采集结束时间
        calcCollectTime 36: integer                         # 采集中途结算时间

        startMontageTime 37: integer                        # 开始Montage时间
        stopMontageTime 38: integer                         # 结束Montage时间

        rallyTroopId 39: integer                            # 子部队加入的集结部队id
        corpInfo 40 : ComTroopCorpInfo                      # 集结信息
        rallyWaitTime 41 : integer                          # 集结等待时间 秒
        rallyWaitTS 42 : integer                            # 集结等待时间戳

        skinMarch       43:integer                          # 行军装扮 个人或集结	
        skinEffect      44:integer                          # 攻击特效

        backAfterBattle 45:boolean                          # 是否是战斗后回家
        extId      46:integer                               # 额外Id: 1.雷达怪事件Id  2.内城区域Id
        initTotalTime 47: double                            # 行走初始总时间

        helpUids 48 : *uint64                               # 协助uid信息
        anger 49 : integer                                  # 怒气值

        curHpRate 50 : double                               # 当前血量比例
        endWalkRateTS    51: double                         # 结束行走时间
        escortTruck 52: ComTruckInfo                        # 运输车

        breakDefenseTime 53: integer                        # 破坏城防时间戳
        oldestEnemyId 54: integer                           # 最早攻击自己的部队id 
        curAttackId 55: integer                             # 当前攻击的部队id
        isTeleport2attackPos 56: boolean                    # 是否瞬移到攻击位置

        tankLv 61: uint32                                  # 改装车等级
        activeSuitId 62: uint32                              # 激活的套装ID 
    }
    .ComTroop2 {
        curX 3: double
        curY 4: double
        path 10: *ComPath
        startWalkRate 11: double                            # 当前位置点对应的时间
        startWalkRateTS 12: double
        heros 17: *ComIntInt()
        targetId 22: integer
        totalTime 23: double
        targetAid 24: integer                               #目标aid
    }
    .ComResource {                                          #矿点
        collectTroopId 1: integer                           #采集部队id
        collectorName 2: string                             #采集者昵称
        startCollectTime 3: integer                         #开始采集时间
        stopCollectTime 4: integer                          #采集结束时间
        calcCollectTime 5: integer                          #采集中途结算时间
        collectSpeedPlus  6: integer                        #额外加成采集速度(采集量/每小时)
        remainResource 7: integer                           #剩余资源
    }
    .ComResource2 {                                          #矿点
        collectTroopId 1: integer                           #采集部队id
    }

    .ComScoreResource {                                     #个人PVP副本 积分矿
        initNpcId 0: integer                                #初始npc
        collectTroopId 1: integer                           #采集部队id
        collectorName 2: string                             #采集者昵称
        startCollectTime 3: integer                         #开始采集时间
        stopCollectTime 4: integer                          #采集结束时间
        collectorServerId 5: integer                        #采集者ServerId
        remainResource 7: integer                           #剩余资源
        initResource   8: integer                           #初始资源总量
        head 9: integer                                     #采集者头像ID
        headFrame 10: integer                               #采集者头像框ID

        attackerName 11: string                             #攻击者昵称
        attackTroopCount 12: integer                        #攻击队伍人数

    }

     .ComScoreWarehouse {                                   #个人PVP 积分仓库

        initNpcId 0: integer                                #初始npc
        occupyingTroopId 1: integer                         #占领部队id
        buildStatus 2: integer                              #建筑状态
        occupyingName 3: string                             #占领者昵称
        occupyingServerId 4: integer                        #占领者ServerId
        head 5: integer                                     #占领者头像ID
        headFrame 6: integer                                #占领者头像框ID
        startOccupyTime 7: integer                          #开始占领时间
       

        attackerName 11: string                             #攻击者昵称
        attackTroopCount 12: integer                        #攻击队伍人数
    }

    .ComScoreDrop {                                         #个人PVP 可拾取积分
        initResource   1: integer                           #积分总量
    }

     .ComSgvgBuild {                                         #gvg地图建筑
        uid 1: integer                                     #队长UID
        head 2: integer                                    #队长头像ID
        headFrame 3: integer                               #队长头像框ID
        nickName 4: string                                 #队长头昵称
    }
    
    .ComBlackGoldMine {                                     #黑金战场 玉石矿
        collectTroopId 1: integer                           #采集部队id
        collectorName 2: string                             #采集者昵称
        startCollectTime 3: integer                         #开始采集时间
        stopCollectTime 4: integer                          #采集结束时间
        collectorServerId 5: integer                        #采集者ServerId
        remainResource 7: integer                           #剩余资源
        initResource   8: integer                           #初始资源总量
        head 9: integer                                     #采集者头像ID
        headFrame 10: integer                               #采集者头像框ID
    }

     .ComBlackGoldBuild {                                    #黑金战场建筑
        dugeonStartTs 0: integer                             #副本开始时间戳
        openTime    1 : integer                              #开启时间戳（属性建筑）
        occupyCamp  2: integer                               #占领方阵营 1 蓝方 2 红方
        agateCount  3: integer                               #玛瑙数量(神殿)  
        buildStatus 4: integer                               #建筑状态MapBuildStatusType（属性建筑）
        firstOccupyCamp 5: integer                           #首次占领方（属性建筑）nil 表示未占领
        occupyingCamp  6: integer                            #正在占领中阵营
        occupyingEndTime  7: integer                         #占领方完全控制结束时间=完全占领开始时间
    }


    .ComVillage {                                           #村庄
        extId      0:integer                                #雷达怪事件Id
    }

    .ComRadarGameRoom {                                     #雷达拼接建筑
        extId      0:integer                                #雷达怪事件Id
    }
    
    .ComRadarPve {                                          #雷达拼接建筑
        extId      0:integer                                #雷达怪事件Id
    }
    
    .ComRadarMine {                                        #雷达矿点
        extId      0:integer                                #雷达怪事件Id
        collectTroopId 1: integer                           #采集部队id
        collectorName 2: string                             #采集者昵称
        startCollectTime 3: integer                         #开始采集时间
        stopCollectTime 4: integer                          #采集结束时间
    }

    .ComAllianceResource {                                   #联盟资源
        flagId  1: integer                                  #联盟旗帜
        patternId  2: integer                               #联盟旗帜模板
        colorId 3: integer                                  #标志颜色
        isEffect 4: boolean                                 #是否生效
        initNpcId 5: integer                                #npcId 大于0时，表示有占领npc
    }

    .ComAllianceCenter {                                     #联盟中心

        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                               #建筑状态AllianceBuildStatusType
        durability  5: integer                               #当前耐久度
        buildSpeed  6: double                               #当前建造速度
        speedTime   7: integer                               #当前建造速度的时间戳
        endTime     8: integer                               #建造完成时间戳
        isDismantle 9: boolean                               #是否拆除中    自己拆除
        dismantleTime 10: integer                            #开始拆除时间戳
        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
        isBurning 14: boolean                                #是否在燃烧
        destroySpeed  16: double                            #敌方拆除速度
        destroyTime   17: integer                            #当前拆除速度的时间戳
        destroyEndTime     18: integer                       #敌方拆除完成时间戳
        isGarrisoned 19: boolean                             #是否驻防
        brokenTime 20: integer                               #损毁截止时间
        terrArea 21: integer                                 #领地值
        buildStage 22: integer                               #建造阶段
        maxDurability 23: integer                            #耐久度上限

    }

    .ComAllianceCenter2 {                                    #联盟中心
        buildStatus 4: integer                               #建筑状态AllianceBuildStatusType
    }

    .ComAllianceGuardTower {                                 #联盟哨塔

        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                               #建筑状态AllianceBuildStatusType
        durability  5: integer                               #当前耐久度
        buildSpeed  6: double                               #当前建造速度
        speedTime   7: integer                               #当前建造速度的时间戳
        endTime     8: integer                               #建造完成时间戳
        isDismantle 9: boolean                               #是否拆除中
        dismantleTime 10: integer                            #开始拆除时间戳
        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
        isBurning 14: boolean                                #是否在燃烧
        destroySpeed  16: double                            #敌方拆除速度
        destroyTime   17: integer                            #当前拆除速度的时间戳
        destroyEndTime     18: integer                       #敌方拆除完成时间戳
        isGarrisoned 19: boolean                             #是否驻防
        brokenTime 20: integer                               #损毁截止时间
        terrArea 21: integer                                 #领地值
        buildStage 22: integer                               #建造阶段
        maxDurability 23: integer                            #耐久度上限

    }

    .ComAllianceGuardTower2 {                                #联盟哨塔
        buildStatus 4: integer                               #建筑状态AllianceBuildStatusType
    }

    .ComAllianceAltar {                                      #联盟祭坛

        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                               #建筑状态

        exp  5: integer                                      #经验
        level 6: integer                                     #等级
        stage  7: integer                                    #状态 准备、开启、试炼
        stageEndTime 8: integer                              #状态结束时间戳
        summonTime 9: integer                                #预约时间
        totalDamage 10: double


        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
    }

    .ComAllianceHonorBuild {                                 #联盟荣誉建筑

        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                               #建筑状态

        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
    }


    .ComAllianceBlockMine {                                  #联盟积木矿

        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                              #建筑状态

        endTime     5: integer                              #建造完成时间戳

        lifeTime  6: integer                                #到期回收时间戳
        remainResource 7: integer                           #剩余资源 不包含当前采集部队的已采集数
        collectSpeed  8: double                             #当前采集速度
        collectSpeedTime  9: integer                        #当前采集速度开始时间戳



        collectTroopIds 10: *ComIntInt()                    #采集部队 [uid]=troopId

        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
        totalRemainResource 14: integer                      #未采走剩余资源 包含当前采集部队的已采集数 服务器用
    }

    .ComAllianceNpcTrial {                                   #联盟试炼场
        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                               #建筑状态AllianceBuildStatusType
        durability  5: integer                               #当前耐久度
        buildSpeed  6: double                                #当前建造速度
        speedTime   7: integer                               #当前建造速度的时间戳
        endTime     8: integer                               #建造完成时间戳

        isDismantle 9: boolean                               #是否拆除中
        dismantleTime 10: integer                            #开始拆除时间戳

        flagId  11: integer                                  #联盟旗帜
        patternId  12: integer                               #联盟旗帜模板
        colorId 13: integer                                  #标志颜色
    }

    .ComTroopCollectInfo {                                  #部队采集信息
        troopId 1: integer                                  #部队id
        troopInfo 2: ComBattleTroopInfo                     #部队信息
        startCollectTime 3: integer                         #开始采集时间
        collectSpeed  4: double                             #采集速度
    }

    .ComBuffHold {                                          #据点

        status  1: integer                                  #状态 0 未开启 1 保护状态 2 可争夺状态
        statusEndTime 2: integer                            #当前状态结束时间
        isProfitable  3: integer                            #是否产生了增益 0 否 1 是 2 增益冲突
        defense 4: integer                                  #当前城防值
       

        firstOwned  5: integer                              #首次占领的联盟id
        firstAllianceFullName 6: string                     #首占联盟名称
        firstAllianceAbbName 7: string                      #首占联盟简称
        firstOwnedTime 8: integer                           #首占时间
        maxDefense 9: integer                               #城防值上限

        terrConnectAids    10: *integer                      #相邻的联盟id列表
        
        flagId  11: integer                                  #占领者联盟旗帜
        patternId  12: integer                               #占领者联盟旗帜模板
        colorId 13: integer                                  #占领者标志颜色
        customName 14: string                                #自定义名称

        initNpcId 21: integer                                #npcId 大于0时，表示占领npc
        curHpRate 22 : double                                # 当前血量比例

        declareWarAids 23: ComIntInt                         #宣战中联盟
        declareWarAbbNames 24: *string                       #宣战中联盟简称

        hasPlayerTroop 25: boolean                           #是否有玩家部队驻扎
    }

    .ComCampong {                                           #聚落
        campongId  0: integer                               #聚落id
        status  1: integer                                  #状态 0=未开启 1=保护状态 2=可争夺状态 3=报名 4=等待战斗 5=结束战斗
        statusEndTime  2: integer                           #当前状态结束时间
        occupyingAllianceId  3: integer                     #占领中的联盟id
        occupyingEndTime  4: integer                        #占领中结束时间
        initNpcId 5: integer                                #npc

        flagId 6: integer                                   #联盟旗帜
        patternId 7: integer                                #联盟旗帜模板
        colorId 8: integer                                  #标志颜色

        occupyingAllianceFullName 9: string                 #占领中的联盟名
        occupyingAllianceAbbName 10: string                 #占领中的联盟简称
        occupyingFlagId 11: integer                         #占领中的联盟旗帜
        occupyingPatternId 12: integer                      #占领中的联盟旗帜模板
        occupyingColorId 13: integer                        #占领中的标志颜色
    }

    .ComCapital {                                           #国王战建筑
        capitalId 0: integer                                #建筑id
        status  1: integer                                  #状态 MapBuildStatusType
        statusEndTime  2: integer                           #当前状态结束时间
        occupyingAllianceId  3: integer                     #占领中的联盟id
        occupyStartTime  4: integer                         #占领中的开始时间
        occupyEndTime  5: integer                           #占领中的结束时间
        initNpcId 6: integer                                #npc

        flagId 7: integer                                   #联盟旗帜
        patternId 8: integer                                #联盟旗帜模板
        colorId 9: integer                                  #标志颜色

        occupyingAllianceFullName 10: string                #占领中的联盟名
        occupyingAllianceAbbName 11: string                 #占领中的联盟简称
        occupyingFlagId 12: integer                         #占领中的联盟旗帜
        occupyingPatternId 13: integer                      #占领中的联盟旗帜模板
        occupyingColorId 14: integer                        #占领中的标志颜色

        uid 15: integer                                     #队长UID
        head 16: integer                                    #队长头像ID
        headFrame 17: integer                               #队长头像框ID
        nickName 18: string                                 #队长头昵称

        killNum 19 : integer                                #箭塔杀敌数量
        atkTs 20 : integer                                  #箭塔下次杀敌时间
        occupyKid 21: integer                               #占领联盟的kid ref-occupyingAllianceId
        kid 22: integer                                     #拥有联盟的kid ref-aid
        isCW 23: boolean                                    #是否跨服战
        occupyTotalTime 24 : integer                        #当前盟占领总时长
    }

    .ComBuffHoldOfAlliance {                                #据点
        flagId  0: integer                                  #占领者联盟旗帜
        patternId  1: integer                               #占领者联盟旗帜模板
        colorId 2: integer                                  #占领者标志颜色

        occupyingAllianceId  3: integer                     #占领中的联盟id
        occupyingAllianceFullName 4: string                 #占领中的联盟名
        occupyingAllianceAbbName 5: string                  #占领中的联盟简称
        occupyingFlagId  6: integer                         #占领中的联盟旗帜
        occupyingPatternId  7: integer                      #占领中的联盟旗帜模板
        occupyingColorId 8: integer                         #占领中的标志颜色

        initNpcId 9: integer                                #npc
        
        customName 14: string                                #自定义名称

    }

    .ComCampongOfAlliance {                                 #聚落
        flagId  0: integer                                  #占领者联盟旗帜
        patternId  1: integer                               #占领者联盟旗帜模板
        colorId 2: integer                                  #占领者标志颜色

        occupyingAllianceId  3: integer                     #占领中的联盟id
        occupyingAllianceFullName 4: string                 #占领中的联盟名
        occupyingAllianceAbbName 5: string                  #占领中的联盟简称
        occupyingFlagId  6: integer                         #占领中的联盟旗帜
        occupyingPatternId  7: integer                      #占领中的联盟旗帜模板
        occupyingColorId 8: integer                         #占领中的标志颜色

        initNpcId 9: integer                                #npc
        status 10: integer                                  #状态 MapBuildStatusType
        campongId  11: integer                              #聚落id
    }

    .ComCapitalOfAlliance {                                 #国王战建筑
        flagId  0: integer                                  #占领者联盟旗帜
        patternId  1: integer                               #占领者联盟旗帜模板
        colorId 2: integer                                  #占领者标志颜色

        occupyingAllianceId  3: integer                     #占领中的联盟id
        occupyingAllianceFullName 4: string                 #占领中的联盟名
        occupyingAllianceAbbName 5: string                  #占领中的联盟简称
        occupyingFlagId  6: integer                         #占领中的联盟旗帜
        occupyingPatternId  7: integer                      #占领中的联盟旗帜模板
        occupyingColorId 8: integer                         #占领中的标志颜色

        initNpcId 9: integer                                #npc
        status 10: integer                                  #状态 MapBuildStatusType
        isModifyAllianceInfo 11: boolean                    #是否修改联盟信息
    }

    .ComMonsterLair {                                       #怪物巢穴

    }

    .ComShadowTaskRobData {
        uid 0: integer                            # 掠夺者uid 
    }

    .ComShadowTaskData {                          # 暗影行动任务在场景对象数据
        taskId 0: uint32                          # 任务唯一 id
        cfgId 1: uint32                           # 任务配置id
        beRobTimes 2: *ComShadowTaskRobData(uid)  # 被掠夺次数
    }

    .ComShadowTaskData2 {                         # 暗影行动任务在场景对象数据
        cfgId 1: uint32                           # 任务配置id
    }

    .ComSceneAllianceFish {                                 # 联盟钓鱼宴会建筑
        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                              # 建筑状态

        flagId  5: integer                                  # 联盟旗帜
        patternId  6: integer                               # 联盟旗帜模板
        colorId 7: integer                                  # 标志颜色
    }

    .ComSceneAllianceFishTableGainUid {                    # 联盟钓鱼宴会餐桌建筑 玩家就餐数据
        uid 1: integer
        ress 2: *ComRes                                    # 获得的资源
    }

    .ComSceneAllianceFishTable {                            # 联盟钓鱼宴会餐桌建筑
        id 1: integer
        isAct 2: boolean
        sn 3: integer
        buildStatus 4: integer                              # 建筑状态

        flagId  5: integer                                  # 联盟旗帜
        patternId  6: integer                               # 联盟旗帜模板
        colorId 7: integer                                  # 标志颜色

        createTime 10: integer                              # 创建时间戳
        gainUids 11: *ComSceneAllianceFishTableGainUid(uid)
    }

    .ComSceneObj {
        id 0: integer
        isPack 100: boolean
        type 1: integer
        ownerId 2: integer
        x 3: double
        y 4: double
        aid 5: integer
        allianceFullName 6: string      #阵营全称 沙盘时为联盟名 副本中可能为其它名
        allianceAbbName 7: string       #阵营简称
        status 8: integer
        beSelected 9: boolean           #被部队选中为目标
        configId 10: integer            #对象配置id
        beRalliedCount 11: integer      #怪物正在集结的队伍数量
        stationTroopId 12: integer      #驻守部队id 服务器用
        serverId 13: integer            #原服务器id 副本中显示

        selectTroopCount 14: integer    #增援部队数量
        createUid 15: integer

        castle 50: ComCastle
        troop 51: ComTroop
        resource 52: ComResource
        allianceResource 53: ComAllianceResource
        buffHold 54: ComBuffHold
        allianceCenter 55: ComAllianceCenter
        allianceGuardTower 56: ComAllianceGuardTower
        village 57 : ComVillage
        campong 58 : ComCampong
        capital 59 : ComCapital
        radarGameRoom 60 : ComRadarGameRoom
        allianceAltar 61 : ComAllianceAltar
        allianceHonorBuild 62 : ComAllianceHonorBuild
        monsterLair 63 : ComMonsterLair
        allianceBlockMine 64 : ComAllianceBlockMine

        allianceNpcTrial 65 : ComAllianceNpcTrial

        scoreResource 66: ComScoreResource
        scoreWarehouse 67: ComScoreWarehouse
        scoreDrop 68:  ComScoreDrop

        sgvgBuild  69: ComSgvgBuild
        radarPve 70 : ComRadarPve
        radarMine 71 : ComRadarMine
        shadowTask 72: ComShadowTaskData

        allianceFish 73: ComSceneAllianceFish
        allianceFishTable 74: ComSceneAllianceFishTable
        blackGoldBuild 75: ComBlackGoldBuild
        blackGoldMine 76: ComBlackGoldMine
    }

    .ComSceneObj2 {
        id 0: integer
        isPack 100: boolean
        type 1: integer
        ownerId 2: integer
        x 3: double
        y 4: double
        aid 5: integer
        allianceAbbName 7: string       #阵营简称
        status 8: integer
        configId 10: integer            #对象配置id
        serverId 13: integer           #原服务器id 副本中显示
        castle 50: ComCastle2
        troop 51: ComTroop2
        allianceCenter 55: ComAllianceCenter2
        allianceGuardTower 56: ComAllianceGuardTower2
        resource 52: ComResource2
        shadowTask 72: ComShadowTaskData2
    }

    .ComSceneObj3 {
        id 0: integer
        isPack 100: boolean
        type 1: integer
        x 3: double
        y 4: double
        aid 5: integer
        configId 10: integer            #对象配置id
        castle 50: ComCastle3
        resource 52: ComResource2
        shadowTask 72: ComShadowTaskData2
    }

    .ComSceneObj4 {
        id 0: integer
        isPack 100: boolean
        type 1: integer
        x 3: double
        y 4: double
        aid 5: integer
        configId 10: integer            #对象配置id
        castle 50: ComCastle3
    }

    .ComSceneObj5 {
        id 0: integer
        isPack 100: boolean
        type 1: integer
        x 3: double
        y 4: double
        aid 5: integer
        configId 10: integer            #对象配置id
        castle 50: ComCastle3
    }

    .ComTroopBattleInfo {
        anger 2: integer
        buffCfgIds 3: *integer
    }

    .ComTroopCorpInfo {                             #集合部队信息:集结部队，建筑驻防部队集合
        leaderTroopId 1 : integer		            #队长ID
        troopIds 2 :  *ComIntInt()                  #部队列表
        uid2TroopId 3 :  *ComIntInt()               #uid2troopId
    }

    #战争面板
    .ComBattlePanelInfo {
        id              0 : integer             #索引id
        battlePanelType 1 : integer             #类型 1 集结 2 个人
        attackTroop 2 : ComBattleTroopInfo		#进攻方部队
        attackTarget 3: ComSceneObj             #进攻目标
        defendTroop 4 : ComBattleTroopInfo		#防守方部队
    }

    # 联盟简要信息
    .ComAllianceBrief {
        aid 0: integer                          # 联盟id
        fullName 1: string                      # 联盟全称
        abbName 2: string                       # 联盟简称
        flagId 3: integer                       # 联盟旗帜
        patternId 4: integer                    # 联盟旗帜模板
        colorId 5: integer                      # 标志颜色
    }

    # 联盟领地建筑信息
    # .ComBuildOfAllianceTerr {
    #     x 0: integer                          # x坐标
    #     y 1: integer                          # y坐标
    #     isAct 2: boolean                      # 是否激活
    #     sn 3: integer                         # 序列号
    #     cfgId 4: integer                      # 配置id
    # }

    # 联盟领地信息
    .ComAllianceTerr {
        aid 0: integer                          # 联盟id
        color 1: integer                        # 联盟领地颜色
        builds 2: *integer                      # 联盟领地建筑信息 (sn << 33) + (bid << 23) + (isAct << 22) + (x << 11) + y
        allianceFullName 3: string              # 阵营全称 沙盘时为联盟名 副本中可能为其它名
        allianceAbbName 4: string               # 阵营简称
    }

    # 联盟领地变化信息
    .ComAllianceTerrChange {
        aid 0: integer                          # 联盟id
        color 1: integer                        # 联盟领地颜色
        news 2: *integer                        # 新建建筑 (sn << 33) + (bid << 23) + (isAct << 22) + (x << 11) + y
        changes 3: *integer                     # 变化建筑 (sn << 33) + (bid << 23) + (isAct << 22) + (x << 11) + y
        removes 4: *integer                     # 删除建筑 (sn << 33) + (bid << 23) + (isAct << 22) + (x << 11) + y
        allianceFullName 5: string              # 阵营全称 沙盘时为联盟名 副本中可能为其它名
        allianceAbbName 6: string               # 阵营简称
    }

    # 场景建筑信息
    .ComSceneBuild {
        id 0: integer                           # 建筑id
        type 1: integer                         # 建筑类型
        x 2: integer                            # 建筑坐标x
        y 3: integer                            # 建筑坐标y
        configId 4: integer                     # 建筑配置id
        aid 5: integer                          # 联盟id
        allianceFullName 6: string              # 阵营全称 沙盘时为联盟名 副本中可能为其它名
        allianceAbbName 7: string               # 阵营简称
        buffHold 54: ComBuffHoldOfAlliance
        campong 58 : ComCampongOfAlliance       # 聚落
        capital 59 : ComCapitalOfAlliance       # 王战建筑
    }

    # 场景建筑变化信息
    .ComSceneBuildChange {
        news 0: *ComSceneBuild(id)
        changes 1: *ComSceneBuild(id)
        removes 2: *integer
    }

    # 预警信息
    .ComWarningInfo {
        srcTroopId   0: integer		            # 用作key
        srcTroop     1: ComBattleTroopInfo		# 发起预警的部队
        waringType   2: integer                 # 类型 enum:WarningType
        time         3: integer                 # 生成时间
        ##scoutLevel   4: integer                 # 实际侦察等级 不处理中途变化
    }

    # 自动集结怪物信息
    .ComAutoRallyBossInfo {
        npcSubType      0: integer		            # 怪物子类型
        prizeCount      1: integer		            # 奖励已领取次数
        prizeMaxCount   2: integer		            # 奖励次数上限
    }


    # 地图标记坐标
    .ComMarkCoordinateData {
        text            0: string                   # 标记文本
        labelType       1: integer                  # 标签类型
        sceneId         2: integer                  # 服务器id改成sceneId
        x               3: integer                  # x坐标
        y               4: integer                  # y坐标
        timestamp       5: integer                  # 标记（更新）时间戳
    }

    # 地图标记坐标
    .ComMarkCoordinates {
        key 0 : string                               # 标记坐标key
        markCoordinateData 1 : ComMarkCoordinateData # 标记坐标数据
    }
]]

sceneProto.c2s = sceneProto.struct .. [[

addTroop 41 { #出征
    request {
        army 0: *ComArmyIdAndNum()
        targetId 2: uint64
        targetX 3: double
        targetY 4: double
        heros 5: *ComUint32Uint32()
        isRally 6: boolean               #是否开启集结 发起集结
        rallyReadyMinutesIndex 7: uint32  #集结准备时间索引
        isScout 8: boolean                 #是否是斥候
        isRadar 9: boolean                 #是否是雷达交互部队
        rallyAutoGo 10: boolean            #是否集结人满后立即出发
        helpUids 11: *uint64             #怪物试炼协助队列
        isAutoBack 12: boolean               #是否战斗后自动返回
        formationId 13: uint32              # 编队Id
        attackTimes 14: uint32              # 打中立建筑时设置攻击次数
    }
    response {
        troopId 1: uint64                 #部队id
    }
}

moveCastle 42 {                         #1 定点迁城 2 随机迁城 3 领地迁城 4 新手buff联盟迁城
    request {
        x 0: uint32
        y 1: uint32
        resExchanges 3: *ComUint32Uint32()        #购买并使用定点迁城道具(道具id->数量为1) [240005] = 1
        items2use 4: *ComUint32Uint32()           #使用定点迁城道具(道具id->数量为1) [240005] = 1
        moveType 5:uint32                  # 1 定点迁城 2 随机迁城 3 领地迁城 4 新手buff联盟迁城 5 跨服战随机迁城
        itemId 6:uint32                    # itemId(物品流水id 2、3、4（无新手buff）时必填)
        newServerId 7: uint32              # 迁入服ID (跨服迁城时传)
    }
    response {
    }
}

setAoiPos 43 {
    request {
        x 0: uint32
        y 1: uint32
        lod 2: uint32
        sceneId 3: uint64                    # 64位场景id
    }
    response {
    }
}

enterScene 46 {
    request {
        sceneId 0: uint64
    }
    response {
    }
}

quitScene 47 {
    request {
    }
    response {
    }
}

findSceneObj 48 {                       #搜索场景对象
    request {
        objType  0:uint32              #对象类型
        objCfgId 1:uint32              #对象配置id 如果是怪物 资源点 需要传配置id
        isIncludeOccupyRes 3:boolean    #是否包含已占领矿 true：包含 false:不包含
        isRadar 4 :boolean              #搜索雷达对象
        objIds 5:*uint64               #客户端已有对象id列表 用于继续搜索时比对
        isFullRes  6 :boolean           #搜索资源为满的资源点
        scoreResourceLv 7: uint32       #pvp副本积分矿等级123
        onlySelfSummon 8: boolean       #是否自己召唤的
    }
    response {
        objs     0: *ComSceneObj        #对象列表
    }
}

callbackTroop 49 {                      #集结解散
    request {
        id 0:uint64                    #部队id
        ##resExchanges 1: *ComUint32Uint32()    #购买并使用召回道具(道具id->数量为1)
        ##items2use 2: *ComUint32Uint32()       #使用召回道具(道具id->数量为1)
    }
    response {
    }
}

troopSpeedUp 50 {                           #部队加速
    request {
        id 0:uint64                        #部队id
        resExchanges 1: *ComUint32Uint32()        #购买并使用加速道具(道具id->数量为1)
        items2use 2: *ComUint32Uint32()           #使用加速道具(道具id->数量为1)
    }
    response {
    }
}

rallyTroopInvite 51 {                       #集结邀请
    request {
        rallyTroopId 0:uint64              #集结部队id
        inviteUIds 1: *uint32              #邀请玩家uid列表
    }
    response {
    }
}

troopRepatriate 52 {                   #集结遣返 增援遣返 联盟建筑遣返
    request {
        rallyTroopId 0:uint64              #集结部队id 如果是增援遣返不填这个字段
        repatriateTroopId 1: uint64        #遣返部队id
        repatriateType 2: uint32           #遣返类型 1 集结遣返 2 城堡增援遣返 3 联盟中立建筑遣返
    }
    response {
    }
}

getBattlePanelInfo 53 {                   #获取战争面板详细信息
    request {
        id              0 : uint64         #索引id
        attackTroopId   1 : uint64         #攻击部队id
        defendTroopId   2 : uint64         #防守部队id
    }
    response {
        battlePanelInfo 0: ComBattlePanelInfo
    }
}

getTroopDetailInfo 54 {                         #获取预警界面部队详情
    request {
        troopId          0: uint64             #部队id
    }
    response {
        troopInfo        0: ComBattleTroopInfo  #部队详情
        relation         1: integer             #和自己的关系 2,友方  3,敌方
        ##scoutLevel       2: integer             #侦察等级
    }
}

getObjDetailInfo 55 {                          #获取对象详情 主要用于查询建筑类对象
    request {
        objId           0: uint64              #id
    }
    response {
        obj             0: ComSceneObj          #对象详情
        troopInfo       1: ComBattleTroopInfo   #驻防部队信息
        playerCapacity  2: integer              #驻防人数上限
        armyCapacity    3: integer              #驻防兵数上限
        troopId2BuildHonorSpeed 4:  *ComIntInt() #驻防部队建造荣誉值速度
        troopId2StartBuildTime 5:  *ComIntInt()  #开始建造时间
        endBuildTime    6:  integer              #联盟建筑建造完成时间
        troopCollectInfo 7: *ComTroopCollectInfo(troopId) #联盟积木矿采集信息
    }
}

getMoveCastlePos 56 {                           #获取联盟迁城和领地迁城坐标
    request {
        itemId 0: uint32                       # itemId(每个玩家的物品id唯一 如果为0表示新手联盟迁城buff)
    }
    response {
        x 0: integer                            # x坐标
        y 1: integer                            # y坐标
    }
}

getScoutTargetRecord 57 {                       # 获取最近侦察目标时间和邮件id
    request {
        targetId 0: uint64                     # 目标id
    }
    response {
        time 0: integer                         # 时间
        mailId 1: integer                       # 邮件id
        labelId 2: integer                      # 标签id
    }
}



getAutoRallyInfo 58 {                                  # 获取自动集结信息
    request {
    }
    response {
        expiredTime 0: integer                          # 自动集结结束时间
        order       1: integer                          # 当前位置
        addTroopType 2: integer                          # 派兵类型 0 全兵加入 1 使用编队
        selectedBoss 3: *integer                         # 已勾选怪物ID
        bossInfo    4: *ComAutoRallyBossInfo(npcSubType) # 可集结怪物
        isUsePsItem  5: boolean                           # 是否自动使用体力道具 true 使用   false不使用
        maxPsbyUseItem 6: integer                        # 最大获得值 自动使用体力道具
        usedPs 7: integer                                # 已使用体力

    }
}

setAutoRallyInfo 59 {                                   # 设置自动集结
    request {
        isOpen 0: boolean                               # true 开启   false关闭
        addTroopType 1: uint32                          # 派兵类型 0 全兵加入 1 使用编队
        selectedBoss 2: *uint32                         # 已勾选怪物ID
        isUsePsItem 3: boolean                           # 是否自动使用体力道具 true 使用   false不使用
        maxPsbyUseItem 4: uint32                        # 最大获得值 自动使用体力道具
    }
    response {
        expiredTime 0: integer                          # 自动集结结束时间
        order       1: integer                          # 当前位置
        addTroopType 2: integer                          # 派兵类型 0 全兵加入 1 使用编队
        selectedBoss 3: *integer                         # 已勾选怪物ID
        isUsePsItem 4: boolean                           # 是否自动使用体力道具 true 使用   false不使用
        maxPsbyUseItem 5: integer                        # 最大获得值 自动使用体力道具
    }
}

getBuffHoldList 60 {                                   # 获取据点信息 已成功占领的据点建筑 和 可争夺的据点建筑
    request {
    }
    response {
        buffHolds           0: *ComSceneObj              #已占领据点对象列表
        forwardBuffHold     1: ComSceneObj               #暂未控制任何据点时显示前往争夺据点
        canOccupyBuffHolds  2: *ComSceneObj              #可占领据点对象列表
        cannotOccupyBuffHolds 3: *ComSceneObj            #不可占领据点对象列表
    }
}


ignoreWarning 61 {                                       #忽略预警
    request {
        warningTroopId 1: uint64                        #单独忽略的预警id
        ignoreAll 2: boolean                             #全部忽略
    }
    response {
    }
}

finishRadarGame 62 {                                     #完成雷达拼接游戏
    request {
        sceneObjId 1: uint64                            #雷达拼接建筑id
    }
    response {
    }
}

markCoordinate 63 {                                     # 标记坐标
    request {
        text 0: string                                  # 标记文本
        labelType 1: uint32                            # 标签类型
        sceneId 2: uint64                              # sceneId (64位场景id)
        x 3: uint32                                    # x坐标
        y 4: uint32                                    # y坐标
    }
    response {
    }
}

unmarkCoordinate 64 {                                   # 取消标记坐标
    request {
        markKeys 0: *string                             # key列表
    }
    response {
    }
}

getAllAllianceTerrDataOfAoi 65 {                        # 获取联盟领地数据
    request {
        serverId 0: uint32                             #服务器id
    }
    response {
    }
}

getAllSceneBuildDataOfAoi 66 {                          # 获取场景中立建筑数据
    request {
        serverId 0: uint32                             #服务器id
    }
    response {
    }
}

getWarningInfo 67 {                   #获取预警详细信息
    request {
        srcTroopId              0 : uint64         #索引id
    }
    response {
        warningInfo 0: ComWarningInfo
    }
}

getCanOccupyAllianceResources 68 {     # 获取本联盟领土范围内可攻打的联盟资源点
    request {
    }
    response {
        allianceResourceRefIds      0: *integer   #allianceResourceRef id列表
    }
}


autoKillMonster 69 {                              # 自动打怪
    request {
        minNpcLv 1: uint32                        # 自动打怪的最小等级
        maxNpcLv 2: uint32                        # 自动打怪的最大等级
        isUsePsItem 3: boolean                    # 是否自动使用体力道具
        army 6: *ComArmyIdAndNum()                # 士兵
        heros 7: *ComIntInt()                     # 英雄列表
    }
    response {
        troopId           0 : uint64              # 部队id
        getPs             1 : uint32              # 本次使用体力道具获得的体力
    }
}


getHelpTroops 70 {                                # 查询协助部队信息
    request {
        troopId           0 : uint64              # 部队id
    }
    response {
        troopInfo        0: ComBattleTroopInfo    #部队详情
    }
}

getSpvpScoreResourceList 76 {                     # pvp副本占领的矿点列表
    request {
    }
    response {
        scoreResourceList  0: *ComSceneObj        # 已占领的矿点列表
    }
}

changeWorld 77 {                                  # 跨服迁城(测试用)
    request {
        serverId 0: uint32
    }
    response {
    }
}

setTroopTarget 78 {                               # 设置部队目标
    request {
        id 0:uint64
        targetId 1: uint64
        targetX 2: double
        targetY 3: double
        isAutoBack 12: boolean               #自由行军过程中设置战斗后是否自动返回
        attackTimes 13:uint32               # 打中立建筑时设置攻击次数
    }
    response {
    }
}

gmSetTroopSpeed 79 {                               # GM加速
    request {
        id 0:uint64
        speed 1: uint32
    }
    response {
    }
}

]]

sceneProto.s2c = sceneProto.struct .. [[

syncEnterScene 60 {
    request {
        sceneId 0: integer      # 当前场景id
        serverId 1: integer     # 当前服务器id
        moveType 2: integer     # 迁城类型
    }
}

syncEnterSceneFinish 51 {
    request {
    }
}

syncAoiUpdateData 61 {
    request {
        newSceneObjs 1: *ComSceneObj
        removeSceneObjIds 3: *integer
        isFirstEnter 4: boolean                         #是否首次进入
        isEnd 5: boolean                                #是否最后一个包
        sceneId 6: integer                             #服务器id改成sceneId
    }
}

syncAoiUpdateData2 62 {
    request {
        newSceneObjs 1: *ComSceneObj2
        removeSceneObjIds 3: *integer
        isFirstEnter 4: boolean                         #是否首次进入
        isEnd 5: boolean                                #是否最后一个包
        sceneId 6: integer                             #服务器id改成sceneId
    }
}

syncAoiUpdateData3 63 {
    request {
        newSceneObjs 1: *ComSceneObj3
        removeSceneObjIds 3: *integer
        isFirstEnter 4: boolean                         #是否首次进入
        isEnd 5: boolean                                #是否最后一个包
        sceneId 6: integer                             #服务器id改成sceneId
    }
}

syncAoiUpdateData4 64 {
    request {
        newSceneObjs 1: *ComSceneObj4
        removeSceneObjIds 3: *integer
        isFirstEnter 4: boolean                         #是否首次进入
        isEnd 5: boolean                                #是否最后一个包
        sceneId 6: integer                             #服务器id改成sceneId
    }
}

syncAoiUpdateData5 65 {
    request {
        newSceneObjs 1: *ComSceneObj5
        removeSceneObjIds 3: *integer
        isFirstEnter 4: boolean                         #是否首次进入
        isEnd 5: boolean                                #是否最后一个包
        sceneId 6: integer                             #服务器id改成sceneId
    }
}

showGeneralTips 66 {                                    #通用提示
    request {
        generalTipsId 1: integer
        params 2:*string                                #参数列表
    }
}


syncAddSceneObj 70 {
    request {
        sceneObj 0: ComSceneObj
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncAddSceneObj2 71 {
    request {
        sceneObj 0: ComSceneObj2
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncAddSceneObj3 72 {
    request {
        sceneObj 0: ComSceneObj3
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncAddSceneObj4 73 {
    request {
        sceneObj 0: ComSceneObj4
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncAddSceneObj5 74 {
    request {
        sceneObj 0: ComSceneObj5
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateSceneObj 80 {
    request {
        sceneObj 0: ComSceneObj
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateSceneObj2 81 {
    request {
        sceneObj 0: ComSceneObj2
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateSceneObj3 82 {
    request {
        sceneObj 0: ComSceneObj3
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateSceneObj4 83 {
    request {
        sceneObj 0: ComSceneObj4
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateSceneObj5 84 {
    request {
        sceneObj 0: ComSceneObj5
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncRemoveSceneObj 90 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncRemoveSceneObj2 91 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncRemoveSceneObj3 92 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncRemoveSceneObj4 93 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncRemoveSceneObj5 94 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncTroopMovePath 100 {
    request {
        id 0: integer
        moving 1: boolean
        path 7: *ComPath
        startWalkRate 8: double
        startWalkRateTS 9: double
        showLine 17:boolean
        sceneId 18: integer                            #服务器id改成sceneId
    }
}


syncRemoveSelfTroop 103 {
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncTroopEnterBattle 110 {                              #进入战斗
    request {
        id 0: integer                                   #部队id
        inBattle 1: boolean                             #进入战斗
        sceneId 2: integer                             #服务器id改成sceneId
    }
}

syncTroopBattleResult 111 {                             #战斗结果
    request {
        id 0: integer                                   #部队id
        isAttacker 2: boolean                           #是否为攻击方
        isWin   3: integer                              #是否胜利 0 失败 1 胜利 2 平
        sceneId 4: integer                             #服务器id改成sceneId
    }
}

syncWarning 121 {
    request {
        news 1: *ComWarningInfo(srcTroopId)
        changes 2: *ComWarningInfo(srcTroopId)
        removes 3: *integer
        sceneId 4: integer                             #服务器id改成sceneId
    }
}


recvRallyTroopInvite 122 {                              #收到集结邀请
    request {
        uid          0:integer                          #邀请者uid
        rallyTroopId 1:integer                          #集结部队id
        sceneId 2: integer                             #服务器id改成sceneId
    }
    response {
    }
}

recvTroopRepatriate 123 {                               #集结遣返
    request {
        rallyUId 0:integer                              #集结者uid
        sceneId 1: integer                             #服务器id改成sceneId
    }
    response {
    }
}

#您的城堡被其他领主摧毁了，城防值已经降为“0”。系统自动随机帮你选择了一处地点重建城市
ntyAutoMoveCity 124 {                                   #自动迁城通知
    request {
        isOnline 0:boolean                              #是否在线 true 在线 false 刚登录
        x 1: integer                                    #新城坐标x
        y 2: integer                                    #新城坐标y
        autoMoveType 3: integer                         #自动迁城类型 0被打飞 1 从王城警戒区自动迁走 2 很久不上线被迁走 3=跨服战系统遣返 4 加入联盟自动迁城
    }
    response {
    }
}


moveToViewPos 125 {                                     #切换视角到指定位置 召唤怪物
    request {
        x 0: uint32
        y 1: uint32
        type 2: uint32                              #对象类型
    }
    response {
    }
}

#战争面板信息
syncBattlePanelInfos 130 {                              #登录时同步所有战争面板信息
    request {
        battlePanelInfos 0: *ComBattlePanelInfo(id)
        autoRallyExpiredTime 1: integer                 #自动集结结束时间
        sceneId 2: integer                              #服务器id改成sceneId
        isFirstEnter 3: boolean                         #是否首次进入
        isEnd 4: boolean                                #是否最后一个包
    }
    response {
    }
}


syncAddBattlePanelInfo 131 {                            #增加战争面板信息
    request {
        battlePanelInfo 0: ComBattlePanelInfo
        sceneId 1: integer                             #服务器id改成sceneId
    }
}

syncUpdateBattlePanelInfo 132 {                         #更新战争面板信息
    request {
        battlePanelInfo 0: ComBattlePanelInfo
        sceneId 1: integer                             #服务器id改成sceneId
    }
    response {
    }
}

syncRemoveBattlePanelInfo 133 {                         #删除战争面板信息
    request {
        id 0: integer
        sceneId 1: integer                             #服务器id改成sceneId
    }
    response {
    }
}

syncUpdateBattlePanelDefendInfo 134 {              #更新战争面板信息
    request {
        battlePanelIds 0 : *integer                     #战争面板id列表
        defendTroop 1 : ComBattleTroopInfo		        #防守部队信息
        sceneId 2: integer                              #服务器id改成sceneId
        attackTarget 3: ComSceneObj                     #进攻目标
    }
    response {
    }
}



syncAllAllianceTerr 140 {                               #同步联盟领地信息
    request {
        allianceTerr 0: ComAllianceTerr
        sceneId 2: integer                             #服务器id改成sceneId
    }
    response {
    }
}

syncAllianceTerrChange 141 {                            #同步联盟领地变化信息
    request {
        allianceTerr 0: ComAllianceTerrChange
        sceneId 2: integer                             #服务器id改成sceneId
    }
    response {
    }
}

syncAllSceneBuild 145 {                                 #同步场景建筑信息
    request {
        builds 0: *ComSceneBuild(id)
        sceneId 2: integer                             #服务器id改成sceneId
    }
    response {
    }
}

syncAllSceneBuildChange 146 {                           #同步场景建筑变化信息
    request {
        builds 0: ComSceneBuildChange
        sceneId 2: integer                             #服务器id改成sceneId
    }
    response {
    }
}

showStrongholdWarWin 147 {                              #据点首占奖励弹窗
    request {
        strongholdId 0: integer
        aid 1: integer  #联盟id
        abbName 2: string    #联盟简称
        fullName 3: string   #联盟名称
        dropId 5: integer     # 掉落ID
    }
}

ntyMoveCastle 148 {                                    #准备迁城通知 客户需求
    request {
    }
}

# 部队停止(1、客户端请求停止部队2、部队到达目的地)
syncTroopStop 149 {
    request {
        id 0: integer
        curX 1: double
        curY 2: double
        dir 3: integer
        moving 4: boolean
    }
}

# 部队离开战斗
syncTroopLeaveBattle 150 {
    request {
        id 0: integer                                   # 部队ID
    }
}

# 部队释放技能(主动技能,skillType=2)
syncTroopCastSkill 151 {
    request {
        id 0: integer               # 部队ID
        heroCfgId 1: integer        # 释放技能的英雄配置ID
        skillCfgId 2: integer       # 释放的技能配置ID
        targetIds 3: *integer       # 目标ID列表
        castTarget 4: integer       # 施法目标
        dmg 5: integer              # 伤害值
        isCirt 6: boolean           # 是否暴击
    }
}

# 部队受到伤害用来飘血(主动技能的伤害单独同步,受到的普通伤害和反击伤害合并同步)
syncTroopHurt 152 {
    request {
        id 0: integer               # 部队ID
        hurt 1: integer             # 伤害值
        skillCfgId 2: integer       # 技能配置ID
        isCirt 3: boolean           # 是否暴击
        curHpRate 4: double         # 当前血量比例
    }
}

syncTroopArmy 153 {
    request {
        id 0: integer
        army 1: *ComArmyIdAndNum()
        truceArmy 2: *ComArmyIdAndNum()
    }
}

# 部队死亡
syncTroopDeaded 154 {
    request {
        id 0: integer               # 部队ID
    }
}

# 部队怒气变化
syncAngerChange 155 {
    request {
        id 0: integer               # 部队ID
        anger 1: integer            # 当前怒气值
    }
}

# 部队传送到攻击位置
syncTeleportToAttackPos 156 {
    request {
        id 0: integer               # 部队ID
        posX 1: double             # 当前X坐标
        posY 2: double             # 当前Y坐标
    }
}

]]

return sceneProto
