local common = [[
    .ComArmyIdAndNum {
        id 0: uint32
        num 1: uint32
    }

    .ComTroopArmy {
        troopId 0: integer              #部队id
        army 1: *ComArmyIdAndNum()      #各兵种数量
    }

    .ComPath {
        x 0: double
        y 1: double
        time 2: double # 路段行军时间
        rate 3: double # 路段/总路程的比例
    }

    .ComPoint {
        x 0: integer
        y 1: integer
    }

    .ComIntBool {
        key 0: integer
        value 1: boolean
    }

    .ComIntInt {
        key 0: integer
        value 1: integer
    }

    .ComUint32Uint32 {
        key 0: integer
        value 1: integer
    }

    .ComIntDouble {
        key 0: integer
        value 1: double
    }

    .ComStringString {
        key 0: string
        value 1: string
    }

    .ComIntString {
        key 0: integer
        value 1: string
    }

    .ComRes {
        type 0: integer
        cfgId 1: integer
        num 2: integer
        isExchange 3: boolean # 是否是兑换获得的资源，比如英雄已经存在，会发给玩家碎片，这个时候isExchange为true
    }

    .ComPlayerBaseInfo {
        uid              0: integer                         # uid 
        headId           1 : integer                        # 头像id
        headFrame        2 : integer                        # 头像框id    
        allianceAbbName  3 : string                         # 联盟简称
        nickName         4 : string                         # 玩家昵称
        posX             5 : integer                        # 玩家位置x
        posY             6 : integer                        # 玩家位置y
    }

    .ComSkillSlot {
        slotId 1: integer                     # 技能槽
        lv 2 : integer                        # 技能槽等级
        skillIds 3 : *integer                 # 技能槽中的技能配置id
        bUnlock 4 : boolean                   # 是否已解锁
    }

    .ComHeroEquip {                             # 从英雄模块给客户端装备信息
        equipId 1: integer                      # id
        itemCfgId 2 : integer                   # itemCfgId
        lv 3: integer                           # 装备等级
        rankLv 4: integer                       # 装备阶数
    }

    .ComExclusiveEquipSkill {
        slotId 1: integer                    # 技能槽id
        skillIds 2: *integer                 # 技能id
    }

    .ComHero {
        heroCfgId 1: integer                    # 配置表id
        lv 2:integer                            # 等级
        skillSlots 3: *ComSkillSlot(slotId)     # 技能槽
        attrs 4: *ComIntInt()                   # 英雄属性信息
        starLv 5 : integer                      # 英雄星级
        power 6: integer                        # 英雄战力
        originalLv 7: integer                   # 原始等级
        lastResetLvTimeSec 8: integer           # 上次重置等级的时间戳
        resonanceLv 9 : integer                 # 共鸣等级
        equips 10: *ComHeroEquip(equipId)       # 装备，注意：其他模块要共用这个定义，不过英雄模块给客户端的信息中，没给这个字段
        isResonance 11: boolean                 # 是否共鸣，注意：其他模块要共用这个定义，不过英雄模块给客户端的信息中，没给这个字段
        honorLv 12: integer                     # 荣誉等级
        exclusiveEquipLv 13: integer            # 专属装备等级
        exclusiveEquipSkills 14: *ComExclusiveEquipSkill(slotId) # 专属装备技能
    }

    .ComArenaHeroEquip {
        equipId 1: integer
        itemCfgId 2: integer
        lv 3: integer           #装备等级
        rankLv 4: integer       #装备阶数
    }

    .ComArenaHero {
        heroCfgId 1: integer                    # 配置表id
        lv 2:integer                            # 等级
        skillSlots 3: *ComSkillSlot(slotId)     # 技能槽
        attrs 4: *ComIntInt()                   # 英雄属性信息
        equips 5: *ComArenaHeroEquip(equipId)   # 英雄装备
        starLv 6 : integer                      # 英雄星级
        power 7: integer                        # 英雄战力
        originalLv 8: integer                   # 原始等级
        lastResetLvTimeSec 9: integer           # 上次重置等级的时间戳
        skillPower 10: integer                  # 技能战力 客户端用
    }
    
    .ComHeroBrief {
        heroCfgId 1: integer                    # 配置表id
        lv 3:integer                            # 等级
        starLv 7 : integer                      # 英雄星级
        power 8: integer                        # 英雄战力
    }

    .ComHeroInterim { #临时的英雄,非养成类,可重复
        heroId 0: integer                       # 英雄ID
        heroCfgId 1: integer                    # 配置表id
        lv 3:integer                            # 等级
        skillSlots 4: *ComSkillSlot(slotId)     # 技能槽
        attrs 5: *ComIntInt()                   # 英雄属性信息
        starLv 7 : integer                      # 英雄星级
        power 8: integer                        # 英雄战力
        equips 9: *ComHeroEquip(equipId)        # 装备
        originalLv 10:integer                   # 原始等级
        isResonance  11:boolean                 # 是否共鸣
    }

    .ComHeroPersonPvp { #赛季个人pvp英雄
        heroCfgId 1: integer                    # 配置表id
        lv 3:integer                            # 等级
        skillSlots 4: *ComSkillSlot(slotId)     # 技能槽
        attrs 5: *ComIntInt()                   # 英雄属性信息
        starLv 7 : integer                      # 英雄星级
        power 8: integer                        # 英雄战力
        equips 9: *ComHeroEquip(equipId)        # 装备
        originalLv 10:integer                   # 原始等级
        isResonance  11:boolean                 # 是否共鸣
        isDisable 12: boolean                   # 是否禁用
        disableTs 13: integer                   # 禁用开始时间戳
    }

    .ComTroopLose {
        troopId 1 : integer                          # 部队id
        truce 2: *ComArmyIdAndNum()                  # 轻伤
        wound 3: *ComArmyIdAndNum()                  # 重伤
        dead  4: *ComArmyIdAndNum()                  # 死亡    
        remain 5: *ComArmyIdAndNum()                 # 生还
        totalHurt 6: integer                         # 总伤害
        allNum 7: integer                            # 总数量
        curLoseNum 8: integer                        # 损失数量
    }

    .ComSkillDmg {
        skillId   2: integer                    # 技能id
        dmg       3: integer                    # 技能击杀数量：技能造成伤害的数量
        heal      4: integer                    # 技能保护数量：技能护盾抵消士兵数+技能治疗士兵数
    }

    .ComHeroDmg {
        heroCfgId 1: integer                    # 英雄配置id
        skillDmg  2: *ComSkillDmg(skillId)      # 技能伤害数据
    }

    #伤害数据
    .ComTroopDmg {
        unitId 1 : integer                            # 方阵id
        armyNum 2 : integer                           # 初始兵量
        remain 3 : integer                            # 生还
        dmgNormal 4 : integer                         # 造成普攻伤害
        dmgSkill 5 : integer                          # 造成技能伤害
        dmgTaken 6 : integer                          # 承担伤害
        heroDmg  7 : ComHeroDmg                       # 英雄伤害数据
    }

    #各兵种战斗详情
    .ComTroopArmyDetail {
        armyId 1 : integer                           # 士兵id
        dmgTakenRate 2: integer                      # 承担伤害比例(万分比)
        dead  3: integer                             # 死亡
        wound 4: integer                             # 重伤 
        truce 5: integer                             # 轻伤
        remain 6: integer                            # 生还    
    }

    .ComTroopData {
        aliveNum 1: double
        allNum 2: double
    }
    
    .ComBattleResult { 
        attackTroopData 1: ComTroopData
        defendTroopData 2: ComTroopData
    }
    
    .ComLordBadgeInfo {
        pos 0: integer # 位置
        stage 1: integer # 当前阶级
    }

    .ComLordOutfitInfo {
        part 0: integer # 部位
        stage 1: integer # 当前阶级
        badgeList 2: *ComLordBadgeInfo(pos) # 装备宝石
    }

    .ComLordOutfitData {
        bShow 0: boolean # 是否展示
        outfitList 1: *ComLordOutfitInfo(part) # 装备列表
    }

    .ComLordOutfit  {
        bUnlockOutfit  1 : boolean                     # 宝物是否解锁
        bUnlockBadge  2 : boolean                      # 宝石是否解锁
        outfitList 3: *ComLordOutfitInfo(part)         # 装备列表
    }
    
    #部队增益界面
    .ComTotalAddAttrs {

        atkAdd 1: integer # 部队总攻击
        defAdd 2: integer # 部队总防御
        hpAdd 3: integer # 部队总生命
        dmgAdd 4: integer # 部队总伤害
        heroNormalDmgAdd 5: integer # 英雄普攻伤害

        atkAddCamp 6: integer # 阵营攻击
        defAddCamp 7: integer # 阵营防御
        hpAddCamp 8: integer # 阵营生命
        dmgAddCamp 9: integer # 阵营伤害
        campTag 10: integer # 阵营类型
        campHeroCount 11: integer # 阵营英雄数量
    }

    # 科技
    .ComTroopTechInfo {
        totalPower 1: integer # 科技总战力
        battleTechPower 2: integer # 战报科技战力（仅 BATTLE_REPORT_TECH_TYPE）
        techTypeProgress 3: *ComIntInt() # 科技分类进度 [type]=progress_sum
    }

    #战斗部队信息邮件一级界面
    .ComBattleTroopInfoBrief {
        troopId          1 : integer                        # 部队id
        objType          2 : integer                        # 部队类型: SceneObjType
        posX             3 : integer                        # 坐标X
        posY             4 : integer                        # 坐标Y
        allianceAbbName  5 : string                         # 联盟简称
        nickName         6 : string                         # 玩家昵称
        headId           7 : integer                        # 头像id
        headFrame        8 : integer                        # 头像框id
        playerUId        9: integer                         # 玩家部队 uid
        castleLv         10:integer                         # 玩家城堡等级
        leaderTroopId    11:integer                         # 集结部队队长troopId
        aid              12 : integer                       # 联盟id
        uids             13 : *integer                      # 成员uids --集结部队，建筑驻防部队

        spvpBuildCfgId   14 : integer                       # 赛季pvp建筑配置id积分矿或仓库配置id SeasonPvpElements.id
        npcCfgId         15 : integer                       # 如果是怪物 配置id
        buildCfgId       16 : integer                       # 部队驻扎的系统城市或联盟建筑 配置id
        serverId         17: integer                        # 王国id
        aliveNum         18: integer                        # 生还数量
    }
    
    #战斗部队信息
    .ComBattleTroopInfo {
        troopId          1 : integer                        # 部队id
        objType          2 : integer                        # 部队类型: SceneObjType
        posX             3 : integer                        # 坐标X
        posY             4 : integer                        # 坐标Y
        allianceAbbName  5 : string                         # 联盟简称
        nickName         6 : string                         # 玩家昵称
        headId           7 : integer                        # 头像id
        headFrame        8 : integer                        # 头像框id
        playerUId        9: integer                         # 玩家部队 uid
        castleLv         10:integer                         # 玩家城堡等级
        leaderTroopId    11:integer                         # 集结部队队长troopId
        aid              12 : integer                       # 联盟id
        modifiedTank     13: ComModifiedTank4Troop          # 改装车信息        
        spvpBuildCfgId   14 : integer                       # 赛季pvp建筑配置id积分矿或仓库配置id SeasonPvpElements.id
        npcCfgId         15 : integer                       # 如果是怪物 配置id
        buildCfgId       16 : integer                       # 部队驻扎的系统城市或联盟建筑 配置id
        fightPower       17 : integer                       # 战力
        loseFightPower   18 : integer                       # 损失战力
        troopArmy        19 : *ComTroopArmy(troopId)        # 初始兵量
        
        removedTroopArmyTroopIds 20: *integer               # 删除的子部队id 更新用

        isOverLoad       24: boolean                       # 是否满负载
        heros            25:  *ComHero                      # 英雄
        attrs            26: *ComIntInt()                   # 属性
        campAttrs        27: *ComIntInt()                   # 阵营加成属性
        totalAddAttrs    28: ComTotalAddAttrs               # 部队增益属性总览
        techInfo 29: ComTroopTechInfo                     # 科技信息

        childTroops      30: *ComBattleTroopInfo            # 如果是集结部队 这里包含所有子部队数据

        rallyDmgAddRate  32:integer                         # 集结伤害增加万分比
        playerCapacity   33:integer                         # 集结人数上限
        capacity         34:integer                         # 部队容量
        targetId         35: integer                        # 目标id
        targetX          36: integer                        # 目标坐标
        targetY          37: integer                        # 目标坐标
        startWalkRateTS  38: double                         # 开始行走时间
        totalTime        39: double                         # 行走总时间
        endWalkRateTS    40: double                         # 结束行走时间
        stopDistance     41: double                         # 停止距离
        path             42: *ComPath                       # 路径

        lordOutfit       45 : ComLordOutfit                 # 领主宝物数据

        totalHp          49: integer                        # 总生命
        loseData         50 : *ComTroopLose(troopId)        # 战斗损失数据
        rewardList       51 : *ComRes                       # 奖励列表 打野或抢夺资源

        ##dmgData          51 : *ComTroopDmg(unitId)          # 战斗伤害数据   当前版本没有使用
        ##armyDetail       52 : *ComTroopArmyDetail(armyId)   # 各兵种战斗详情  当前版本没有使用
    }


    .ComConditionCompareData {
        compareType 1: integer
        data 2: *integer
    }

    .ComConditionConditionTypeData {
        conditionType 1: integer
        data 2: *integer
    }

    .ComCondition {
        compareData 0: ComConditionCompareData
        conditionTypeData 1: ComConditionConditionTypeData
    }
    
    .ComHeroFormation {
        key 0: uint32                                   # 位置
        value 1: ComHero                                # 英雄数据
    }

    .ComArenaHeroFormation {
        key 0: uint32                                   # 位置
        value 1: ComArenaHero                           # 英雄数据
    }

    # 队伍数据
    .ComArenaFormation {
        heroIds 1: *ComIntInt()                         # 英雄ID pos=>heroCfgId
        army 2: *ComArmyIdAndNum()                      # 各兵种数量 根据英雄带兵等级和容量确定兵数
        heros 3: *ComArenaHeroFormation()               # 英雄数据
        power 4: integer                                # 队伍战力
    }

    .ComArenaTeamDetail {                               # 阵容详情
        key 0: uint32                                   # 队伍编号
        value 1: ComArenaFormation                      # 队伍数据
    }

    .ComArenaTeam {
        key 0: uint32                # 队伍编号
        value 1: *ComUint32Uint32()  # 队伍数据 pos=>heroCfgId
    }

    .ComAllianceMemberInfo {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像
        headFrameId 3: integer #头像框
        customHead 4: string #自定义头像
        isOnline 5: boolean #是否在线
        lastLoginTime 6: integer #上次登陆时间
        rank 7: integer #成员等级 MemberRankType
        position 8: integer #成员官职
        joinTime 9: integer #加入时间
        power 10: integer #战力
        kill 11: integer #击杀
        isApplyForLeader 12: boolean #是否竞选盟主
        x 13: integer #场景坐标x
        y 14: integer #场景坐标y
        massTime 15: integer #群发消息的时间戳
        crossServerId 16: integer #跨服服务器id
        permission 17: uint32 # 成员权限
        castleLv 18: uint32 # 主堡等级
        sex 19: uint32 # 性别
    }

    .ComAllianceApplyInfo { #联盟的玩家申请列表
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像
        headFrameId 3: integer #头像框
        customHead 4: string #自定义头像
        power 5: integer #战力
        kill 6: integer #击杀
        applyTime 7: integer #申请时间
    }

    .ComAllianceLeaderInfo {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像
        headFrameId 3: integer #头像框
        customHead 4: string #自定义头像
        power 5: integer #战力
        appyTime 6: integer #申请时间
    }

    .ComTask {
        id 0: integer                   # id(每个玩家的任务id唯一)
        status 1: integer               # 任务状态
        count 2: integer                # 任务当前进度数量
        cfgId 3: integer                # 任务配置ID
        finishTime 4: integer           # 任务完成时间
    }

    .ComAllianceEnemyInfo {
        uid 1: integer #uid
        nickName 2: string #盟主昵称
        headId 3: integer #头像
        headFrameId 4: integer #头像框
        customHead 5: string #自定义头像
        serverId 6: integer #服务器id
        power 7: integer #战力
        x 8: integer #x坐标
        y 9: integer #y坐标
        aid 10: integer          # 联盟id
        abbName 11: string      # 联盟简称
        time 12: integer 
    }

    .ComAllianceTerritoryOccupyInfo { # 已占领的领地信息
        strongholdId 1: uint32 # 据点id
        strongholdName 2: string # 据点名称
        durability 3: integer # 当前耐久度
        isGiveUp 4: boolean # 正在放弃中
        giveUpTs 5: integer # 开始放弃时间戳
        occupyTime 6: integer # 占领时间
        firstOwned 7: boolean # 首占
    }
]]

return common