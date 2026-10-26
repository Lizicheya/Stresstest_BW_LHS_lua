--通用联盟信息模块 1801~1900

local allianceInfoProto = {}

allianceInfoProto.struct = [[
    .ComSyncDataAllianceMember {
        news 1: *ComAllianceMemberInfo(uid)                           # 成员数据列表
        changes 2: *ComAllianceMemberInfo(uid)                        # 成员数据列表
        removes 3: *integer                                           # 删除uid
    }

    .ComSyncDataAllianceApply {
        news 1: *ComAllianceApplyInfo(uid)                            # 申请信息列表
        changes 2: *ComAllianceApplyInfo(uid)                         # 申请信息列表
        removes 3: *integer                                           # 删除uid
    }

    .ComSyncDataAllianceLeader {
        news 1: *ComAllianceLeaderInfo(uid)                           # 竞选信息列表
        changes 2: *ComAllianceLeaderInfo(uid)                        # 竞选信息列表
        removes 3: *integer                                           # 删除uid
    }

    .ComPlayerApplyInfo { #玩家的联盟申请列表
        aid 0: integer #联盟id
        applyTime 1: integer #申请时间
    }
    
    .ComSyncDataPlayerApply {
        news 1: *ComPlayerApplyInfo(aid)                           # 玩家申请的联盟列表
        changes 2: *ComPlayerApplyInfo(aid)                        # 玩家申请的联盟列表
        removes 3: *integer                                        # 删除aid
    }

    .ComAllianceBasis {
        base 0: ComAllianceBase                            #联盟基础信息
        members 1: *ComAllianceMemberInfo(uid)             #联盟成员
        applys 2: *ComAllianceApplyInfo(uid)               #联盟的玩家申请加入列表
        leaders 3: *ComAllianceLeaderInfo(uid)             #联盟竞选列表
        applications 4: *ComPlayerApplyInfo(aid)           #玩家的联盟申请加入列表
    }

    .ComSyncDataAllianceBasis { 
        base 0: ComAllianceBase                            #联盟基础信息
        members 1: ComSyncDataAllianceMember               #联盟成员
        applys 2: ComSyncDataAllianceApply                 #联盟的玩家申请加入列表
        leaders 3: ComSyncDataAllianceLeader               #联盟竞选列表
        applications 4: ComSyncDataPlayerApply             #玩家的联盟申请加入列表
    }

    .ComAllianceTechnology {
        techId 0: integer               # id(科技唯一id-配置ID)
        status 1: integer               # 状态 AllianceTechnologyStatusType
        lv 2: integer                   # 等级
        exp 3: integer                  # 科技点
        recommend 4: boolean            # 推荐状态
        beginTime 5: integer            # 开始研究时间
        upgradeTime 6: integer          # 研究时长
    }
    
    .ComAllianceTech {
        technology 0: *ComAllianceTechnology(techId)            # 联盟科技
        normalDonate 1: ComNormalDonate                                 # 普通捐献数据
        gemDonate 2: ComGemDonate                                       # 宝石捐献数据
        dailyVal 3: integer                                             # 每日总贡献值
        weeklyVal 4: integer                                            # 每周总贡献值
    }

    .ComSyncDataAllianceTechnology {
        news 1: *ComAllianceTechnology(techId)                  # 联盟科技数据列表
        changes 2: *ComAllianceTechnology(techId)               # 联盟科技数据列表
        removes 3: *integer                                     # 删除科技id
    }

    .ComSyncDataAllianceBuild {
        news 1: *ComAllianceBuild(id)                  # 联盟建筑数据列表
        changes 2: *ComAllianceBuild(id)               # 联盟建筑数据列表
        removes 3: *integer                            # 删除建筑id
    }

    #联盟物品
    .ComSyncDataAllianceItem {
        news 1: *ComIntInt()                           # 新增
        changes 2: *ComIntInt()                        # 修改
        removes 3: *integer                            # 删除
    }

    #联盟宝箱信息
    .ComAllianceGiftBoxInfo {
        level 1: integer    # 宝箱等级
        exp 2: integer      # 宝箱经验
        keyNum 3: integer   # 宝箱钥匙
        curBoxId 4: integer # 当前正在开启的宝箱
    }

    .ComAllianceGiftBoxItem {
        id 1: integer    # 自增id(唯一id)
        cfgId 2: integer           # 礼物or宝箱id
        senderName 3: string    # 发送人昵称，匿名为nil
        addTime 4: integer      # 投放时间
        goodsId 5: integer     # 商品id
    }

    .ComAllianceGiftBoxList {
        news 1: *ComAllianceGiftBoxItem(id)                         # 宝箱列表
        changes 2: *ComAllianceGiftBoxItem(id)                      # 宝箱列表
        removes 3: *integer                                         # 删除
    }

    .ComSyncDataAlliancePositions{
        news 1: *ComIntInt()                           # 新增
        changes 2: *ComIntInt()                        # 修改
        removes 3: *integer                            # 删除
    }

    .ComSyncDataAllianceSystemOpen{
        news 1: *ComIntInt()                           # 新增
        changes 2: *ComIntInt()                        # 修改
        removes 3: *integer                            # 删除
    }

    .ComAllianceResMine {
        cfgId 0: integer #联盟资源id
        addSpeed 1: double #增加速度
        reduceSpeed 2: double #减少速度
    }

    .ComSyncDataAllianceResProduce {
        lastSettleTS 1: integer                        # 上次结算时间
        resMineList 2: *ComAllianceResMine(cfgId)      
    }

    .ComSyncDataPoint {
        news 1: *ComIntInt()                                            # 联盟积分活动数据列表
        changes 2: *ComIntInt()                                         # 联盟积分活动数据列表
        removes 3: *integer                                             # 删除uid
    }

    .ComAllianceMark {
        id 0: integer #标记id
        uid 1: integer
        markType 2: integer #标记类型
        sceneId 3: integer
        x 4: integer
        y 5: integer
        text 6: string #文本
        time 7: integer #创建时间戳
        expireTime 8: integer #过期时间戳，秒
        mapBuildCfgId 9: integer # 建筑配置表id
        nickName 10: string # 昵称
    }

    .ComSyncDataAllianceMark {
        news 1: *ComAllianceMark(id)
        changes 2: *ComAllianceMark(id)
        removes 3: *integer
    }

    .ComSyncDataCoolBuild {
        news 1: *ComIntInt()                                            # 联盟建筑冷却数据列表
        changes 2: *ComIntInt()                                         # 联盟建筑冷却数据列表
        removes 3: *integer                                             # 删除bid
    }

    .ComSyncActivityMonsterSiege {
        news 1: *ComActivityMonsterSiege(actId)              # 新增怪物攻城
        changes 2: *ComActivityMonsterSiege(actId)           # 更新怪物攻城
        removes 3: *integer                                  # 删除怪物攻城
    }

    .ComAllianceOperLog {
        id 0: integer
        operType 1: integer
        operSubType 2: integer
        operTime 3: integer
        operData 4: ComAllianceOperLogDetail
    }

    .ComSyncAllianceOperLog {
        news 1: *ComAllianceOperLog(id)              # 新增
        changes 2: *ComAllianceOperLog(id)           # 改变 实际不改变
        removes 3: *integer                          # 移除 实际不做移除更新操作
    }

    .ComSyncUnitedAllianceInvite {
        news 1: *ComIntBool           # 新增
        removes 2: *ComIntBool        # 删除 
    }

    .ComSyncUnitedAllianceApply {
        news 1: *ComIntBool           # 新增
        removes 2: *ComIntBool        # 删除 
    }

    .ComUnitedAlliances {
        uaid 0: integer                                 # 友盟id
        aids 1: *integer                                # 友盟中联盟
        inviteAids  2: *ComSyncUnitedAllianceInvite     # 已邀请列表
        applyUaids 3: *ComSyncUnitedAllianceApply       # 申请的友盟列表
    }

    .ComSyncGvgTeamMember {
        uid 0: integer      # 玩家id
        role 1: integer     # 玩家角色
        power 2: integer    # 玩家战力
    }

    .ComAllianceGvgTeam {
        teamId 0: integer   # 队伍id
        teamName 1: string  # 队伍名字
        updateNameTs 2: integer # 更名时间戳
        teamIndex  3: integer    # 队伍索引
        members 4: *ComSyncGvgTeamMember(uid)   #队伍成员
        application 5: *integer # 申请玩家id列表
        score 6: integer    # 队伍积分
        isUnlock 7: boolean    # 队伍解锁状态
    }

    .ComSyncGvgTeams {
        news 1: *ComAllianceGvgTeam(teamId)              # 新增
        changes 2: *ComAllianceGvgTeam(teamId)           # 改变
    }

    .ComSyncAllianceGvgTeamInfo {
        teams 0: ComSyncGvgTeams # 队伍信息
    }

    .ComSyncAllianceEnemyInfo {
        news 0: *ComAllianceEnemyInfo(uid)
        changes 1: *ComAllianceEnemyInfo(uid)
        removes 2: *uint32
    }

    .ComSyncAllianceMonsterHunt {
        news 0: *AllianceMonsterHuntInfo(actId)
        changes 1: *AllianceMonsterHuntInfo(actId)
        removes 2: *uint32
    }


	.ComSyncAllianceActivity {
        news 1: *Activity(actId)                            # 新增活动
        changes 2: *Activity(actId)                         # 更新活动
        removes 3: *integer                                 # 移除活动
    }

    .CompSyncAllianceActivityTask {
        news 1: *ComTask(cfgId)                           
        changes 2: *ComTask(cfgId)                         
        removes 3: *integer                                 
    }

	.ComSyncAllianceTerritoryOccupyList {
        news 0: *ComAllianceTerritoryOccupyInfo(strongholdId)
        changes 1: *ComAllianceTerritoryOccupyInfo(strongholdId)
        removes 2: *uint32
    }

    .ComSyncAllianceTerritoryDeclareList {
        news 0: *ComAllianceTerritoryDeclareWarInfo(strongholdId)
        changes 1: *ComAllianceTerritoryDeclareWarInfo(strongholdId)
        removes 2: *uint32
    }

    .ComSyncAllianceTerritoryOperLogList {
        news 0: *ComAllianceTerritoryOperLog(id)
        changes 1: *ComAllianceTerritoryOperLog(id)
        removes 2: *uint32
    }

    .ComSyncAllianceTerritory {
        dailyWarNum 1: uint32
        occupyList 2: ComSyncAllianceTerritoryOccupyList
        declareList 3: ComSyncAllianceTerritoryDeclareList
        operLogList 4: ComSyncAllianceTerritoryOperLogList
    }

    .ComSyncActivityCalendar {
        news 0: *ComActivityCalendar(actId)
        changes 1: *ComActivityCalendar(actId)
        removes 2: *uint32
    }

]]

allianceInfoProto.c2s = allianceInfoProto.struct .. [[

]]

allianceInfoProto.s2c = allianceInfoProto.struct .. [[
    syncAllianceLoginData 1801 {
        request {
            allianceBasis 0: ComAllianceBasis                       # 联盟信息
            allianceTechnology 1: *ComAllianceTechnology(techId)    # 联盟科技数据列表
            allianceBuild 2: *ComAllianceBuild(id)                  # 联盟建筑
            allianceItem 3: *ComIntInt()                            # 联盟物品
            positions 7: *ComIntInt()                               # 联盟官职
            allianceSystemOpen 8: *ComIntInt()                      # 联盟系统开启
            allianceActivityMonsterHunt 9: *AllianceMonsterHuntInfo(actId) # 联盟异兽追捕活动信息
            allianceActivity 10: *Activity(actId)                   # 联盟活动信息
            allianceActivityTask 11: *ComTask(cfgId)                # 联盟活动任务信息
            allianceHelpDaily 12: ComAllianceHelpDaily              # 联盟帮助每日信息
        }
    }

    syncAllianceInfo 1802 {
        request {
            allianceBasis 0: ComSyncDataAllianceBasis               # 联盟信息
            allianceTechnology 1: ComSyncDataAllianceTechnology     # 联盟科技
            allianceBuild 2: ComSyncDataAllianceBuild               # 联盟建筑
            allianceItem 3: ComSyncDataAllianceItem                 # 联盟物品
            allianceGiftInfo 4: ComAllianceGiftBoxInfo              # 联盟礼物 宝箱详情
            allianceGiftGiftList 5: ComAllianceGiftBoxList          # 联盟礼物 礼物列表
            allianceGiftBoxList 6: ComAllianceGiftBoxList           # 联盟礼物 宝箱列表
            positions 7: ComSyncDataAlliancePositions               # 联盟官职
            allianceSystemOpen 8: ComSyncDataAllianceSystemOpen     # 联盟系统开启
            allianceResProduce 9: ComSyncDataAllianceResProduce     # 联盟矿资源产出上次结算时间戳
            activityAllianceScoreData 10: ComSyncDataPoint          # 联盟积分活动
            allianceMark 11: ComSyncDataAllianceMark                # 联盟标记
            coolBuilds 12: ComSyncDataCoolBuild                     # 冷却联盟建筑
            activityMonsterSiege 13: ComSyncActivityMonsterSiege    # 怪物攻城活动
            allianceOperLog 14: ComSyncAllianceOperLog              # 联盟日志
            allianceBlock 15: ComSyncDataAllianceBlock              # 联盟积木
            allianceWorker 16: ComSyncDataAllianceWorker            # 联盟工人
            canOccupyCount 17: integer                              # 联盟领地可占领联盟矿数量
            allianceUnitedAlliances 18: ComUnitedAlliances          # 友盟数据
            allianceGvgTeam 19: ComSyncAllianceGvgTeamInfo          # 联盟GVG队伍
            allianceEnemy 20: ComSyncAllianceEnemyInfo              # 联盟敌对玩家
            allianceActivityMonsterHunt 21: ComSyncAllianceMonsterHunt    # 联盟异兽追捕活动
			allianceActivity 22: ComSyncAllianceActivity            # 联盟活动
			allianceTerritory 23: ComSyncAllianceTerritory          # 联盟领地
            allianceActivityTask 24: CompSyncAllianceActivityTask   # 联盟活动任务
            allianceHelp 25: ComSyncDataAllianceHelp                # 帮助数据列表
            allianceShadowTask 26: ComSyncPlayerAllianceHelpShadowTask    # 暗影任务数据列表
            allianceActivityCalendar 27: ComSyncActivityCalendar    # 联盟活动日历
            allianceHelpDaily 28: ComSyncAllianceHelpDaily          # 联盟帮助每日信息
            allianceChatBonusList 29: ComSyncAllianceChatBonusList  # 联盟聊天红包列表
        }
    }
]]

return allianceInfoProto