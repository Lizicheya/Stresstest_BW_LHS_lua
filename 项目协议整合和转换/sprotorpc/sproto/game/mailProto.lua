-- 邮件模块 1300~1400
local mailProto = {}

mailProto.struct = [[
    .ComMailAppendixItem {
        type 0:integer              # 资源类型
        cfgId   1:integer           # 资源ID
        num   2:integer             # 资源数量
    }
    .ComMailRewardInfo {
        id   1 : integer                         # 邮件ID
        appendix  2 : *ComMailAppendixItem       # 附件
    }

    .ComMailLabelUnread {
        labelType   1 : integer                  # 页签类型
        count   2 : integer                      # 未读数量
        allianceRank2num 0: *ComUint32Uint32()   # 未读邮件的邮件额外信息中 联盟职位信息
        readUnGetCount 3 : integer               # 已读未领取奖励的数量
    }

    .ComMailUnread {
        allCount 0: integer                     # 总数
        labelList 1: *ComMailLabelUnread        # 未读数列表
    }

    .ComMailAllianceOptions {
        aid 0: integer                          # 联盟ID
        operateUid 1: integer                   # 操作者 uid 业务的逻辑触发者是玩家的话 记录下玩家 uid
        operateRank 2: integer                  # 操作者 uid 存在的话 该玩家在联盟中的等级
    }

    .ComMailOptions {                           # 邮件额外信息 可能会无数据 要先判断 key 存在
        alliance 0: ComMailAllianceOptions      # 联盟相关邮件选项
    }

    .ComMailInfo {
        id   1 : integer                         # 邮件ID
        readFlag 2 : integer                     # 已读标记
        getFlag  3 : integer                     # 已领取标志
        appendixFlag 4 : integer                 # 是否有附件(0没有,1有)
        data1 5 : integer                        # 附带数据1(最大255)
        mailType 6 : integer                     # 对应配置表的邮件ID
        mailShowData 7 : ComMailShowData         # 展示数据
        createTime   8 : integer                 # 时间
        appendix  9 : *ComMailAppendixItem       # 附件
        mailOptions 10 : ComMailOptions          # 邮件额外信息
    }

    .ComActFishAllianceRewardMailData {
        tableCfgId 0: integer # 餐桌配置id
    }

    .ComMailKingWarRoyalMail {
        title 0: string          # 邮件标题
        content 1: string        # 邮件内容
    }

    #发送给客户端的邮件内容
    .ComMailShowData {
        welCome 0: ComMailUniversal              #欢迎邮件
        collects 1: *ComMailCollectResource        #采集
        battleReport 2: ComMailBattleReportShowData      #战报
        buildUpgrade 3: ComMailBuildUpgrade      #建筑升级奖励
        radarInteraction 4: ComMailRadarInteraction #雷达的交互事件
        scoutReport 5: ComMailScoutReport        #侦察报告
        beScouted 6: ComMailBeScouted            #被侦察邮件
        welcomeJoinAlliance 7: ComMailWelcomeJoinAlliance #加入联盟邮件
        allianceDonateRank 8: ComAllianceDonateRank #联盟捐献排行榜
        transferLeader 9: ComMailTransferLeader  #盟主变化
        rankChange 10: ComMailRankChange        # 职位变化
        hospitalAlreadyFull 11: ComHospitalAlreadyFull #医院爆仓
        positionChange 12: ComMailPositionChange        # 官职变化
        beKickAlliance 13: ComMailBeKick        # 联盟被踢邮件
        allianceName 14: ComMailALName        # 联盟邮件联盟名称
        inviteInfo 15: ComMailALInviteInfo        # 邀请邮件邀请人、联盟名称
        firstOwnHold 16: ComMailFirstOwnHold      # 据点首占奖励
        ownHold 17: ComMailOwnHold                # 据点占领邮件
        monsterLost 18: ComMailMonsterLost        # 怪物丢失邮件
        campongWarDivide 19: ComMailCampongWarDivideReward #聚落战争分配奖励
        campongRegist 20: ComMailCampongWarRegistList #聚落战争报名邮件
        campongWarKillReward 21: ComMailCampongWarKillReward #聚落战争击杀邮件
        campongWarOccupyReward 22: ComMailCampongWarOccupyReward #聚落战争占领邮件
        campongWarOccupyPoint 23: ComMailCampongWarOccupyPoint #聚落战争占领积分
        campongWarSeasonReward 24: ComMailCampongWarSeasonReward #聚落战争赛季奖励
        tideSuccessReward 25: ComTideSuccessReward #潮汐胜利奖励
        commonRank 26: ComCommonRank            # 通用排行榜
        gm 27: ComGmMail                        # gm邮件
        commonActReward 28: ComActReward       # 通用活动奖励补发邮件
        targetLost 29: ComMailTargetLost        # 目标丢失邮件
        epicRecruitReward 30: ComEpicRecruitActReward #史诗招募活动奖励
        actContinuousReward 31: ComActContinuousReward # 连续充值活动档位奖励发放
        bossHarmRankReward 32: ComHarmRankReward # 世界boss伤害排名奖励邮件
        rallyDissolution 33: ComMailRallyDissolution # 集结主动解散邮件
        markInfo 34: ComAllianceMarkMail # 联盟标记邮件
        siegeReserve 35: ComSiegeReserve # 怪物攻城预约邮件
        siegeStart 36: ComSiegeStart # 怪物攻城开启邮件
        siegeStageReward 37: ComSiegeStageReward # 怪物攻城阶段奖励
        altarDamageNum 38: ComAltarDamageNum # 联盟神兽伤害次数上限
        altarReward 39: ComAltarReward # 联盟神兽奖励
        allianceGroupMail 40: ComAllianceGroupMail # 联盟群发邮件
        siegeFail 41: ComSiegeFailMail # 怪物攻城失败次数邮件
        privilegeCard 42: ComMailPrivilegeCard # 特权卡邮件
        shiledCastle 43: ComMailShiledCastle # 保护罩邮件 侦查失败 阻止侦查 进攻失败 阻止进攻
        dismantleBuild 44: ComDismantleBuildMail # 主动拆除建筑邮件
        removedBuild 45: ComRemovedBuildMail # 被拆除建筑邮件
        attackHoldBoss 46: ComMailAttackHoldBoss  # 据点参与击杀守军奖励 
        kingWarDivide 47: ComMailKingWarDivide  # 王战分配奖励
        kingWarRank 48: ComMailKingWarRank  # 王战排行奖励
        kingWarScore 49: ComMailKingWarScore  # 王战积分奖励
        kingWarEnd 50: ComMailKingWarEnd  # 王战结束
        kingWarKing 51: ComMailKingWarKing  # 王战国王登基
        kingWarOfficial 52: ComMailKingWarOfficial  # 王战国王官职任命
        kingWarNotice 53: ComMailKingWarNotice  # 王战国王公告
        altarDamageValue 54: ComMailAltarDamage  # 联盟神兽伤害
        buildBlockMine 55: ComMailBuildBlockMine  # 放置联盟积木矿
        addBlockMine 56: ComMailAddBlockMine  # 联盟积木矿建造完成

        payDeliver 57: ComMailPayDeliver  # 支付发货
        altarReserve 58: ComMailAltarReserve # 联盟神兽预约
        arenaReward 59: ComMailArenaReward # 竞技场奖励
        kingWarArmyDead 60: ComMailKingWarArmyDead # 王战士兵死亡
        campongWarKillNpc 61: ComMailCampongWarKillReward #聚落战争击杀npc奖励邮件
        massacre 62: ComMailMassacre # 大屠杀邮件
        kingWarArrowAtk 63: ComMailKingWarArmyDead # 箭塔攻击
        npcTrialPlyAward 64: ComNpcTrialPlyAward # 联盟怪物试炼个人档位奖励邮件
        npcTrialAliAward 65: ComNpcTrialAliAward # 联盟怪物试炼联盟档位奖励邮件

        peakArenaRankReward 66: ComPeakArenaRankReward #巅峰竞技场排名奖励
        gm2 67: ComGmMail2                        # gm礼包邮件
        peakArenaJoin 68: ComPeakArenaJoin #巅峰竞技场参与邮件

        seasonPvpScore 69: ComMailSeansonPvpScore # 赛季pvp个人积分奖励

        seasonPvpPickUpScore 70:ComMailSeasonPvpPickUpScore # 赛季pvp拾取积分
        crossWarRank 71: ComMailKingWarRank  # 跨服战个人排行奖励
        crossWarALiRank 72: ComMailKingWarRank  # 跨服战联盟排行奖励
        crossWarOpen 73: ComMailCrossWarOpen  # 跨服战开启
        crossWarScore 74: ComMailKingWarScore  # 跨服战积分奖励
        beKing 75: ComMailBeKing  # 王战/跨服战成为国王
        crossWarKing 76: ComMailCrossWarKing  # 跨服战国王登基
        crossWarOfficial 77: ComMailCrossWarOfficial  # 跨服战国王官职任命
        crossWarDivide 78: ComMailCrossWarDivide  # 跨服战分配奖励
        opinionBox 79: ComMailOpinionBox # 民意评价奖励
        hospitalWillFull 80: ComHospitalWillFull # 医院即将爆仓
        invasionBossStageAward 81: ComInvasionBossStageReward # 暴君降临伤害档位奖励
        invasionBossAttackNumAward 82: ComInvasionBossAttackNumReward # 暴君降临攻击次数奖励
        strongholdStageAward 83: ComStrongHoldStageReward # 据点首占个人战功档位奖励
        strongholdDeclareWar 84: ComStrongHoldDeclareWar # 据点预约宣战
        strongholdGiveUp 85: ComStrongHoldGiveUp # 放弃据点
        strongholdOccupyRemove 86: ComStrongHoldOccupyRemove # 据点占领预约宣战移除
        placeAlliancePoint 87: ComPlaceAlliancePoint # 放置联盟集合点
        championshipRecyle 88: ComChampionshipRecycle # 冠军对决狂欢道具回收邮件
        championshipRank 89: ComChampionShipRank # 冠军对决排行奖励邮件
        actFishAllianceReward 90: ComActFishAllianceRewardMailData # 钓鱼联盟宴会奖励邮件

        kingWarRoyalMail 91: ComMailKingWarRoyalMail # 王战国王服务器邮件
        strongholdAllianceAward 92: ComStrongholdAllianceAward # 据点联盟战功奖励邮件
    }

    #通用内容(不带任何参数)
    .ComMailUniversal {
    }

    #采集
    .ComMailCollectResource {
        endCollectTime   1 : integer              # 时间
        posX             2 : integer              # 地点
        posY             3 : integer              # 地点
        mineCfgId        4 : integer              # 资源点配置Id
        collectedResource 5: *ComIntInt()         # 采集资源量
        extraDrop 6: *ComIntInt()                 # 额外掉落
    }

     #战斗轮次
    .ComMailBattleRound {
        isWin               1 : integer                     # 攻方战斗结果 LOSE = 0, -- 失败 WIN = 1, -- 胜利 DRAW = 2, -- 平局
        attackTroop         2 : ComBattleTroopInfo          # 攻方信息
        defendTroop         3 : ComBattleTroopInfo          # 守方信息
        time                4 : integer                     # 时间
        battleLogName       7 : string                      # 战斗日志文件名

        siegeScore     11 : integer                         # 怪物攻城积分
    }
    
    # 属性来源-》属性列表
    .ComSourceAttrs {
        sourceType 0: integer # 属性来源
        attrs 1: *ComIntInt() # 属性[attrId]=attrValue
    }
    
    # 部队属性来源列表
    .ComTroopSourceAttrs {
        troopId 0: integer # 部队id
        sourceAttrs 1: *ComSourceAttrs() # 属性来源类型(AttrSourceType)-》属性列表
        heroSourceAttrs 2: *ComSourceAttrs() # 英雄属性来源类型(HeroAttrSourceType)-》属性列表
    }
    
    .ComBattleRoundLog {
        castTroopId           0 : integer                       # 技能发起方
        roundLogType            1 : integer                     # 类型   1--伤害 2--治疗 3--反击 4--添加buff
        skillCfgId              2 : integer                     # 技能配置Id
        reduceHp               3 : integer                      # 减少血量
        isCrit                 4 : boolean                      # 是否暴击
        buffCfgId              5 : integer                      # buff效果配置Id
    }
    .ComBattleRoundLogs {
        roundLogs           1 : *ComBattleRoundLog          # 战斗轮次日志
        remainHps           2 : *ComIntInt()                # 剩余血量 [troopId]=remainHp
    }
    
    #战报
    .ComMailBattleReport {
        time                1 : integer                     # 时间
        battleCfgId         2 : integer                     # 战斗类型配置Id 参考Battle.xlsx
        isWin               3 : integer                     # 攻方战斗结果  LOSE = 0, -- 失败 WIN = 1, -- 胜利 DRAW = 2, -- 平局

        attackTroopBrief    5 : ComBattleTroopInfoBrief     # 攻方信息一级界面 双方对战信息
        defendTroopBrief    6 : ComBattleTroopInfoBrief     # 守方信息一级界面 双方对战信息

        battleRounds        7 : *ComMailBattleRound         # 战斗场次  从进战到脱战发生的战斗场次
        battleRoundCount    8 : integer                    # 战斗场次总数


        harm               17 : integer                     # 对神兽的伤害


        actId  22 : integer                                 # 怪物攻城活动id
        round  23 : integer                                 # 怪物攻城活动轮次
        attackRound 24: integer                             # 怪物攻城攻击轮次
        aid  25: integer                                    # 我方的联盟ID
    }
    
    #战报
    .ComMailBattleReportShowData {
        time                1 : integer                     # 时间
        battleCfgId         2 : integer                     # 战斗类型配置Id 参考Battle.xlsx
        isWin               3 : integer                     # 攻方战斗结果  LOSE = 0, -- 失败 WIN = 1, -- 胜利 DRAW = 2, -- 平局
        rewardList          4 : *ComRes                     # 奖励列表 打野或抢夺资源
        attackTroopBrief    5 : ComBattleTroopInfoBrief     # 攻方信息一级界面 双方对战信息
        defendTroopBrief    6 : ComBattleTroopInfoBrief     # 守方信息一级界面 双方对战信息

        ##battleRounds      7 : *ComMailBattleRound         # 战斗场次  从进战到脱战发生的战斗场次
        battleRoundCount    8 : integer                    # 战斗场次总数

        extraDrop           9 : *ComRes                     # 额外掉落
        isReinforceCastle   10 : boolean                    # 是否是城堡援助部队
        assembleDrop       11 : *ComRes                     # 发起集结奖励
        joinAssembleDrop   12 : *ComRes                     # 加入集结奖励
        harmRewardDrop     13 : *ComRes                     # 集结伤害百分比奖励
        harmRate           14 : double                      # 集结伤害百分比

        harm               17 : integer                     # 对神兽的伤害


        newKingBuffWoundReduce 18 : integer                 # 新服buff重伤减少
        newKingBuffDeadReduce 19 : integer                  # 新服buff死亡减少
        newKingBuffWoundAdd 20 : integer                    # 新服buff重伤增加
        newKingBuffDeadAdd 21 : integer                     # 新服buff死亡增加

        actId  22 : integer                                 # 活动id
        round  23 : integer                                 # 活动轮次
        attackRound 24: integer                             # 怪物攻城攻击轮次
        aid  25: integer                                  # 我方的联盟ID
    }

    #大屠杀邮件
    .ComMailMassacre {
         nickName         1 : string                         # 对方昵称
    }

    #怪物丢失邮件
    .ComMailMonsterLost {
        time                1 : integer                     # 时间
        npcCfgId            2 : integer                     # 怪物配置Id
    }

    #目标丢失邮件
    .ComMailTargetLost {
        time                1 : integer                     # 时间
        objType             2 : integer                     # 目标类型 1 城堡 2 矿点 49 空地
    }

    # 保护罩邮件 侦查失败 阻止侦查 进攻失败 阻止进攻
    .ComMailShiledCastle {
        nickName           0 : string                      # 人名
        abbName            1 : string                      # 联盟简称 可能为空
    }

    #集结主动解散邮件
    .ComMailRallyDissolution {
        type             1 : integer                     # 目标类型: SceneObjType
        nickName         2 : string                      # 如果是玩家 昵称
        configId         3 : integer                     # 其它对象配置id
    }

    .ComHarmRankRewardPlayer {
        rank 1: integer                                 #排名
        uid 2: integer                                  #玩家id
        nickName 3: string                              #玩家昵称
        headId 4: integer                               #头像
        headFrameId 5: integer                          #头像框
        
        rewardList          10 : *ComRes                #伤害排名奖励列表
    }

    #世界boss伤害排名奖励邮件
    .ComHarmRankReward {
        npcCfgId         1 : integer                       # 怪物配置id
        playerList 2: *ComHarmRankRewardPlayer             # 排行
    }

    .ComMailScoutBaseInfo {
        leaderInfo       0 : ComPlayerBaseInfo              # 队长基础信息
        posX             1 : integer                        # 地点
        posY             2 : integer                        # 地点
        fightPower       3 : integer                        # 队长战斗力
        durability       4 : integer                        # 耐久度
        maxDurability     5 : integer                       # 最大耐久度
    }

    #侦察报告
    .ComMailScoutReport {
        objType     0:integer                            # 被侦察目标类型
        result      1:boolean                            # 侦察成功 失败
        failReason  2:integer                            # 侦察失败原因 1 加入了同一联盟 2 保护罩 3 使用了反侦察道具 4 迁城 5 目标消失

        ##realScoutLevel 3:integer                         # 侦察实际等级

        configId    4:integer                            # 建筑配置id


        baseInfo    5:ComMailScoutBaseInfo               # 基础信息
        canRobRes   6:*ComRes                            # 可掠夺资源
        totalArmy   7:*ComArmyIdAndNum()                 # 驻防部队总数
        defendTroop 8:ComBattleTroopInfo                 # 驻防部队
        battleAttrs 9:*ComIntInt()                       # 战争增益
    }

    #被侦察
    .ComMailBeScouted{

        objType     0:integer                            # 被侦察目标类型
        scoutPlayer 1:ComPlayerBaseInfo                  # 侦察者
        posX        2:integer                            # 地点
        posY        3:integer                            # 地点
        configId    4:integer                            # 建筑配置id
    }

    # 建筑升级奖励
    .ComMailBuildUpgrade {
        buildCfgId          1 : integer                     # 建筑配置表id
        lv                  2 : integer                     # 建筑等级
    }

    # 雷达交互邮件
    .ComMailRadarInteraction {
        eventCfgId          1 : integer                     # 事件的配置ID
    }

    # 加入联盟邮件
    .ComMailWelcomeJoinAlliance {
        content             1 : string                      # 邮件内容
    }

    # 联盟捐献排行榜
    .ComAllianceDonateRank {
        rank               1 : integer                     # 排名
    }

    # 盟主变化
    .ComMailTransferLeader {
        oldLeader          0 : string                      # 老盟主
        newLeader          1 : string                      # 新盟主
    }

    # 职位变化
    .ComMailRankChange {
        newRank           0 : integer                     #职位
    }

    # 官职变化
    .ComMailPositionChange {
        position           0 : integer                     #官职
        nickName           1 : string                       #昵称
    }

    # 被踢
    .ComMailBeKick {
        reason             0 : integer                     # 原因
        nickName           1 : string                       # 踢人者昵称
    }

    # 联盟名称与简称
    .ComMailALName {
        fullName           0 : string                     # 名称
        abbName            1 : string                       # 简称
    }

    # 邀请信息
    .ComMailALInviteInfo {
        nickName           0 : string                     # 邀请人名称
        allianceName       1 : ComMailALName               # 联盟名称与简称
    }

    # 医院爆仓
    .ComHospitalAlreadyFull {
        num1              0 : integer                     #治疗数量
        num2              1 : integer                     #死亡数量
    }

    # 据点首占奖励
    .ComMailFirstOwnHold {
        mapBuildCfgId    0 : integer                      # 建筑配置id mapBuild.lua
        posX             1 : integer                      # 坐标
        posY             2 : integer                      # 坐标
        rewardList       3 : *ComRes                      # 奖励列表
    }

    # 据点参与击杀守军奖励
    .ComMailAttackHoldBoss {
        mapBuildCfgId    0 : integer                      # 建筑配置id mapBuild.lua
        posX             1 : integer                      # 坐标
        posY             2 : integer                      # 坐标
        rewardList       3 : *ComRes                      # 奖励列表
    }


    # 占领据点邮件
    .ComMailOwnHold {
        mapBuildCfgId    0 : integer                      # 建筑配置id mapBuild.lua
        posX             1 : integer                      # 坐标
        posY             2 : integer                      # 坐标
    }

    # 聚落战争分配邮件
    .ComMailCampongWarDivideReward {
        campongId 0: integer #聚落ID
        divideId 1: integer #奖励分配ID
    }

    # 聚落战争报名邮件
    .ComMailCampongWarRegistList {
        campongList 0: *ComIntInt()
    }

    # 聚落战争击杀奖励
    .ComMailCampongWarKillReward {
        campongId 0: integer #聚落ID
        groupId 1: integer #奖励组ID
    }

    # 聚落战争占领奖励
    .ComMailCampongWarOccupyReward {
        campongId 0: integer    #聚落ID
        groupId 1: integer #奖励组ID
    }

    # 聚落战争占领积分
    .ComMailCampongWarOccupyPoint {
        point 0: integer #积分
        seasonId 1: integer #赛季ID
        round 2: integer #轮次
        campongId 3: integer #聚落ID
    }

    # 聚落战争赛季奖励
    .ComMailCampongWarSeasonReward {
        point 0: integer
        seasonId 1: integer
        groupId 2: integer
    }

    # 聚落战争赛季奖励
    .ComTideSuccessReward {
        tideId 0: integer
    }

    # 通用排行榜内容
    .ComCommonRank {
        rankCfgId 0: integer        # 排行榜id
        rank 1 : integer            # 排行
    }

    # GM邮件内容
    .ComGmMail {
        title 0: string
        content 1: string
        externalUrl 2: string
        internalUrl 3: string
        gameUrl 4:string
    }

    .ComGmMail2 {
        title 0: string
        content 1: string
        externalUrl 2: string
        internalUrl 3: string
        gameUrl 4:string
        activityId 5 : integer      # 活动ID
        activityName 6 : string       # 活动名称
    }

    # 活动奖励补发
    .ComActReward {
        activityId 0: integer   # 活动id
    }

    # 史诗招募活动奖励补发
    .ComEpicRecruitActReward {
        activityId 0: integer   # 活动id
    }

    .ComActContinuousReward {
        rechargePlanGrade 0: integer   # 当前档位
    }

    .ComAllianceMarkMail {
        nickName 0: string
        rank 1: integer
        markType 2: integer
        x 3: integer
        y 4: integer
        text 5: string
    }

    .ComSiegeReserve {
        actId 0: integer
        siegeTime 1: integer
    }

    .ComSiegeStart {
        actId 0: integer
    }

    .ComSiegeStageReward {
        actId 0: integer
        score 1: integer
        allianceScore 2: integer
        rewardGroup 3: integer
    }

    .ComAltarDamageNum {
        damageNum 0: integer # 伤害次数
    }

    .ComAltarReward {
        totalDamage 1: double # 联盟总伤害
    }

    .ComAllianceGroupMail {
        title 0: string #邮件标题
        content 1: string #邮件内容
        nickName 2: string #昵称
    }

    .ComSiegeFailMail {
        failNum 0: integer #失败次数
    }

    .ComMailPrivilegeCard {
        cfgId 0: integer # 特权卡id
    }

    .ComDismantleBuildMail { #主动拆除联盟建筑
        nickName 0: string #玩家昵称
        x 1: integer
        y 2: integer
        bid 3: integer #联盟建筑类型
    }

    .ComRemovedBuildMail { #被拆除联盟建筑
        abbName 0: string #联盟简称
        nickName 1: string #玩家昵称
        x 2: integer
        y 3: integer
        bid 4: integer #联盟建筑类型
    }

    # 王战分配奖励
    .ComMailKingWarDivide {
        groupId 0 : integer                      # 组id
        tp 1 : integer                           # 类型
    }
    
    .ComMailCrossWarDivide {
        groupId 0 : integer                      # 组id
        tp 1 : integer                           # 类型
        serverId 2 : integer
        kingKid 3 : integer
        kingUid 4 : integer
        fullName 5 : string
        abbName 6 : string
        nickName 7 : string
    }

    .ComMailOpinionBox {
        id 0: integer # 配置表id
        opValue 1: integer # 民意最高值
        dateTime 2: integer # 发奖日期
    }

    # 王战排行奖励
    .ComMailKingWarRank {
        groupId 0 : integer                      # 组id
        tp 1 : integer                           # 类型
        rank 2 : integer                         # 排名
        score 3 : integer                        # 积分
    }

    # 王战排行奖励
    .ComMailKingWarScore {
        groupId 0 : integer                      # 组id
        round 1 : integer                        # 类型
        score 2 : integer                        # 积分
    }

    # 王战结束
    .ComMailKingWarEnd {
        groupId 0 : integer                      # 组id
        round 1 : integer                        # 类型
        kingAid 2 : integer                      # 国王联盟AID
        fullName 3: string #联盟名称
        abbName 4: string #联盟简称
    }

    # 王战国王登基
    .ComMailKingWarKing {
        round 0 : integer                        # 轮次
        kingAid 1: integer       # 国王联盟ID
        kingUid 2: integer       # 国王玩家ID
        nickName 3: string #玩家昵称
        fullName 4: string #联盟全称
        abbName 5: string #联盟简称
    }
    
    # 跨服战国王登基
    .ComMailCrossWarKing {
        round 0 : integer        # 轮次
        serverId 1 : integer     # 服务器ID
        kingKid 2: integer       # 国王KID
        kingAid 3: integer       # 国王联盟ID
        kingUid 4: integer       # 国王玩家ID
        nickName 5: string #玩家昵称
        fullName 6: string #联盟全称
        abbName 7: string #联盟简称
    }

    #王战国王官职任命
    .ComMailKingWarOfficial {
        id 0 : integer #官职id
        kingUid 1: integer       # 国王玩家ID
        nickName 2: string #玩家昵称
        abbName 3: string #联盟简称
    }
    
    .ComMailCrossWarOfficial {
        serverId 0: integer
        kingKid 1: integer
        kingUid 2: integer       # 国王玩家ID
        nickName 3: string #玩家昵称
        abbName 4: string #联盟简称
        id 5 : integer #官职id
    }

    # 王战国王公告
    .ComMailKingWarNotice {
        notice 0: string
    }

    # 联盟神兽伤害
    .ComMailAltarDamage {
        damageValue 0: integer
        logFilename 1 : string                      # 战斗日志文件名
    }

    # 放置联盟积木矿
    .ComMailBuildBlockMine {
        posX 0: integer #x坐标
        posY 1: integer #y坐标
    }
    
    # 联盟积木矿建造完成
    .ComMailAddBlockMine {
        posX 0: integer #x坐标
        posY 1: integer #y坐标
    }


    # 支付发货
    .ComMailPayDeliver {
        goodsId 0: integer #商品ID
        items 1: *ComMailAppendixItem #物品列表
    }

    # 联盟神兽预约
    .ComMailAltarReserve {
        reserveTime 0: integer #预约时间
    }
    
    .ComMailArenaRank {
        rank 0: integer #
        name 1: string #
        serverId 2: integer #
        uid 3: integer #
        bRobot 4: boolean
        abbName 5: string
    }

    # 竞技场奖励
    .ComMailArenaReward {
        rank 0: integer        # 自己排名
        groupId 1: integer # 分组id 0:无 1:在黄金组 2:在白银组
    }

    .ComMailKingWarArmyDead {
        num 0: integer        # 死兵总数
    }

    .ComNpcTrialPlyAward {
        groupId 0: integer #
        awardId 1: integer #档位Id
    }

    .ComNpcTrialAliAward {
        groupId 0: integer #
        awardId 1: integer #档位Id
    }


    .ComPeakArenaRankReward {
        rank 0: integer        # 排名
    }

    .ComPeakArenaJoin {
        configGroupId 0 : integer # 配置组ID
    }

    
    # 赛季pvp个人积分奖励
   .ComMailSeansonPvpScore {
        groupId 1: integer #奖励组ID
        score 2: integer #个人积分
    }
    
     # 赛季pvp拾取积分
   .ComMailSeasonPvpPickUpScore {
        score 1: integer #拾取积分
    }
    
    # 王战排行奖励
    .ComMailCrossWarOpen {
        vsKid 0 : integer
        castleLv 1 : integer
    }
    
    # 王战/跨服战成为国王
    .ComMailBeKing {
        serverId 0 : integer                      # 服务器ID
    }

    .ComHospitalWillFull {
        rate 0: integer     # 使用容量万分比
    }

    .ComInvasionBossStageReward {
        actId 1: integer
    }

    .ComInvasionBossAttackNumReward {
        actId 1: integer
    }

    .ComStrongHoldStageReward {
        strongholdId 0: integer # 据点配置表id
        score 1: integer # 战功
        rankPlayerList 2: *ComTerritoryRankPlayer
        abbName 3: string # 联盟全称
        fullName 4: string # 联盟简称
        occupyNum 5: integer # 联盟占领的据点数量
        stage 6: integer # 达到的奖励档位
    }
    
    .ComStrongholdAllianceAward {
        strongholdId 0: integer # 据点配置表id
        score 1: integer # 战功
    }

    .ComStrongHoldDeclareWar {
        strongholdId 0: integer # 据点配置表id
        strongholdName 1: string # 据点名字
        nickName 2: string # 昵称
        declareTime 3: integer # 预约宣战时间戳
    }

    .ComStrongHoldGiveUp {
        strongholdId 0: integer # 据点配置表id
        strongholdName 1: string # 据点名字
        occupyNum 2: integer # 据点占领数量
        fullName 3: string # 联盟全称
        abbName 4: string # 联盟简称
        nickName 5: string # 昵称
    }

    .ComStrongHoldOccupyRemove {
        strongholdId 0: integer # 据点配置表id
        strongholdName 1: string # 据点名字
        fullName 2: string # 联盟全称
        abbName 3: string # 联盟简称
    }

    .ComPlaceAlliancePoint {
        nickName 1: string # 昵称
        x 2: integer # x
        y 3: integer # y
    }

    .ComChampionshipRecycle {
        itemNum 1: integer # 道具数量
    }

    .ComChampionShipRank {
        rank  1: integer # 排行值
    }
]]

mailProto.c2s = mailProto.struct .. [[

readOneMail 1301 { #读取一封邮件
    request {
        labelType 0: uint32                    # 页签类型
        id 1: uint32                           # 当前页签下的邮件ID
    }
    response {
    }
}

readAllMail 1302 { #一键读取页签下的所有邮件
    request {
        labelType 0: uint32                    # 页签类型
    }
    response {
    }
}

delOneMail 1303 { #删除一封邮件
    request {
        labelType 0: uint32                    # 页签类型
        id 1: uint32                           # 当前页签下的邮件ID
    }
    response {
    }
}

delAllMail 1304 { #一键删除页签下的所有邮件
    request {
        labelType 0: uint32                    # 页签类型
    }
    response {
    }
}

getOneMailReward 1305 { #获取一封邮件奖励
    request {
        labelType 0: uint32                    # 页签类型
        id 1: uint32                           # 当前页签下的邮件ID
    }
    response {
        labelType 0: integer               # 页签类型
        rewardList 1: *ComMailRewardInfo   # 奖励信息
    }
}

getAllMailReward 1306 { #一键获取页签下的所有邮件奖励
    request {
        labelType 0: uint32                 # 页签类型
    }
    response {
        labelType 0: integer               # 页签类型
        rewardList 1: *ComMailRewardInfo   # 奖励信息
    }
}

queryMail 1307 { #查询邮件信息
    request {
        labelType 0: uint32                 # 页签类型
        beginId 1: uint32                   # 开始ID(0代表最大的ID倒序)
        count 2: uint32                     # 查询数量
        isPre 3 : boolean                    # true beginId前count个,false beginId后count个
    }
    response {
        labelType 0: integer                     # 页签类型
        mailList 1: *ComMailInfo                 # 邮件列表
    }
}

collectMail 1308 { #收藏邮件
    request {
        labelType 0: uint32                    # 页签类型
        id 1: uint32                           # 当前页签下的邮件ID
    }
    response {
    }
}

queryAllMailBriefInfo 1310 { #查询邮件简要信息
    request {
        labelType 0: uint32                    # 页签类型
    }
    response {
        labelType 0: integer                    # 页签类型
        ids 1 : *integer
    }
}

queryMailByIds 1311 { #通过邮件ID查询邮件
    request {
        labelType 0: uint32             # 页签类型
        ids 1 : *uint32                 # id列表
        uid 2: uint32                   # 值>0时，表示查任意玩家的邮件
    }
    response {
        labelType 0: integer             # 页签类型
        mailList 1: *ComMailInfo         # 邮件列表
        uid 2: uint32                    # 值>0时，表示查任意玩家的邮件
    }
}

cancelCollectMail 1312 { #取消收藏邮件
    request {
        id 1: uint32                   # 取消收藏邮件ID
    }
    response {
    }
}

queryMailBattleReport 1313 { #通过邮件ID查询战报详细信息
    request {
        labelType 0: uint32             # 页签类型
        id 1 : uint32                   # id
        uid 2: uint32                   # 值>0时，表示查任意玩家的邮件
    }
    response {
        labelType 0: integer             # 页签类型
        id 1 : integer                   # id
        battleReport 2: ComMailBattleReport #战报
    }
}

queryMailBattleLog 1314 { #查询战报日志详情
    request {
        battleLogName 0: string             # 战报日志文件名
    }
    response {
        battleRoundLogs 1: *ComBattleRoundLogs   #详情
    }
}

delMails 1315 { #批量删除多封邮件
    request {
        labelType 0: uint32                   # 页签类型
        ids 1: *uint32                        # 邮件ID列表
    }
    response {
    }
}

cancelCollectMails 1316 { #批量取消收藏邮件
    request {
        ids 1: *uint32                   # 取消收藏邮件ID列表
    }
    response {
    }
}

queryMailBattleRound 1317 { #通过邮件ID查询战报回合数据
    request {
        uid 0: uint32                   # uid为nil时 表示查自己的邮件，不为nil且>0时，表示查指定玩家的邮件
        labelType 1: uint32             # 页签类型
        id 2 : uint32                   # id
        rounds 3: *uint32                # 战斗轮次 【1,battleRoundCount] 一次最多请求5个轮次
    }
    response {
        uid 0: uint32                   # uid为nil时 表示查自己的邮件，不为nil且>0时，表示查指定玩家的邮件
        labelType 1: uint32             # 页签类型
        id 2 : uint32                   # id
        rounds 3: *uint32                # 战斗轮次 【1,battleRoundCount]
        battleRounds 4: *ComMailBattleRound # 战斗回合数据
    }
}

queryMailBattleSourceAttrs 1318 { #查询战报属性来源对比
    request {
        battleLogName 0: string             # 战报日志文件名
    }
    response {
        troopSourceAttrs 1: *ComTroopSourceAttrs(troopId) # 部队属性来源列表 玩家部队才有值 怪物没有值
    }
}

]]

mailProto.s2c = mailProto.struct .. [[
    newMailNotice 1351 {  #新邮件通知
        request {
            labelType 0: integer             # 页签类型
            mailInfo  1: ComMailInfo         # 邮件信息
        }
        response {
        }
    }

    delMailNotice 1352 {  #删除邮件通知
        request {
            labelType 0: integer             # 页签类型
            mailId  1: integer               # 邮件ID
        }
        response {
        }
    }
]]

return mailProto
