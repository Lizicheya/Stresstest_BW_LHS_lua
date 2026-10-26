local protoFiles = {
    --登陆临时放这里
    "sproto.login.loginproto",
    -- 10~20
    "sproto.game.frameworkProto",
    --通用玩家信息模块 21~40
    "sproto.game.playerInfoProto",
    --场景模块 41~200
    "sproto.game.sceneProto",
    --物品模块 201~300
    "sproto.game.itemProto",
    --建筑模块 301~400
    "sproto.game.cityProto",
    --队列模块 401~500
    "sproto.game.queueProto",
    --buff模块 501~600
    "sproto.game.buffProto",
    --英雄模块 601~700
    "sproto.game.heroProto",
    --查询模块 801~900
    "sproto.game.queryProto",
    --试炼模块 901~1000
    "sproto.game.trialProto",
    --士兵模块 1001~1100
    "sproto.game.armyProto",
    --资源收集模块 1101~1200
    "sproto.game.resProduceProto",
    -- 任务模块 1200~1300
    "sproto.game.taskProto",
    -- 邮件模块 1300~1400
    "sproto.game.mailProto",
    --阵型模块 1400~1500
    "sproto.game.formationProto",
    --科技模块 1500~1600
    "sproto.game.technologyProto",
    --联盟模块 1601~1800
    "sproto.game.allianceProto",
    --联盟通用信息模块 1801~1900
    "sproto.game.allianceInfoProto",
    --商店模块 2601~2700
    "sproto.game.shopProto",
    --系统开启模块 2701~2800
    "sproto.game.systemOpenProto",
    --资源交换模块 2801~2900
    "sproto.game.resExchangeProto",
    --招募 2901~3000
    "sproto.game.recruitProto",
    --领主信息 3001~3100
    "sproto.game.lordProto",
    --英雄装备 3101~3200
    "sproto.game.equipProto",
    --联盟帮助 3201~3300
    "sproto.game.allianceHelpProto",
    -- 探索大厅与副本 3301~3400
    "sproto.game.barrierProto",
    -- 雷达 3401~3500
    "sproto.game.radarProto",
    -- 联盟科技 3501 ～3600
    "sproto.game.allianceTechnologyProto",
    -- 联盟建筑 3601 ~ 3700
    "sproto.game.allianceBuildProto",
    -- 城墙 3701 ~ 3800
    "sproto.game.cityWallProto",
    --联盟任务 3801 ~ 3900
    "sproto.game.allianceTaskProto",
    --里程碑任务 3901 ~ 4000
    "sproto.game.mileStoneProto",
    --排行榜 4001 ~ 4100
    "sproto.game.rankProto",
    --联盟礼物与宝箱 4101 ~ 4200
    "sproto.game.allianceGiftProto",
    --联盟道具（联盟仓库） 4201 ~ 4300
    "sproto.game.allianceItemProto",
    --联盟兑换 4301 ~ 4400
    "sproto.game.allianceResExchangeProto",
    --成就 4401 ~ 4500
    "sproto.game.achievementProto",
    --内城怪物 4501 ~ 4600
    "sproto.game.cityMonsterProto",
    --vip 4601 ~ 4700
    "sproto.game.vipProto",
    -- activity 4701 ~ 4800
    "sproto.game.activityProto",
    -- 战力达标活动 4801 ~ 4900
    "sproto.game.activityTaskCompProto",
    -- campongWar 4901 ~ 5000
    "sproto.game.campongWarProto",
     -- fateWheel 5001 ~ 5100
    "sproto.game.activityFateWheelCompProto",
     -- cityPve 5101 ~ 5200
     "sproto.game.cityPveProto",
    -- 活动 新手成长 组件 5201 ~ 5300
    "sproto.game.activityNewbieGrowthProto",
    -- 活动 累计签到领奖 组件 5301 ~ 5400
    "sproto.game.activityTotalSignInCompProto",
    -- 活动 副本额外奖励 5401 ~ 5500
    "sproto.game.activityDungeonRewardProto",
    -- 活动 个人积分 5501 ~ 5600
    "sproto.game.activityPersonalScoreProto",
    -- 支付 5601 ~ 5700
    "sproto.game.payProto",
    -- 区域解锁 5701 ~ 5800
    "sproto.game.cityAreaUnlockProto",
    -- 城堡等级达标活动 5801 ~ 5900
    "sproto.game.activityAchieveCastleProto",
    -- 克拉肯的复仇活动 5901 ~ 6000
    "sproto.game.activityKrakenProto",
    -- 联盟积分活动 6001 ~ 6100
    "sproto.game.activityAllianceScoreProto",
    -- 掉落活动 6101 ~ 6200
    "sproto.game.activityExtraDropProto",
    -- 客户端数据 6201 ~ 6300
    "sproto.game.clientDataProto",
    -- 皮肤（装饰） 6301 ~ 6400
    "sproto.game.skinProto",
    -- 最强领主活动 6401 ~ 6500
    "sproto.game.activityStrongestLordProto",
    -- 首充奖励 6501 ~ 6510
    "sproto.game.payFirstRewardProto",
    -- 累计充值 6511 ～6520
    "sproto.game.activityAccumulateRechargeProto",
    -- 连续充值 6521 ～6530
    "sproto.game.activityContinuousRechargeProto",
    -- 特权卡 6601 ～6300
    "sproto.game.privilegeCardProto",
    -- kingWar 6701 ~ 6750
    "sproto.game.kingWarProto",
    -- 联盟祭坛 6751 ~ 6800
    "sproto.game.allianceAltarProto",
    -- 通行证活动 6801 ~ 6850
    "sproto.game.activityPassProto",
    -- 设置 6851 ～ 6870
    "sproto.game.settingProto",
    -- 皮肤收集活动 6871 ～ 6880
    "sproto.game.activitySkinCollectProto",
    -- 自选礼包活动 6881 ~ 6890
    "sproto.game.activityGift",
    -- 联盟标记 6891 ~ 6910
    "sproto.game.allianceMarkProto",
    --领地增益  6921 ~ 6930
    "sproto.game.territoryGainProto",
    --访问社区奖励  6931 ~ 6940
    "sproto.game.communityProto",
    -- 推送 6941 ~ 6950
    "sproto.game.pushProto",
    -- 联盟怪物攻城 6951 ~ 6980
    "sproto.game.activityMonsterSiegeProto",
    -- 联盟操作日志 6981 ~ 6990
    "sproto.game.allianceOperLogProto",
    -- 游服信息 6991 ~ 7000
    "sproto.game.serverInfoProto",
    -- 角色信息 7101 ~ 7200
    "sproto.game.roleProto",
    -- 引导数据 7201 ~ 7210
    "sproto.game.guideDataProto",
    -- 在线奖励 7211 ~ 7220
    "sproto.game.onlineRewardProto",
    -- 领主装备 7221 ~ 7230
    "sproto.game.lordOutfitProto",
    -- 新手活动古迹探险 7231 ~ 7250
    "sproto.game.activityAncientSearchProto",
    -- boss活动 7051 ~ 7100
    "sproto.game.actBossProto",
    -- 领主天赋卡牌 7251 ~ 7270
    "sproto.game.lordTalentProto",
    -- 探索肉鸽副本 7271 ~ 7350
    "sproto.game.barrierRogueProto",
    -- 复活-募兵营 7401 ~ 7425
    "sproto.game.resurrectProto",
    -- 翻译 7431 ~ 7440
    "sproto.game.translateProto",
    -- 跑马灯（推送通知） 7441 ~ 7450
    "sproto.game.pushNotifyProto",
    -- 属性及加成显示 7451 ~ 7470
    "sproto.game.attributeDisplayProto",
    -- 竞技场 7471 ~ 7500
    "sproto.game.arenaProto",
    -- 巅峰竞技场 7501 ~ 7550
    "sproto.game.activityPeakArenaProto",
    -- 怪物试炼 7551 - 7600
    "sproto.game.npcTrialProto",
    -- 游园会活动 7601 ～ 7650
    "sproto.game.activityParadeProto",
    -- 赛季 7651-7700
    "sproto.game.seasonProto",
    -- 赛季个人pvp 7701 ～ 7750
    "sproto.game.personPvpProto",
    -- 赛季战场 7751 ～ 7800
    "sproto.game.seasonGvgWarProto",
    -- 友盟 7801 ～ 7850
    "sproto.game.allianceUnitedAlliancesProto",
    -- 联盟队伍 7851 ～ 7900
    "sproto.game.allianceGvgTeamProto",
    -- 跨服战 7901 ~ 7950
    "sproto.game.crossWarProto",
    -- 前期目标 7951 ~ 7970
    "sproto.game.earlyGoalsProto",
    -- 内城地块 7971 ~ 8000
    "sproto.game.innerCityBlockProto",
    -- 内城居民 8001 ~ 8050
    "sproto.game.cityResidentProto",
    -- 打野奖励展示 8051 ~ 8060
    "sproto.game.npcRewardProto",
    -- 基础资源 8071～8090
    "sproto.game.basicRessProto",
    -- 民意信箱 8091～8110
    "sproto.game.opinionBoxProto",
    -- 押运货车 8111～8150
    "sproto.game.escortTruckProto",
    -- 改装车 8151～8180
    "sproto.game.modifiedTankProto",
    -- 沙盘集体boss 8181 ~ 8230
    "sproto.game.invasionBossProto",
    -- 联盟领地 8231 ~ 8300
    "sproto.game.allianceTerritoryProto",
    -- 每日打boss 8301 ~ 8330
    "sproto.game.dailyAttackBossProto",
    -- 活动异兽追捕 8331 ~ 8380
    "sproto.game.activityMonsterHuntProto",
    -- 暗影行动 8381 ~ 8430
    "sproto.game.shadowProto",
    -- 联盟聊天红包 8431 ~ 8450
    "sproto.game.allianceChatBonusProto",
    -- 叛军入侵 8451 ～ 8480
    "sproto.game.rebelProto",
    -- 联盟对决 8481 ～ 8580
    "sproto.game.allianceDuelProto",
    -- x玩法 8581 ～ 8610
    "sproto.game.xGameplayProto",
    -- 礼包累计给奖 8611 ～ 8630
    "sproto.game.payCumulativeProto",
    -- 英雄训练活动 8631 ～ 8680
    "sproto.game.activityHeroTrainProto",
    -- 末日宝藏手册 8681 ～ 8700
    "sproto.game.activityContinuousStoredValueProto",
    -- 联盟活动日历 8701 ～ 8720
    "sproto.game.allianceActivityCalendarProto",
    -- 拼图活动 8721 ～ 8750
    "sproto.game.activityPuzzleProto",
    -- 飞刀活动 8751 ～ 8780
    "sproto.game.activityDaggerThrowingProto",
    -- 暗区行动 （养成校验） 8781 ~ 8810
    "sproto.game.trainInspectProto",
    -- 冠军对决活动 8810 ～ 8860
    "sproto.game.championshipDuelProto",
    -- 钓鱼图鉴 8861 ~ 8890
    "sproto.game.fishGuideProto",
    -- 钓鱼活动 8891 ~ 8920
    "sproto.game.activityFishProto",
    -- 连续签到活动 8921 ~ 8950
    "sproto.game.activityConsecutiveSignInProto",
    -- 钓鱼联盟宴会活动 8951 ~ 8980
    "sproto.game.activityFishAllianceRewardProto",
    -- 黑金战场 9001 ～ 9050
    "sproto.game.activityBlackGoldWarProto",
    -- 钓鱼商店活动 9051 ~ 9080
    "sproto.game.activityFishShopProto",
    -- 收复区域 9081 ~ 9090
    "sproto.game.innerCityRegionProto",
    -- 机器人玩家 9091 ~ 9120
    "sproto.game.robotUserProto",
    -- 属性统计 9121 ~ 9150
    "sproto.game.attributeStatProto",
    -- 复兴城镇 9151 ~ 9180
    "sproto.game.innerCityRevivalProto",
    -- 英雄属性来源 9181 ~ 9210
    "sproto.game.heroAttributeStatProto",
    -- 联盟帮助活动 9211 ～ 9240
    "sproto.game.activityAllianceHelpProto",
    -- 联盟任务 9241 ~ 9270
    "sproto.game.activityAllianceTaskProto",
}

return protoFiles
