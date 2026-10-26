-- 竞技场 7451 ~ 7500
local arenaProto = {}

arenaProto.struct = [[    
    .ComArenaData {
        attackFormation 0: *ComArenaTeamDetail()        # 进攻阵容
        defenderFormation 1: *ComArenaTeamDetail()      # 防守阵容
        challengeTicket 2: uint32                       # 剩余挑战次数
        payTicketTimes 3: uint32                        # 购买挑战的次数
        lastRefreshTime 4: uint32                       # 上一次刷新对手时间
        newDayTime 6: uint32                            # 刷新时间
        serverIdsOfGold 7: *integer                     # 服务器id列表(黄金组)
        serverIdsOfSilver 8: *integer                   # 服务器id列表(白银组)
        groupId 9: integer                              # 分组id 0:无 1:在黄金组 2:在白银组
    }
    
    .ComArenaParam {
        configId 0 : uint32                             # 指向配置表activityArenaCfg
        actGroupId 1 : uint32                           # 指向配置表arenaRobot
    }

    .ComArena {
        actId 0 : uint32                                # 活动 id
        round 1 : uint32                                # 轮次
        state 2 : uint32                                # 状态
        param 3 : ComArenaParam                         # 参数
        data 4 : ComArenaData                           # 竞技场数据
    }
    
    .ComArenaOpponent {                                 # 竞技场对手
        uid 0 : uint32                                  # uid,机器人uid等于配置表id
        bRobot 1 : boolean                              # 是否机器人
        nickName 2: string                              # 玩家昵称
        headId 3: uint32                                # 头像
        headFrameId 4: uint32                           # 头像框
        customHead 5: string                            # 自定义头像
        rank 6: uint32                                  # 排名
        score 7: double                                 # 分数
        power 8: uint32                                 # 战力
        abbName 9: string                               # 联盟简称
        serverId 10: uint32                             # 所属服务器
        unlockArmyMaxLevel 11: uint32                   # 解锁兵种最高等级
        applyArmyType 12: uint32                        # 阵营加成对应的兵种 默认0
    }    

    .ComArenaRemove {
        actId 0: uint32
        isForceOver 1: boolean
    }
    
    .ComSyncArena {
        news 0: *ComArena(actId)
        changes 1: *ComArena(actId)
        removes 2: *integer
    }

    .ComArenaBattleReport {                             # 战报
        id 0: uint32                                    # 战报id
        timeStamp 1: uint32                             # 时间戳
        scoreChange 2: integer                          # 积分变化
        result 3: boolean                               # 结果
        isAttacker 4: boolean                           # 是否攻方
        opponentInfo 5: ComArenaOpponent                # 对手数据
        bRevenge 6: boolean                             # 是否复仇过
        
    }

    .ComArenaBattleResult {                             # 本次战斗结果
        isWin 1: boolean                                # 是否胜利
        scoreBefore 2: uint32                           # 进攻前分数
        scoreAfter 3: uint32                            # 进攻后分数
        rankBefore 4: uint32                            # 进攻前排名
        rankAfter 5: uint32                             # 进攻后排名
    }

    .ComArenaRankPlayer {
        uid 0: integer                                  # 玩家id
        nickName 1: string                              # 玩家昵称
        headId 2: integer                               # 头像
        headFrameId 3: integer                          # 头像框
        customHead 4: string                            # 自定义头像
        rank 5: integer                                 # 排名
        score 6: integer                                # 排行值
        power 7: uint32                                 # 战力
        abbName 8: string                               # 联盟简称
        serverId 9: integer                             # 服务器id
        unlockArmyMaxLevel 10: integer                  # 解锁兵种最高等级
        bRobot 11: boolean                              # 是否机器人
        applyArmyType 12: uint32                        # 阵营加成对应的兵种 默认0
        aid 13: integer                                 # 联盟id
    }

    .ComPos2ArenaHero {
        key 1: integer
        value 2: ComArenaHero
    }

    .ComArenaReplay {
        teamAtk 1: *ComPos2ArenaHero()
        teamDef 2: *ComPos2ArenaHero()
        randomSeed 3: integer
        time 4: double
        version 5: integer
    }

]]

arenaProto.c2s = arenaProto.struct .. [[

reqChangeBattleFormation 7471 { # 调整战斗阵容
    request {
        arenaActId 0: uint32                        # 竞技场活动id
        defenderFormation 1: *ComArenaTeam()        # 防御阵容
    }
    response {
        
    }
}

reqPayForTicket 7472 { # 购买竞技场次数
    request {
        arenaActId 0: uint32                        # 竞技场活动id
    }
    response {
        
    }
}

reqArenaOpponents 7474 { # 获取对手列表
    request {
        arenaActId 0: uint32                        # 竞技场活动id
    }
    response {
        opponentList 0: *ComArenaOpponent(uid)      # 对手列表
    }
}

reqRefreshArenaOpponents 7475 { # 刷新对手列表
    request {
        arenaActId 0: uint32                        # 竞技场活动id
    }
    response {
        opponentList 0: *ComArenaOpponent(uid)      # 对手列表
    }
}

reqArenaTeamDetail 7476 { # 获取某个对手详情
    request {
        arenaActId 0: uint32                        # 竞技场活动id
        targetUid 1: uint32                         # 目标id
        groupId 2: uint32                           # 分组id 0:无 1:在黄金组 2:在白银组
    }
    response {
        teamDetail 0: *ComArenaTeamDetail()         # 阵容详情
        score 1: uint32                             # 积分
        modifiedTankParts 2: *ComModifiedTankPart(partType)   # 改装车部位列表
        tankLv 3: uint32                # 改装车等级
        power 4: uint32                 # 队伍战力
    }
}

reqArenaChanllenge 7477 { # 请求挑战
    request {
        arenaActId 0: uint32                        # 竞技场活动id
        attackFormation 1: *ComArenaTeam()          # 进攻阵容，如果有填用本数据覆盖当前保存的数据，没有用当前保存数据进攻
        targetUid 2: uint32                         # 对手uid，机器人用配置id
        useItem 3: boolean                          # 使用道具替代次数
        isWin 4: boolean                            # 是否胜利
        replayDatas 6: *ComArenaReplay
    }
    response {
        battleResult 0: ComArenaBattleResult             # 战斗结果
        dropRes 1: *ComRes                               # 获得的奖励
        errorCode 2: integer                             # 错误弹窗
        isWin 3: boolean                                 # 是否胜利
        result 4: ComBattleResult
        time 5: integer
   }
}

reqArenaBattleReport 7478 { # 请求战报信息
    request {
        arenaActId 0: uint32                        # 竞技场活动id
    }
    response {
        arenaBattleReport 0: *ComArenaBattleReport(id) # 战报信息列表
    }
}

reqArenaRevenge 7479 { # 请求复仇
    request {
        arenaActId 0: uint32                        # 竞技场活动id
        attackFormation 1: *ComArenaTeam()          # 进攻阵容，如果有填用本数据覆盖当前保存的数据，没有用当前保存数据进攻
        reportId 2: uint32                          # 战报id
        useItem 3: boolean                         # 使用道具替代次数
        targetUid 4: uint32                         # 目标id
        isWin 5: boolean                            # 是否胜利
        replayDatas 6: *ComArenaReplay
    }
    response {
        battleResult 0: ComArenaBattleResult              # 战斗结果
        dropRes 1: *ComRes                                # 获得的奖励
        errorCode 2: integer                       # 错误弹窗
        isWin 3: boolean                                 # 是否胜利
        result 4: ComBattleResult
        time 5: integer
    }
}

reqArenaRank 7480 {
    request {
        arenaActId 1: uint32
        groupId 2: uint32                              # 分组id 0:无 1:在黄金组 2:在白银组
    }
    response {
        selfRank 0: integer                             # 自己的排名
        playerList 1: *ComArenaRankPlayer               # 排行榜信息
        selfScore 2: integer                            # 自己的排行值
    }
}

reqArenaSelfRank 7481 {                               # 自己在某榜中的排行与分数
    request {
        arenaActId 1: uint32                            
    }
    response {
        selfRank 0: integer                             # 自己的排名
        selfScore 1: integer                            # 自己的排行值
    }
}

reqArenaBattleReportDetail 7482 { # 请求单封战报详细信息
    request {
        arenaActId 0: uint32                        # 竞技场活动id
        id 1: uint32                                # 战报id
    }
    response {
        replayDatas 1: *ComArenaReplay              # pve战斗模式的
        battleReport 2: ComMailBattleReport         # 数据对撞的战报
        isRobot 3: boolean
    }
}

]]

arenaProto.s2c = arenaProto.struct .. [[

notifyNewBattleReport 7491 { # 新战斗记录通知
    request {
        arenaActId 0: uint32                        # 竞技场活动id
    }
    response {
    }
}

]]

return arenaProto
