-- 冠军对决活动 8810 ～ 8860
local championshipDuelProto = {}

championshipDuelProto.struct = [[
    .ComActChampionshipParam {
        configId 1: integer
    }
    
    .ComChampionshipDuelData {
        actId 0: integer
        isSignUp 1: boolean                         # 是否报过名
        curStage 2: integer                         # 当前赛事阶段
        session 3: integer                          # 当前场次
        formations 4: *ComArenaTeam()               # 上阵阵容
        items 5: *ComIntInt()                       # 狂欢道具列表
        exchangeList 6: *ComIntInt()                # 已兑换列表
        boxPoints 7: integer                        # 狂欢进度值
        pointsList 8: *ComIntBool()                 # 已领取的狂欢进度宝箱
        param 9: ComActChampionshipParam            # 活动参数
        battleBoxList 10: *integer                  # 已经领取的胜场宝箱列表 stage * 100 + id
        winCount 11: integer                        # 海选赛胜利场次
        betCount 12: integer                        # 当前场次已下注次数(淘汰赛或八强赛阶段)
    }

    .ComChampionshipRankPlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        power 5: integer                                #战力
        rank 6: integer                                 #排名
        score 7: integer                                #排行值
        abbName 8: string                               #联盟简称
        serverId 9: integer                             #服务器id
        winCount 10: integer                            #胜利场次
        failCount 11: integer                           #失败场次 
    }

    .ComChampionshipBattlePlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        abbName 5: string                               #联盟简称
        serverId 6: integer                             #服务器id
        power 7: integer                                #战力
    }

    .ComChampionshipBattleInfo {
        groupId 1: integer                           # 小组id
        battleId 2: integer                          # 编号id
        players 3: *ComChampionshipBattlePlayer      # 对战双方
        winner 4: integer                            # 获胜者
        scoreArray 5: *integer                       # 比分
    }

    .ComChampionshipRecordInfo {
        stage 0: integer                             # 赛事阶段
        groupId 1: integer                           # 小组id
        battleId 2: integer                          # 编号id
        players 3: *ComChampionshipBattlePlayer      # 对战双方
        winner 4: integer                            # 获胜者
        scoreArray 5: *integer                       # 比分
        session 6: integer                           # 场次
    }

    .ComChampionshipContestInfo {
        stage 0: integer                             # 赛事阶段
        groupId 1: integer                           # 小组id
        battleId 2: integer                          # 编号id
        players 3: *ComChampionshipBattlePlayer      # 对战双方
        winner 4: integer                            # 获胜者
        scoreArray 5: *integer                       # 比分
        betNumArray 6: *integer                      # 双方下注人数
        odds 7: integer                              # 赔率
        betTime 8: integer                           # 下注时间
    }

    .ComChampionshipBetInfo {
        betKey 0: integer                            # betKey = stage * 10000 + groupId * 100 + battleId
        selectUid 1: integer                         # 选择的玩家
        betNum 2: integer                            # 下注数
        isRewarded 3: boolean                        # 是否领过奖
    }
]]

championshipDuelProto.c2s = championshipDuelProto.struct .. [[
    championshipDuelSignUp 8810 { # 活动报名
        request {
            actId 1: uint32
        }
        response {

        }
    }

    championshipDuelUseItems 8811 { # 使用狂欢道具
        request {
            actId 1: uint32
            num 2: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    championshipDuelExchangeItems 8812 { # 兑换物品
        request {
            actId 1: uint32
            exchangeId 2: uint32
            exchangeNum 3: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    championshipDuelGetPointsReward 8813 { # 领取狂欢宝箱
        request {
            actId 1: uint32
            pointsIndex 2: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    championshipDuelChangeFormation 8814 { # 调整战斗阵容
        request {
            actId 1: uint32
            formations 2: *ComArenaTeam()  # 战斗阵容
        }
        response {
        }
    }

    championshipDuelGuess 8815 { # 下注竞猜
        request {
            actId 1 : uint32     # 活动 id
            stage 2: uint32     # 赛事阶段
            groupId 3: uint32    # 组id
            battleId 4 : uint32  # 战斗 id
            selectUid 5: uint32 # 选择的玩家 id
            betNum 6: uint32     # 下注数
        }
        response {
            betNumArray 1: *integer  # 双方下注人数
            betCount 2: integer # 当前场次已下注次数
        }
    }

    championshipDuelCancelGuess 8816 { # 取消下注竞猜
        request {
            actId 1: uint32     # 活动 id
            stage 2: uint32     # 赛事阶段
            groupId 3: uint32   # 组id
            battleId 4: uint32  # 战斗 id
        }
        response {
            ress 1: *ComRes
            betNumArray 2: *integer  # 双方下注人数
            betCount 3: integer # 当前场次已下注次数
        }
    }

    championshipDuelGetGuess 8817 { # 领取竞猜奖励
        request {
            actId 1: uint32     # 活动 id
            stage 2: uint32     # 赛事阶段
            groupId 3: uint32   # 组id
            battleId 4: uint32  # 战斗 id
        }
        response {
            ress 1: *ComRes
        }
    }

    championshipDuelGetBattleReward 8818 { # 领取对战奖励
        request {
            actId 1: uint32     # 活动 id
            stage 2: uint32     # 赛事阶段
            id 3: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    championshipDuelGetPreliminaryRank 8819 { # 获取海选赛排行榜
        request {
            actId 1: uint32     # 活动 id
        }
        response {
            selfRank 0: integer                             # 自己的排名
            playerList 1: *ComChampionshipRankPlayer        # 排行榜信息
            selfScore 2: integer                            # 自己的排行值
            selfWinCount 3: integer
            selfFailCount 4: integer
        }
    }

    championshipReqPreliminaryInfo 8820 { # 获取海选赛信息
        request {
            actId 1: uint32     # 活动 id
        }
        response {
            players 1: *ComChampionshipRankPlayer  # 对战双方
            selfWinCount 2: integer
            selfFailCount 3: integer
            
            viewWinCount 4: integer
            viewFailCount 5: integer
            viewScore 6: integer
        }
    }

    championshipReqKnockoutInfo 8821 { # 获取淘汰赛或八强赛信息
        request {
            actId 1: uint32     # 活动 id
        }
        response {
            curStage 0: integer # 当前赛事阶段
            battleList 1: *ComChampionshipBattleInfo
        }
    }

    championshipGetBattleReport 8822 { # 请求战报详情
        request {
            actId 1: uint32     # 活动id
            stage 2: uint32     # 赛事阶段
            groupId 3: uint32   # 小组id
            battleId 4: uint32  # 编号id
        }
        response {
            scoreArray 1: *integer                       # 比分
            battleReportList 2: *ComMailBattleReport     # 战报列表
        }
    }

    championshipGetRecordList 8823 { # 请求玩家战斗记录
        request {
            actId 1: uint32     # 活动id
            uid 2: uint32       # 玩家id
        }
        response {
            recordList 1: *ComChampionshipRecordInfo # 战斗记录列表
        }
    }

    championshipGetBattleReportByRecordId 8824 { # 请求战报详情
        request {
            actId 1: uint32     # 活动id
            uid 2: uint32       # 玩家id
            recordId 3: uint32  # 玩家记录id

        }
        response {
            scoreArray 1: *integer                       # 比分
            battleReportList 2: *ComMailBattleReport     # 战报列表
        }
    }

    championshipDuelGetCurContestInfo 8825 { # 获取当前赛事信息
        request {
            actId 1: uint32     # 活动id
        }
        response {
            contestList 1: *ComChampionshipContestInfo
            betList 2: *ComChampionshipBetInfo(betKey)
            betCount 3: integer # 当前场次已下注次数
        }
    }

    championshipDuelGetBetContestInfo 8826 { # 获取我的助威信息
        request {
            actId 1: uint32     # 活动id
        }
        response {
            contestList 1: *ComChampionshipContestInfo
            betList 2: *ComChampionshipBetInfo(betKey)
            betCount 3: integer # 当前场次已下注次数
        }
    }
]]

championshipDuelProto.s2c = championshipDuelProto.struct .. [[

]]

return championshipDuelProto