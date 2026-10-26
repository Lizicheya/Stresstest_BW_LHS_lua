-- 通用玩家信息模块 21~40
local playeInfoProto = {}

playeInfoProto.struct = [[
    .ComLord {
        uid 0: integer                                      #
        nickName 1: string                                  # 玩家昵称
        castleLv 2: integer                                 # 城堡等级
        castleModel 3: integer                              # 城堡模型
        headAndFrame 4: ComHeadAndFrameData                 # 头像和头像框
        serverId 5:  integer                                # 服务ID
        age 6 : integer                                     # 时代
        lv 7: integer                                       # 玩家等级
        registerTime 8: integer                             # 注册时间
        isNameChanged 9: boolean                            # 是否改过名
        exp 10: integer                                     # 经验
        showUid 11: integer                                 # 展示uid
        style 12: integer                                   # 风格
        sex 13: integer                                     # 性别
        sign 14: string                                     # 个性签名
        likeNum 15: integer                                 # 点赞数量
        maxLikeId 16: integer                               # 当前最大点赞id
        dailyLikeNum 17: integer                            # 今日已点赞次数
        kill 18: integer                                    # 击杀
        totalRecharge 19: double                            # 累计充值
        enableLike 20: boolean                              # 是否允许点赞
        isEvaluate 21: boolean                              # 是否评价过
    }

    .ComPlayerInfo {
        uid 0: integer                                      # 玩家UID
        nickName 1: string                                  # 玩家昵称
        isOnline 2: boolean                                 # 是否在线
        lastLoginTime 3: integer                            # 最后登陆时间
        headFrameId 4: integer                              # 头像框ID
        headId 5: integer                                   # 头像ID
        customHead 6: string                                # 自定义头像
        power 7: integer                                    # 战力
        kill 8: integer                                     # 击杀
        aid 9: integer                                      # 联盟id
        castleLv 10: integer                                # 城堡（秩序大厅）等级
        serverId 11: integer                                # 服务器id
        achievementBadgesShow 12: *integer                  # 成就墙展示
        applySkinCfgId 13: *integer                         # 装扮配置id
        applySkinLv 14: *integer                            # 装扮等级
        applySkinExpiredTS 15: *integer                     # 装扮过期
        currentOpenBarrier 16: integer                      # 当前挑战副本
        latestCompletedBarrier 17: integer                  # 最后通关挑战副本
        lordOutfitShow 18: boolean                          # 是否展示
        lordOutfit 19: string                               # 领主装备
        bUnlockOutfit 20: boolean                           # 是否解锁领主装备
        bUnlockBadge 21: boolean                            # 是否解锁领主宝石
        language 22: integer                                # 语言
        fullName 23: string                                 # 联盟全称
        abbName 24: string                                  # 联盟简称
    }

    .ComWorld {
        castleX 1: integer                                  # 城堡坐标
        castleY 2: integer                                  # 城堡坐标
        castleSceneObjId 3: integer                         # 城堡场景id
        scenes 4: *ComIntInt()                              # 场景map sceneId<=>sceneCfgId sceneId 服务端场景id，用于enterScene
        isBurning 5:boolean                                 # 是否在燃烧
        isCreatedCastle 6:boolean                           # 是否已创建外城
        isMaxDurability 7:boolean                           # 当前城防值是否已满
        crossServerId 8: integer                            # 跨服服务器id
    }

    .ComPower {
        totalPower 1: integer                               # 总战力
        maxTotalPower 2: integer                            # 最大总战力
    }

    .ComSyncDataArmy {
        news 1: *ComArmyIdAndNum()                          # 新增士兵列表
        changes 2: *ComArmyIdAndNum()                       # 更新士兵列表
        removes 3: *integer                                 # 删除士兵id
    }

    .ComSyncDataHero {
        news 1: *ComHero(heroCfgId)                         # 新增英雄列表
        changes 2: *ComHero(heroCfgId)                      # 更新英雄列表
        removes 3: *integer                                 # 删除英雄id
    }

    .ComSyncDataItem {
        news 1: *ComItem(id)                                # 新增物品列表
        changes 2: *ComItem(id)                             # 更新物品列表
        removes 3: *integer                                 # 删除物品id
    }

    .ComSyncSvrItem {
        news 1: *ComIntInt()                                # 新增物品列表
        changes 2: *ComIntInt()                             # 更新物品列表
        removes 3: *integer                                 # 删除物品id
    }

    .ComSyncDataAttribute {
        news 1: *ComIntInt()                                # 新增属性列表
        changes 2: *ComIntInt()                             # 更新属性列表
        removes 3: *integer                                 # 删除属性id
    }

    .ComSyncDataCity {
        news 1: *ComBuild(id)                               # 新增建筑列表
        changes 2: *ComBuild(id)                            # 更新建筑列表
        removes 3: *integer                                 # 删除建筑id
    }

    .ComSyncDataCityAreaUnlock {
        news 1: *ComCityAreaUnlock(areaCfgId)               # 新增区域解锁
        changes 2: *ComCityAreaUnlock(areaCfgId)            # 更新区域解锁
        removes 3: *integer                                 # 删除区域解锁
    }

    .ComSyncDataRecycleBuildings {
        news 1: *ComIntInt()                                # 新增回收建筑
        changes 2: *ComIntInt()                             # 更新回收建筑
        removes 3: *integer                                 # 删除回收建筑id
    }
    
    .ComSyncDataQueue {
        news 1: *ComQueue(queueCfgId)                       # 新增队列列表
        changes 2: *ComQueue(queueCfgId)                    # 更新队列列表
        removes 3: *integer                                 # 删除队列id
    }

    .ComSyncDataQueueCfgIds {
        news 1: *ComIntDouble()                             # 新增开放队列配置id列表
        changes 2: *ComIntDouble()                          # 更新开放队列配置id列表
        removes 3: *integer                                 # 删除开放队列配置id
    }

    .ComSyncDataBuff {
        news 1: *ComBuff(buffCfgId)                         # 新增buff列表
        changes 2: *ComBuff(buffCfgId)                      # 更新buff列表
        removes 3: *integer                                 # 删除buffid
    }

    .ComSyncDataPendingArmy {
        news 1: *ComPendingArmy(armyType)                   # 新增待收取士兵
        changes 2: *ComPendingArmy(armyType)                # 更新待收取士兵
        removes 3: *integer                                 # 删除待收取士兵
    }

    .ComSyncDataResProduce{
        news 1: *CompResProduce(buildId)                    # 新增资源生产
        changes 2: *CompResProduce(buildId)                 # 更新资源生产
        removes 3: *integer                                 # 删除资源生产
    }

    .ComSyncDataWarehouse{
        news 1: *ComResProtectInfo(itemCfgId)               # 新增仓库资源保护
        changes 2: *ComResProtectInfo(itemCfgId)            # 更新仓库资源保护
        removes 3: *integer                                 # 删除仓库资源保护
    }

    .ComSyncDataFormation{
        news 1: *ComFormation(id)                           # 新增布阵队列
        changes 2: *ComFormation(id)                        # 更新布阵队列
        removes 3: *integer                                 # 删除布阵队列
    }

    .ComSyncDataTask{
        type 0: integer                                     # 任务类型
        news 1: *ComTask(id)                                # 新增任务
        changes 2: *ComTask(id)                             # 更新任务
        removes 3: *integer                                 # 删除任务
    }

    .ComSyncDataTechnology{
        news 1: *ComTechnology(id)                          # 新增科技
        changes 2: *ComTechnology(id)                       # 更新科技
        removes 3: *integer                                 # 删除科技
    }

    .ComSyncDataShop{
        news 1: *integer                                    # 新增商店
        changes 2: *integer                                 # 更新商店
        removes 3: *integer                                 # 删除商店
    }

    .ComSyncDataSystemOpen{
        news 1: *integer                                    # 新增系统开启
        changes 2: *integer                                 # 更新系统开启
        removes 3: *integer                                 # 删除系统开启
    }

    .ComSyncHead{
        news 1: *ComHeadData(headId)                        # 新增头像
        changes 2: *ComHeadData(headId)                     # 更新头像
        removes 3: *integer                                 # 删除头像
    }

    .ComSyncHeadFrame{
        news 1: *ComHeadFrameData(headFrameId)              # 新增头像框
        changes 2: *ComHeadFrameData(headFrameId)           # 更新头像框
        removes 3: *integer                                 # 删除头像框
    }

    .ComSyncDataPendingHealArmy {
        news 1: *ComArmyIdAndNum()                          # 新增待收取治疗士兵列表
        changes 2: *ComArmyIdAndNum()                       # 更新待收取治疗士兵列表
        removes 3: *integer                                 # 删除待收取治疗士兵列表
    }

    .ComSyncRadarEvent {
        news 1: *ComRadarEvent(id)                          # 新增雷达事件
        changes 2: *ComRadarEvent(id)                       # 更新雷达事件
        removes 3: *integer                                 # 移除雷达事件
    }

    .ComSyncLordStatData {
        news 1: *ComIntInt()                                # 领主统计数据新增
        changes 2: *ComIntInt()                             # 统计数据更新
    }

    .ComSyncAllianceTechnology {
        normalDonate 1: ComNormalDonate                     # 普通捐献数据
        gemDonate 2: ComGemDonate                           # 宝石捐献数据
        dailyVal 3: integer                                 # 每日总贡献值
        weeklyVal 4: integer                                # 每周总贡献值
        preDonateMultiCircularList 5: integer               # 预捐献循环暴击倍数环形列表
        indexCircularList 6: integer                        # 当前环形列表索引
    }

    .AllianceGiftInfo {
        key 1: integer # 礼物id
        value 2: *ComRes # 领取的奖励
    }

    .AllianceGiftInfoSyncData {
        news 1: *AllianceGiftInfo()                          # 新增列表
        changes 2: *AllianceGiftInfo()                       # 更新列表
        removes 3: *integer                                  # 删除列表
    }

    .ComAllianceGift {
        bAnonymous 0: boolean                      #是否匿名
        claimdIdList 1: *AllianceGiftInfo()        #领取列表
    }
    
    .ComSyncDataAllianceGift {
        bAnonymous 0: boolean                      #是否匿名
        claimdIdList 1: AllianceGiftInfoSyncData       
    }
    
    #联盟邀请
    .ComSyncAllianceInvite {
        inviteNum 0: integer            #邀请次数
        fullName 1: string #联盟全称
        abbName 2: string #联盟简称
        language 3: integer #联盟语言
        flagId 4: integer #标志样式
        colorId 5: integer #标志颜色
        patternId 6: integer #标识图案
        aid 7: integer #联盟ID
    }

    .ComSyncHeroBackground {
        news 1: *ComHeroBackgroundData(heroId)              # 新增英雄背景信息
        changes 2: *ComHeroBackgroundData(heroId)           # 更新英雄背景信息
        removes 3: *integer                                 # 删除英雄背景信息
    }

    .ComSyncHeroLevelResonance {
        news 1: *ComHeroLevelResonanceData(id)              # 新增英雄等级共鸣
        changes 2: *ComHeroLevelResonanceData(id)           # 更新英雄等级共鸣
        removes 3: *integer                                 # 删除英雄等级共鸣
    }

    .ComSyncAchievementBadges {
        news 1: *ComIntInt()                                # 新增成就徽章
        changes 2: *ComIntInt()                             # 更新成就徽章
        removes 3: *integer                                 # 删除成就违章
    }

    .ComSyncAchievementPoint {
        news 1: *ComIntInt()                                # 新增成就徽章展示
        changes 2: *ComIntInt()                             # 更新成就徽章展示
        removes 3: *integer                                 # 删除成就违章展示
    }

    .ComVip {
        vipLv 0: integer                # vip等级
        totalExp 1: integer             # 总经验
        dayVipExpTS 2: integer          # 每日vip经验领取时间
        dayGiftTS 3: integer            # 每日礼包领取时间
        continueLoginDay 5: integer     # 连续登陆天数
        lastCheckTS 6: integer          # 上次检测过天记录
        expiredTS 7: integer            # 激活到期时间
    }

    .ComItemCapSource {
        key 0: integer             # 来源
        value 1:*ComIntInt()       # 限制类型对应数量
    }

    .ComItemCap {
        key 0: integer             # 资产id
        value 1:*ComItemCapSource()       # 限制类型对应数量
    }

    .ComAssetsLimit {
        dayNextRefreshTS 0: integer         # 刷新每日获得上限
        weekNextRefreshTS 1: integer        # 刷新每日获得上限
        itemCap 2: *ComItemCap()            # 本日获得量列表（初始化全量同步）
        itemCapChange 3: *ComItemCap()      # 本日获得量改变同步（有改动的数量为最终已获取数量）
        limitCfgItem 4: *ComItemCap()       # 本次获取资源超过上限的列表(数量为超过的数量)
    }

    .ComSyncActivity {
        new 1: Activity             # 新增活动
        change 2: Activity          # 更新活动
        remove 3: integer           # 移除活动
    }

    .ComSyncActivityAgenda {
        new 1: ActivityAgenda       # 新增活动日程
        remove 2: string            # 取消活动日程
    }

    .ComSyncFateWheelActivityInfo {
        news 1: *ComFateWheelActivityInfo(id)              # 新增命运之轮
        changes 2: *ComFateWheelActivityInfo(id)           # 更新命运之轮
        removes 3: *integer                                # 删除命运之轮
    }

    .ComSyncActivityShop {
        news 1: *ComActivityShop(activityId)                 # 新增活动商店数据
        changes 2: *ComActivityShop(activityId)              # 更新活动商店数据
        removes 3: *integer                                  # 删除活动商店数据
    }

    .ComActivityCommonTask {
        round 0: integer             # 轮次
        actId 2: integer             # 活动id
        taskGroupId 3: integer       # 活动配置参数(使用哪个任务组)
    }

    .ComSyncActivityCommonTask {
        news 0: ComActivityCommonTask
        changes 1: ComActivityCommonTask
    }

    .ComSyncTideRuins {
        news 1: *ComIntInt() #新增废墟数据                     
        removes 3: *integer    #移除废墟                       
    }

    .ComSyncTideSuccessMonsters {
        news 1: *ComIntInt()    #新增成功怪物                     
        removes 3: *integer     #移除成功怪物                       
    }

    .ComSyncRecruitComp {
        news 1: *ComRecruitComp(activityId)                 # 新增招募组件
        changes 2: *ComRecruitComp(activityId)              # 更新招募组件
        removes 3: *integer                                 # 移除招募组件
    }

    .ComSyncPay {
        news 0: *PayGoods()                                 # 新增支付
        changes 1: *PayGoods()                              # 更新支付
        removes 2: *integer                                 # 移除支付
    }

    .ComSyncStronestLord {
        news 0 : *StrongesLordInfo(actId)                    # 新增最强领主                   
        changes 1 : *StrongesLordInfo(actId)                 # 更新最强领主
        removes 2 : *integer                                 # 移除最强领主
    }
    
    .ComSyncShopRefresh {
        news 1: *ComShopRefresh(shopId)                     # 新增商店免费刷新
        changes 2: *ComShopRefresh(shopId)                  # 更新商店免费刷新
        removes 3: *integer                                 # 移除商店免费刷新
    }
    
    .ComSyncShopFreeSlot {
        news 1: *ComShopFreeSlot(shopId)                    # 新增商店免费槽位
        changes 2: *ComShopFreeSlot(shopId)                 # 更新商店免费槽位
        removes 3: *integer                                 # 移除商店免费槽位
    }

    .ComSyncMarkCoordinate {
        news 1: *ComMarkCoordinates()                       # 新增标记坐标
        changes 2: *ComMarkCoordinates()                    # 同步标记坐标
        removes 3: *string                                  # 移除标记坐标
    }

    .ComSyncApplySkins {
        news 1: *ComIntInt()                                # 新增
        changes 2: *ComIntInt()                             # 更新
        removes 3: *integer                                 # 删除
    }

    .ComAccumulateRecharge {
        news 0 : *AccumulateRechargeInfo(actId)             # 新增累计充值                   
        changes 1 : *AccumulateRechargeInfo(actId)          # 更新累计充值
        removes 2 : *integer                                # 移除累计充值
    }

    .ComContinuousRecharge {
        new 0 : ContinuousRechargeInfo                     # 新增累计充值                   
        change 1 : ContinuousRechargeInfo                  # 更新累计充值
        remove 2 : integer                                 # 移除累计充值
    }

    .ComSyncPrivilegeCard {
        new 0 : ComPrivilegeCard                           # 新增
        change 1 : ComPrivilegeCard                        # 更新
        remove 2 : integer                                 # 移除
    }

    .ComActivityPass {
        news 0 : *ComActivityPassInfo(actId)               # 新增
        changes 1 : *ComActivityPassInfo(actId)            # 更新
        removes 2 : *integer                               # 移除
    }

    .ComSyncSettings {
        news 1: *ComIntInt()                                # 新增游戏设置
        changes 2: *ComIntInt()                             # 更新游戏设置
        removes 3: *integer                                 # 删除游戏设置id
    }

    .ComActivitySkinCollect {
        new 0 : ComActivitySkinCollectInfo                 # 新增
        change 1 : ComActivitySkinCollectInfo              # 更新
        remove 2 : integer                                 # 移除
    }

    .ActivityGift {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态

        .Param {
            configGroupId 0 : integer # 活动配置组 Id
        }

        param 3 : Param # 参数

        .Data {
            lastFreeRewardClaimTime 0 : integer # 上次免费宝箱奖励领取时间
        }
        data 4 : Data
    }

    .ComActivityGift {
        new 0 : ActivityGift                                # 新增
        change 1 : ActivityGift                             # 更新
    }

    .ComSyncTerritoryGain {
        news 1:  *ComTerritoryGainFreeItem(territoryGainFreeId)  # 新增
        changes 2:  *ComTerritoryGainFreeItem(territoryGainFreeId)  # 更新
    }


    .ComSyncLordOutfitList {
        new 0 : ComLordOutfitInfo                                # 新增
        change 1 : ComLordOutfitInfo                             # 更新
    }
    
    .ComSyncLordOutfitData {
        bShow 0 : boolean                                # 是否展示
        outfitList 1 : ComSyncLordOutfitList                       # 装备列表更新
    }

    .ComSyncServerInfo {
        news 0 : *ComServerInfo(serverId)                                # 新增
        changes 1 : *ComServerInfo(serverId)                             # 更新
    }

    .ComSyncAllianceBlock {
        gemDonateCount 1: integer  #宝石捐献次数
        normalDonateCount 2: integer #普通捐献次数
        updateTime 3: integer #更新时间
    }

    .ComSyncAllianceAltar {
        donateNum 1: integer  #祭坛捐献次数
        updateTime 2: integer #更新时间
    }

    .ComSyncInvitedMoveCastle {
        abbName 1: string
        nickName 2: string
        uid 3: integer
        aid 4: integer
    }

    .ComSyncAllianceCreate {
        unlockId 1: integer
        costRes 2: *ComRes
    }

    .ComSyncServerSettings {
        news 1: *ComIntString() # 新增
        changes 2: *ComIntString()  # 更新
    }

    .ComSyncPeakArena {
        new 0 : PeakArenaInfo # 新增巅峰竞技场
        change 1 : PeakArenaInfo # 更新巅峰竞技场
        remove 2 : integer # 移除巅峰竞技场
    }

    .ComSyncAllianceGvgTeam {
        teamId 0: integer # 玩家队伍id
    }

    .ActivityGiftMap {
        actId 0 : integer
        data 1 : ActivityGift
    }

    .ComSyncFurniture {
        news 1: *ComFurniture(id)    # 新增
        changes 2: *ComFurniture(id) # 更新
        removes 3: *integer          # 删除
    }

    .ComSyncBasicRess {
        news 1: *ComBasicRess(cfgId)    # 新增
        changes 2: *ComBasicRess(cfgId) # 更新
    }
    
    .ComSyncEquipSlot {
        news 1: *ComIntInt()    # 新增
        changes 2: *ComIntInt() # 更新
        removes 3: *integer     # 删除
    }
        
    .ComSyncMonsterHunt {
        news 0 : *MonsterHuntInfo(actId) # 新增异兽追捕
        changes 1 : *MonsterHuntInfo(actId) # 更新异兽追捕
        removes 2 : *integer # 移除异兽追捕
    }

    .ComSyncSatisfactionPoint {
        news 1: *ComSatisfactionPoint(cfgId)                                # 新增满意度
        changes 2: *ComSatisfactionPoint(cfgId)                             # 更新满意度
        removes 3: *integer                                                 # 删除满意度
    }

    .ComSyncDataChatEmoji {
        news 1: *ComIntBool()
    }

    .ComSyncContinuousStoredValue {
        news 1: *ComContinuousStoredValue(actId)
        changes 2: *ComContinuousStoredValue(actId)
        removes 3: *integer
    }

    .ComSyncChampionshipDuelData {
        news 1: *ComChampionshipDuelData(actId)
        changes 2: *ComChampionshipDuelData(actId)
        removes 3: *integer
    }
]]

playeInfoProto.c2s = playeInfoProto.struct..[[

]]

playeInfoProto.s2c = playeInfoProto.struct..[[

syncLoginData 22 {
    request {
        serverTime 0: double                                # 服务器时间
        serverOpenTime 1: integer                           # 服务器开服时间(时间戳)
        army 2: *ComArmyIdAndNum()                          # 士兵信息
        upgradeArmy 3: *ComArmyIdAndNum()                   # 升级士兵信息
        lord 4: ComLord                                     # 玩家基础信息
        hero 5: *ComHero(heroCfgId)                         # 英雄信息
        world 6: ComWorld                                   # 世界信息
        item 7: *ComItem(id)                                # 物品信息
        attribute 8: *ComIntInt()                           # 属性信息
        city 9: *ComBuild(id)                               # 建筑信息
        queue 10: *ComQueue(queueCfgId)                     # 队列信息
        openQueueCfgIds 11: *ComIntDouble()                 # 开放的队列配置id信息
        buff 12: *ComBuff(buffCfgId)                        # buff信息
        unlockArmyCfgIds 13: *integer                       # 已解锁士兵列表
        pendingArmy 15: *ComPendingArmy(armyType)           # 待收取士兵
        resProduce 16: *CompResProduce(buildId)             # 资源生产
        mailUnRead 17: ComMailUnread                        # 邮件未读信息
        task 18: *ComTaskTypeTasks(type)                    # 任务信息
        warehouse 19: *ComResProtectInfo(itemCfgId)         # 仓库
        formations 20: *ComFormation(id)                    # 布阵
        technology 21: *ComTechnology(id)                   # 科技
        shop 22: *integer                                   # 商店
        systemOpen 24: *integer                             # 系统开启ID
        recycleBuildings 26: *ComIntInt()                   # 回收建筑
        heads 27: *ComHeadData(headId)                      # 头像
        headFrames 28: *ComHeadFrameData(headFrameId)       # 头像框
        physicalStrength 29: ComPhysicalStrength            # 体力
        woundedArmy 30: *ComArmyIdAndNum()                  # 伤兵信息
        pendingHealArmy 31: *ComArmyIdAndNum()              # 待收取治疗士兵
        taskDay 32: ComTaskDay                              # 每日任务
        taskChapter 33: ComTaskChapter                      # 章节任务
        recruitPoint 34: integer                            # 招募积分
        barrierData 35: ComBarrierModuleData                # 副本数据
        radarEvents 36: *ComRadarEvent(id)                  # 雷达事件
        radarBase   37: ComRadarBase                        # 雷达基本数据
        lordStat 38: *ComIntInt()                           # 普通统计 统计总数量(LoadStatType-num)
        lordKillNormalMonsterStat 39: *ComIntInt()          # 杀怪统计 统计杀死的每个等级的普通怪(lv-num)
        power 40: ComPower                                  # 战力
        allianceTechnology 41: ComSyncAllianceTechnology    # 联盟科技
        allianceInvite 42: ComSyncAllianceInvite            # 联盟邀请
        allianceGift 43: ComAllianceGift                    # 联盟礼物与宝箱
        heroBackground 44: *ComHeroBackgroundData(heroId)   # 英雄背景数据
        taskAllianceNovice 45: ComTaskAllianceNovice        # 联盟新手任务
        heroLevelResonance 46: *ComHeroLevelResonanceData(id)# 英雄等级共鸣
        resonanceHeroTemplate 47: *integer                   # 共鸣英雄模版
        achievementBadges 49: *integer                      #获得的成就徽章
        achievementBadgesShow 50: *integer                   #成就徽章展示列表
        cityMonster 51: integer                             # 内城怪物刷新时间
        vip 52: ComVip                                      # vip数据
        achievementPoints 53: *ComIntInt()                   #成就积分
        achievementBoxs 54: *integer                         #成就宝箱
        heroRelationshipRewardList 55: *integer              #英雄羁绊已经领取奖励列表
        assetsLimit 56: ComAssetsLimit                       # 资产获得限制
        activity 57: *Activity(actId)                       # 活动列表
        activityAgenda 58: *ActivityAgenda(agendaId)        # 活动日程列表
        activityTaskComp 59: *ComActivityTaskComp(actId)    # 战力达标活动
        fateWheel 60: *ComFateWheelActivityInfo(id)     # 命运之轮
        cityPveData 62: ComCityPveOnhookData                # 内城PVE挂机数据
        activityShop  63: *ComActivityShop(activityId)      # 活动商店数据
        activityCommonTask 64: *ComActivityCommonTask(actId)# 通用活动任务
        activityNewbieGrowth 65: *ComActivityNewbieGrowth(actId)  # 新手成长活动
        tide               66: ComTide                      # 潮汐数据
        tideRuins          67: *ComIntInt()                 # 潮汐废墟数据
        activityTotalSignIn 68: *ComActivityTotalSignIn(actId)  # 累计签到活动
        recruitComp        69: *ComRecruitComp(activityId)  # 招募组件
        activityDungeonReward 70: *ComActivityDungeonReward(actId)  # 副本额外奖励
        activityPersonalScore 71: *ComActivityPersonalScore(actId)  # 个人积分
        tideSuccess         72: *ComIntInt()                # 潮汐废墟数据
        cityAreaUnlock 73: *ComCityAreaUnlock(areaCfgId)    # 区域解锁
        pay 74: *PayGoods()                                 # 支付
        activityAchieveCastle 75: *ComActivityAchieveCastle(actId)    # 城堡等级达标活动
        activityAllianceScore 76: *ComActivityAllianceScore(actId)    # 联盟积分活动
        activityExtraDrop 77: *activityExtraDrop(actId)    # 掉落活动
        activityKraken 78: *ComActivityKraken(actId)    # 克拉肯的复仇活动
        clientData 79: ComClientData                # 客户端引导数据
        skinData 80: ComSkinData                       # 皮肤(装饰)数据
        activityStrongestLord 81: *StrongesLordInfo(actId)  # 最强领主
        systemOfAWard 82: *integer                          # 领奖的系统ID
        shopFreeRefresh 83: *ComShopRefresh(shopId)         # 商店免费刷新
        shopFreeSlots 84: *ComShopFreeSlot(shopId)          # 商店免费槽位
        markCoordinates 85: *ComMarkCoordinates()           # 标记的坐标
        applySkins 86: *ComIntInt()                         # 应用的皮肤（skinCfgId->lv）
        payFirstReward 87 : PayFirstRewardInfo           # 首充奖励
        activityAccumulateRecharge 88 : *AccumulateRechargeInfo(actId) # 累计充值
        activityContinuousRecharge 89 : *ContinuousRechargeInfo(actId) # 连续充值
        privilegeCard 90 : *ComPrivilegeCard(cfgId) # 特权卡数据
        campongData 91: ComCampongWarData                   # 聚落战争数据
        kingWarData 92: ComKingWarData                      # 王战数据
        mileStoneData 93: *ComMileStoneData(id)             # 里程碑数据(当前进行中的)
        allianceJoin 94: ComAllianceJoin                   #加入联盟数据
        activityPass 95: *ComActivityPassInfo(actId)             # 通行证活动数据
        settings 96: *ComIntInt()                          # 游戏设置 (settingOpenId->value)
        activitySkinCollect 97: *ComActivitySkinCollectInfo(actId) # 皮肤收集活动
        activityGift 98: *ActivityGiftMap()    # 自选礼包活动
        community 99: ComCommunity    # 访问社区奖励数据
        cityBlock 101: ComCityBlock                         # 内城积木数据
        push 102: *pushEventMap()                           # 推送事件开关数据
        freeList 103: *ComTerritoryGainFreeItem(territoryGainFreeId) #领地增益数据
        serverInfo 104: *ComServerInfo(serverId)            # 游服信息
        guideData 105: *ComGuideData(guideId)               #引导数据
        onlineReward 106: ComOnlineRewardData               # 在线奖励数据
        lordOutfit 107: ComLordOutfitData                   # 领主装备数据
        activityAncientSearch 108: *ComActivityAncientSearch(actId) # 新手古迹探险活动
        allianceBlock 109: ComSyncAllianceBlock             # 联盟积木
        #actBoss 110: ComActBoss                            # boss活动 屏蔽
        lordTalent 111: ComLordTalent                       # 领主天赋数据
        barrierRogue 112: ComBarrierRogue                   # 肉鸽副本
        allianceAltar 113: ComSyncAllianceAltar             # 联盟祭坛
        invitedMoveCastle 114: ComSyncInvitedMoveCastle     # 被邀请迁城
        allianceCreate 115: ComSyncAllianceCreate           # 联盟创建变化
        svrItems 116: *ComIntInt()                          # 全服物品信息
        freeResurrectArmy 117: *ComArmyIdAndNum()           # 免费可复活士兵(募兵营)
        paidResurrectArmy 118: *ComArmyIdAndNum()           # 付费可复活士兵(募兵营)
        resurrectInfo 119 : ComResurrectInfo                # 复活信息(募兵营)
        kingWarResurrectArmy 120: *ComArmyIdAndNum()        # 王战复活士兵(当前剩余)
        kingWarResurrectInfo 121: ComKingWarResurrect       # 王战复活士兵信息
        arena 122: *ComArena(actId)                         # 竞技场信息
        kingWarResurrectHelp 123: *ComAllianceResurrectHelp(uid) # 王战复活士兵帮助信息
        serverSettings 124: *ComIntString()                   # 后台设置
        cityWall 125: ComCityWall                           # 城墙数据
        equip 126: ComEquipData                             # 装备操作数据
        npcTrailData 127: ComNpcTrialData                   # 怪物试炼数据
        activityPeakArena 128: *PeakArenaInfo(actId)        # 巅峰竞技场
        activityParade 129: *ComParadeActInfo(actId)        # 游园会活动
        seasonData 130: ComSeasonData                       # 赛季数据
        personPvp 131: *ComPersonPvpActInfo(actId)          # 赛季个人pvp
        gvgTeam 132: ComSyncAllianceGvgTeam                 # 联盟 gvg队伍
        crossWarData 133: ComCrossWarData                   # 跨服战数据
        earlyGoals 134: *ComIntBool()                     # 前期阶段目标
        innerCityBlock 135: ComInnerCityBlockData           # 内城地块数据
        furniture 136: *ComFurniture(id)                    # 建筑家具信息
        innerCityResident 137: ComInnerCityResident         # 内城居民信息
        npcReward 138: *ComNpcReward(id)                    # 怪物奖励数据
        basicRess 139: *ComBasicRess(cfgId)                 # 基础资源
        innerCityDecree 140: *ComResidentDecree(decreeId)   # 公民会议
        heroLevelResonanceDiscount 141: integer             # 英雄等级共鸣折扣
        deadArmy 142: *ComArmyIdAndNum()                    # 募兵营中等待复活的死亡士兵
        pendingResurrectDeadArmy 143: *ComArmyIdAndNum()    # 募兵营中复活完成待收取的士兵
        opinionBox 144: ComOpinionBox                       # 民意信箱
        equipSlot 145: *ComIntInt()                         # 装备栏位数据
        recruit 146: *ComRecruitInfo(id)                    # 招募信息
        modifiedTankBase 147: ComModifiedTankBase           # 改装车基础数据
        modifiedTankParts 148: *ComModifiedTankPart(partType)   # 改装车零件数据
        radarTypeBase 149: *ComRadarTypeBase(radarType)     # 不同雷达类型的数据
        invasionBoss 150: *ComInvasionBossActInfo(actId)    # 沙盘boss暴君降临
        xGamePlay 151: *ComIntBool()                        # x玩法                 
        activityPersonalScoreBase 152: ComActivityPersonal  # 个人积分活动数据
        escortTruck 153: ComEscortTruck                     # 运输车
        dailyAttackBoss 154: ComDailyAttackBossBase         # 每日攻打boss活动
        activityMonsterHunt 155: *MonsterHuntInfo(actId)    # 异兽追捕活动
        satisfactionPoints 157: *ComSatisfactionPoint(cfgId)     # 满意度
        dailyShadowTasks 158: ComDailyShadowTasks           # 暗影任务
        dailyShadowBase 159: ComDailyShadowBase             # 暗影任务基础数据
        allianceHelp 160: ComPlayerAllianceHelp             # 玩家联盟帮助数据
        rebelInvasion 161: ComRebelInvasion                 # 叛军入侵
        rebelRaid 162: *ComRaidTask(taskId)                 # 叛军突袭 
        allianceDuel 163: ComActivityAllianceDuel           # 联盟对决活动
        payCumulative 164: *ComPayCumulative(goodsId)       # 购买礼包后，每日给奖励
        chatEmoji 165: *ComIntBool()                        # 聊天表情
        kingWarOfficialOpt 166: ComOfficialOpt              # 王战官职操作信息
        activityHeroTrain 167: *ComActHeroTrain(actId)      # 英雄训练活动
        activityContinuousStoredValue 168: *ComContinuousStoredValue(actId) # 末日宝藏手册
        kingWarScore 169: ComKingWarScore                   # 王战积分
        activityPuzzle 170: *ComActPuzzle(actId)            # 拼图活动
        actDaggerThrowing 171: *ComActDaggerThrowing(actId) # 飞刀活动
        trainInspectList 172: *ComTrainInspect(cfgId)       # 暗区行动 （养成校验）
        queueTry 173: *ComIntInt()                          # 队列试用
        trainInspectBase 174: ComTrainInspectBase           # 暗区行动 （养成校验）数据
        trainInspectRecord 175: *ComTrainInspectRecord(id)  # 暗区行动 （养成校验）战斗记录
        fishGuideBase 176: ComFishGuideBase                 # 钓鱼图鉴基础信息
        fishGuideList 177: *ComFishGuide(id)                # 钓鱼图鉴鱼列表
        actFish 178: *ComActFish(actId)                     # 钓鱼活动
        actConsecutiveSignIn 179: *ComActConsecutiveSignIn(actId) # 连续签到活动
        championshipDuel 180: *ComChampionshipDuelData(actId) # 冠军对决活动
        actFishBase 181: ComActFishBase                     # 钓鱼活动基本信息
        actFishAllianceReward 182: *ComActFishAllianceReward(actId) # 钓鱼联盟宴会活动
        actFishShop 183: *ComActFishShop(actId)             # 钓鱼商店活动
        innerCityRegion 184: ComInnerCityRegion             # 收复区域
        innerCityRevival 185: ComInnerCityRevival           # 复兴城镇
        activityAllianceHelp 186: ComActivityAllianceHelp   # 联盟帮助活动
    }
}

syncPlayerInfo 23 {                                         # 同步玩家数据
    request {
        army 2: ComSyncDataArmy                             # 士兵信息
        woundedArmy 3: ComSyncDataArmy                      # 伤兵信息
        lord 4: ComLord                                     # 玩家基础信息
        hero 5: ComSyncDataHero                             # 英雄信息
        world 6: ComWorld                                   # 世界信息
        item 7: ComSyncDataItem                             # 物品信息
        attribute 8: ComSyncDataAttribute                   # 属性信息
        city 9: ComSyncDataCity                             # 建筑信息
        queue 10: ComSyncDataQueue                          # 队列信息
        openQueueCfgIds 11: ComSyncDataQueueCfgIds          # 开放的队列配置id信息
        buff 12: ComSyncDataBuff                            # buff信息
        unlockArmyCfgIds 13: *integer                       # 已解锁士兵列表
        pendingArmy 15: ComSyncDataPendingArmy              # 待收取士兵
        resProduce 16: ComSyncDataResProduce                # 资源生产
        mailUnRead 17: ComMailUnread                        # 邮件未读信息
        task 18: ComSyncDataTask                            # 任务信息
        warehouse 19: ComSyncDataWarehouse                  # 仓库
        formations 20: ComSyncDataFormation                 # 布阵
        technology 21: ComSyncDataTechnology                # 科技
        shop 22: ComSyncDataShop                            # 商店
        systemOpen 24: *integer                             # 系统开启ID
        recycleBuildings 26: ComSyncDataRecycleBuildings    # 回收建筑
        heads 27: ComSyncHead                               # 头像
        headFrames 28: ComSyncHeadFrame                     # 头像框
        physicalStrength 29: ComPhysicalStrength            # 体力
        upgradeArmy 30: ComSyncDataArmy                     # 升级士兵信息
        pendingHealArmy 31: ComSyncDataPendingHealArmy      # 待收取治疗士兵
        taskDay 32: ComTaskDay                              # 每日任务
        taskChapter 33: ComTaskChapter                      # 章节任务
        recruitPoint 34: integer                            # 招募积分
        barrierData 35: ComBarrierModuleData                # 副本数据
        radarEvents 36: ComSyncRadarEvent                   # 雷达事件
        radarBase   37: ComRadarBase                        # 雷达基本数据
        lordStat 38: ComSyncLordStatData               # 累计数据领主统计
        lordKillNormalMonsterStat 39: ComSyncLordStatData   # 击杀普通怪领主统计
        power 40: ComPower                                  # 战力
        allianceTechnology 41: ComSyncAllianceTechnology    # 联盟科技
        allianceInvite 42: ComSyncAllianceInvite            # 联盟邀请
        allianceGift 47: ComSyncDataAllianceGift            # 联盟礼物与宝箱
        heroBackground 43: ComSyncHeroBackground            # 英雄背景数据
        taskAllianceNovice 44: ComTaskAllianceNovice        # 联盟新手任务
        heroLevelResonance 45: ComSyncHeroLevelResonance    # 英雄等级共鸣
        resonanceHeroTemplate 46: *integer                  # 共鸣英雄模版
        achievementBadges 48: *integer                      #获得的成就徽章
        achievementBadgesShow 49: *integer                  #成就徽章展示列表
        vip 50: ComVip                                      # vip数据更新
        achievementPoints 51: ComSyncAchievementPoint       #成就积分
        achievementBoxs 52: *integer                        #成就宝箱
        heroRelationshipRewardList 55: *integer             #英雄羁绊已经领取奖励列表
        assetsLimit 53: ComAssetsLimit                      # 资产获得限制更新
        activity 56: ComSyncActivity                        # 同步活动
        activityAgenda 57: ComSyncActivityAgenda            # 同步活动日程
        activityTaskComp 58: ComSyncActivityTaskComp        # 达标活动组件数据更新
        fateWheel 59: ComSyncFateWheelActivityInfo          # 命运之轮
        cityPveData 61: ComCityPveOnhookData                # 内城PVE挂机数据
        activityShop  62: ComSyncActivityShop               # 活动商店数据
        activityCommonTask 64: ComSyncActivityCommonTask    # 通用活动任务
        activityNewbieGrowth 65: ComSyncActivityNewbieGrowth      # 新手成长活动
        tide               66: ComTide                      # 潮汐数据
        tideRuins          67: ComSyncTideRuins             # 潮汐废墟数据
        activityTotalSignIn 68: ComSyncActivityTotalSignIn  # 活动任务&积分
        recruitComp        69: ComSyncRecruitComp           # 招募组件
        activityDungeonReward 70: ComSyncActivityDungeonReward  # 副本额外奖励
        activityPersonalScore 71: ComSyncActivityPersonalScore  # 个人积分
        tideSuccess          72: ComSyncTideSuccessMonsters     # 潮汐成功
        cityAreaUnlock 73: ComSyncDataCityAreaUnlock        # 区域解锁
        pay 74: ComSyncPay                                  # 支付
        activityAchieveCastle 75: ComSyncActivityAchieveCastle  # 城堡等级达标活动
        activityAllianceScore 76: ComSyncActivityAllianceScore  # 联盟积分活动
        activityExtraDrop 77: ComSyncActivityExtraDrop      # 掉落活动
        activityKraken 78: ComSyncActivityKraken            # 克拉肯的复仇活动
        clientData 79: ComSyncClientData              # 客户端数据 引导
        activityStrongestLord 80: ComSyncStronestLord       # 最强领主
        systemOfAWard 82: *integer                          # 领奖的系统ID
        shopFreeRefresh 83: ComSyncShopRefresh              # 商店免费刷新
        shopFreeSlots 84: ComSyncShopFreeSlot               # 商店免费槽位
        markCoordinates 85: ComSyncMarkCoordinate           # 标记的坐标
        applySkins 86: ComSyncApplySkins                    # 应用的皮肤
        payFirstReward 87 : PayFirstRewardInfo           # 首充奖励
        activityAccumulateRecharge 88 : ComAccumulateRecharge # 累计充值
        activityContinuousRecharge 89 : ComContinuousRecharge # 连续充值
        privilegeCard 90 : ComSyncPrivilegeCard # 特权卡数据更新
        campongData 91: ComCampongWarData                   # 聚落战争数据
        kingWarData 92: ComKingWarData                      # 王战数据
        mileStoneData 93: *ComMileStoneData(id)             # 里程碑数据(当前进行中的)
        allianceJoin 94: ComAllianceJoin                    # 加入联盟数据
        activityPass 95:  ComActivityPass                   # 通行证
        settings 96: ComSyncSettings                        # 游戏设置
        activitySkinCollect 97: ComActivitySkinCollect      # 皮肤收集活动
        activityGift 98: ComActivityGift                    # 自选礼包活动
        community 99: ComCommunity                          # 访问社区奖励数据
        cityBlock 101: ComCityBlock                         # 内城积木数据
        freeList 103: ComSyncTerritoryGain                  # 领地增益数据
        serverInfo 104: ComSyncServerInfo                   # 游服信息同步
        guideData 105: ComSyncGuideData                     # 引导数据
        onlineReward 106: ComOnlineRewardData               # 在线奖励数据
        lordOutfit 107: ComSyncLordOutfitData               # 更新领主装备数据
        activityAncientSearch 108: ComSyncActivityAncientSearch # 新手古迹探险活动
        allianceBlock 109: ComSyncAllianceBlock             # 联盟积木
        #actBoss 110: ComActBoss                            # boss活动 屏蔽
        barrierRogue 112: ComSyncBarrierRogue               # 肉鸽副本
        allianceAltar 113: ComSyncAllianceAltar             # 联盟祭坛
        invitedMoveCastle 114: ComSyncInvitedMoveCastle     # 被邀请迁城
        allianceCreate 115: ComSyncAllianceCreate           # 联盟创建变化
        svrItems 116: ComSyncSvrItem                        # 全服物品信息
        freeResurrectArmy 117: ComSyncDataArmy              # 免费可复活士兵(募兵营)
        paidResurrectArmy 118: ComSyncDataArmy              # 付费可复活士兵(募兵营)
        resurrectInfo 119 : ComResurrectInfo                # 复活信息(募兵营)
        kingWarResurrectArmy 120: ComSyncDataArmy           # 王战复活士兵(当前剩余)
        kingWarResurrectInfo 121: ComKingWarResurrect       # 王战复活士兵信息
        arena 122: ComSyncArena                             # 竞技场
        kingWarResurrectHelp 123: ComSyncAllianceResurrectHelp # 王战复活士兵帮助信息
        serverSettings 124: ComSyncServerSettings           # 后台设置
        cityWall 125: ComCityWall                           # 城墙数据
        equip 126: ComEquipData                             # 装备操作数据
        npcTrailData 127: ComNpcTrialData                   # 怪物试炼数据
        activityPeakArena 128: ComSyncPeakArena             # 巅峰竞技场数据
        activityParade 129: ComSyncActivityParade           # 游园会活动

        seasonData 130: ComSyncSeasonData                   # 赛季数据
        personPvp 131: ComSyncPersonPvpActInfo              # 赛季个人pvp
        gvgTeam 132: ComSyncAllianceGvgTeam                 # 联盟 gvg队伍
        crossWarData 133: ComCrossWarData                   # 跨服战数据

        earlyGoals 134: ComSyncEarlyGoals                   # 前期阶段目标
        innerCityBlock 135: ComSyncInnerCityBlockData       # 内城地块数据
        furniture 136: ComSyncFurniture                     # 建筑家具信息
        innerCityResident 137: ComSyncDataInnerCityResident # 内城居民信息
        npcReward 138: ComSyncNpcReward                     # 怪物奖励数据
        basicRess 139: ComSyncBasicRess                     # 基础信息
        innerCityDecree 140: ComSyncResidentDecree          # 公民会议
        heroLevelResonanceDiscount 141: integer             # 英雄等级共鸣折扣
        deadArmy 142: ComSyncDataArmy                       # 募兵营中等待复活的死亡士兵        
        pendingResurrectDeadArmy 143: ComSyncDataPendingHealArmy # 募兵营中复活完成待收取的士兵
        opinionBox 144: ComSyncOpinionBox                   # 民意信箱
        equipSlot 145: ComSyncEquipSlot                     # 装备栏位数据
        recruit 146: ComSyncRecruitInfo                     # 招募信息
        modifiedTankBase 147: ComModifiedTankBase           # 改装车基础数据
        modifiedTankParts 148: ComSyncModifiedTankPart      # 改装车零件数据
        radarTypeBase 149: ComSyncRadarTypeBase             # 不同雷达类型的数据
        invasionBoss 150: ComSyncInvasionBossActInfo        # 沙盘boss暴君降临
        xGamePlay 151: *ComIntBool()                      # x玩法
        activityPersonalScoreBase 152: ComActivityPersonal  # 个人积分活动数据
        escortTruck 153: ComSyncEscortTruck                 # 运输车
        dailyAttackBoss 154: ComDailyAttackBossBase         # 每日攻打boss活动
        activityMonsterHunt 155: ComSyncMonsterHunt         # 异兽追捕活动
        skinData 156: ComSyncSkinPack                       # 皮肤信息同步
        satisfactionPoints 157: ComSyncSatisfactionPoint    # 满意度
        dailyShadowTasks 158: ComSyncDailyShadowTasks       # 暗影任务
        dailyShadowBase 159: ComDailyShadowBase             # 暗影任务基础数据
        allianceHelp 160: ComPlayerAllianceHelp             # 玩家联盟帮助数据
        rebelInvasion 161: ComSyncDataRebelInvasion         # 叛军入侵
        rebelRaid 162: ComSyncDataRebelRaid                 # 叛军突袭 
        allianceDuel 163: ComActivityAllianceDuel           # 联盟对决活动
        payCumulative 164: ComSyncPayCumulative             # 购买礼包后，每日给奖励
        chatEmoji 165: ComSyncDataChatEmoji                 # 聊天表情
        kingWarOfficialOpt 166: ComSyncOfficialOpt          # 王战官职操作信息
        activityHeroTrain 167: ComSyncActHeroTrain          # 英雄训练活动
        activityContinuousStoredValue 168: ComSyncContinuousStoredValue # 末日宝藏手册
        kingWarScore 169: ComKingWarScore                   # 王战积分
        activityPuzzle 170: ComSyncActPuzzle                # 拼图活动
        actDaggerThrowing 171: ComSyncActDaggerThrowing     # 飞刀活动
        trainInspectList 172: ComSyncTrainInspect           # 暗区行动 （养成校验）
        queueTry 173: ComSyncQueueTry                       # 队列试用
        trainInspectBase 174: ComTrainInspectBase           # 暗区行动 （养成校验）数据
        trainInspectRecord 175: ComSyncTrainInspectRecord   # 暗区行动 （养成校验）战斗记录
        fishGuideBase 176: ComFishGuideBase                 # 钓鱼图鉴基础信息
        fishGuideList 177: ComSyncFishGuide                 # 钓鱼图鉴鱼列表
        actFish 178: ComSyncActFish                         # 钓鱼活动
        actConsecutiveSignIn 179: ComSyncActConsecutiveSignIn # 连续签到活动
        championshipDuel 180: ComSyncChampionshipDuelData   # 冠军对决活动
        actFishBase 181: ComActFishBase                     # 钓鱼活动基本信息
        actFishAllianceReward 182: ComSyncActFishAllianceReward # 钓鱼联盟宴会活动
        actFishShop 183: ComSyncActFishShop                 # 钓鱼商店活动
        innerCityRegion 184: ComSyncDataInnerCityRegion     # 收复区域
        innerCityRevival 185: ComSyncInnerCityRevival       # 复兴城镇
        activityAllianceHelp 186: ComActivityAllianceHelp   # 联盟帮助活动
    }
}

syncLoginDataFinish 24 {                                    # 登陆数据发送成功
    request {
        
    }
}

]]

return playeInfoProto