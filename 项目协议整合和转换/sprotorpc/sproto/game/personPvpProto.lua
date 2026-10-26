-- 赛季个人pvp 7701 ～ 7750
local personPvpProto = {}

personPvpProto.struct = [[
    .PersonPvpParam {
        rankCfgId 1: integer
        seasonId 2: integer
    }

    .PersonPvpSkill {
        level 1: integer # 天赋等级
        skillId 2: integer # 技能id
        castTs 3: integer # 技能释放时间戳
    }

    .PersonPvpSection {
        sectionId 1: integer # 场次id
        isOver 2: boolean # 是否结束
        isMax 3: boolean # 报名人数是否达到上限
        status 4: integer # 0:可报名 1:匹配中 2:可进入 3:对战开启 4:终止参与
    }

    .PersonPvpRankPlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        rank 5: integer                                 #排名
        score 6: integer                                #排行值
        abbName 7: string                               #联盟简称
        serverId 8: integer                             #服务器id
        gloryLv 9: integer                              #赛季荣耀等级
    }

    .ComSyncPersonPvpHero {
        news 1: *ComHeroPersonPvp(heroCfgId)                     # 新增英雄
        changes 2: *ComHeroPersonPvp(heroCfgId)                  # 更新英雄
        removes 3: *integer 
    }

    .ComSyncPersonPvpSkill { 
        news 1: *PersonPvpSkill(level)                     # 新增天赋技能
        changes 2: *PersonPvpSkill(level)                  # 更新天赋技能
        removes 3: *integer
    }

    .ComSyncPersonPvpSection {
        news 1: *PersonPvpSection(sectionId)                     # 新增场次
        changes 2: *PersonPvpSection(sectionId)                  # 更新场次
        removes 3: *integer
    }

    .ComPersonPvpActInfo {
        actId 1: integer # 活动id
        param 2: PersonPvpParam # 活动参数
        moveTimes 3: integer # 迁城次数
        lastFreeMoveTs 4: integer # 上次免费迁城时间戳
        talentExp 5: integer # 天赋经验
        talentLv 6: integer # 天赋等级
        skill 7: *PersonPvpSkill(level) # 天赋技能
        hero 8: *ComHeroPersonPvp(heroCfgId) # 英雄信息
        army 9: *ComArmyIdAndNum() # 士兵信息
        section 10: *PersonPvpSection(sectionId) # 场次信息
        signId 11: integer # 报名id
        isJoin 12: boolean # 是否参与活动
        sceneId 13: integer # 战场场景id
        attribute 14: *ComIntInt() # 属性信息
        optOutTimes 15: integer #报名了不参与次数
        isOver 16: boolean # 活动是否关闭
        totalScore 17: integer #积分
        occupyTime 18: integer #占领积分仓库时长
        dungeonPlayerNum 19: integer #战场人数
        entered 20: boolean #是否进入过战场
        totalPower 21: integer #总战力
        dungeonStartTs 22: integer #战场实际开启时间戳
    }

    .ComSyncPersonPvpActInfo {
        actId 1: integer # 活动id
        param 2: PersonPvpParam # 活动参数
        moveTimes 3: integer # 迁城次数
        lastFreeMoveTs 4: integer # 上次免费迁城时间戳
        talentExp 5: integer # 天赋经验
        talentLv 6: integer # 天赋等级
        skill 7: ComSyncPersonPvpSkill # 技能
        hero 8: ComSyncPersonPvpHero # 英雄
        army 9: ComSyncDataArmy # 兵力
        section 10: ComSyncPersonPvpSection # 场次信息
        signId 11: integer # 报名id
        isJoin 12: boolean # 是否参与活动
        sceneId 13: integer # 战场场景id
        attribute 14: ComSyncDataAttribute # 属性信息
        optOutTimes 15: integer #报名了不参与次数
        isOver 16: boolean # 活动是否关闭
        totalScore 17: integer #积分
        occupyTime 18: integer #占领积分仓库时长
        dungeonPlayerNum 19: integer #战场人数
        entered 20: boolean #是否进入过战场
        totalPower 21: integer #总战力
        dungeonStartTs 22: integer #战场实际开启时间戳
    }

]]

personPvpProto.c2s = personPvpProto.struct .. [[
    personPvpSignUp 7701 { # 活动报名
        request {
            actId 1: uint32 # 活动id
            sectionId 2: uint32 # 场次id
        }
        response {

        }
    }

    personPvpActivateTalentSkill 7702 { # 激活天赋技能
        request {
            actId 1: uint32 # 活动id
            level 2: uint32 # 天赋等级
            skillId 3: uint32 # 技能id
        }
        response {

        }
    }

    personPvpCastTalentSkill 7703 { # 释放天赋技能
        request {
            actId 1: uint32 # 活动id
            level 2: uint32 # 天赋等级
        }
        response {

        }
    }

    personPvpQueryRank 7704 {                              # 查询排行榜
        request {
            actId 1: uint32 # 活动id
            sectionId 2: uint32 # 场次id

        }
        response {
            selfRank 0: integer                             # 自己的排名
            playerList 1: *PersonPvpRankPlayer
            selfScore 2: integer                            # 自己的排行值
        }
    }

]]

personPvpProto.s2c = personPvpProto.struct .. [[
    syncPersonPvpDungeonOver 7704 { #战场结算
        request {
            actId 0: integer # 活动id
            totalScore 1: integer # 本场总积分
            loseScore 2: integer # 本场损失积分
            occupyTime 3: integer  # 占领积分仓库
            killMonster 4: integer # 击杀怪物
            pickScore 5: integer # 拾取积分
            occupyNum 6: integer # 占领积分矿
            isJoin 7: boolean # 玩家是否参与了游戏
            optOutTimes 8: integer #报名了不参与次数
            sceneId 9: integer # 场景id
        }
    }
]]

return personPvpProto