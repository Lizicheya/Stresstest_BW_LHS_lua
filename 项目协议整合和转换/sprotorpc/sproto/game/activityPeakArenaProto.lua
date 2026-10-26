--
-- author: TQING<tqing1128@gmail.com>
-- date: 2024-09-25 15:13:35
--

local activityPeakArenaProto = {}

activityPeakArenaProto.struct = [[
    .PeakArenaTeam {
        team 0 : *ComArenaTeamDetail() # 队伍数据
        teamPower 1 : integer # 战力
    }

    .PeakArenaBattleResult {
        winner 0 : integer # 胜利者
        .Map {
            uid 0 : integer # 玩家 Id
            value 1 : PeakArenaTeam # 队伍数据
        }
        team 1 : *Map() # 队伍数据
        log 2 : *boolean # 战斗日志
    }

    .PeakArenaStageDataMap {
        stage 0 : integer # 阶段

        .Map {
            battleId 0 : integer # 战斗 Id

            .Struct {
                players 0 : *integer # 玩家 Id

                .Result {
                    winner 0 : integer # 胜利者
                }
                result 1 : Result # 结果
            }
            value 1 : Struct # 战斗数据
        }
        value 1 : *Map() # 阶段数据
    }

    .PeakArenaSelfGuessDataMap {
        stage 0 : integer # 阶段

        .Struct {
            battleId 0 : integer # 战斗 id
            selectUid 1 : integer # 玩家 id,未选择为 nil
            win 2 : boolean # 竞猜结果,未选择为 nil
            claimed 3 : boolean # 领取状态,未选择为 nil
        }
        value 1 : Struct # 竞猜数据
    }

    .PeakArenaSelfSettleData {
        rank 0 : integer # 名次
        rankClaimed 1 : boolean # 名次奖励领取状态

        .Map {
            aid 0 : integer # 联盟 id

            .Map{
                uid 0 : integer # 玩家 id

                .Struct {
                    rank 0 : integer # 名次
                    claimed 1 : boolean # 领取状态
                }
                value 1 : Struct # 联盟结算玩家数据
            }
            value 1 : *Map() # 结算数据
        }
        alliance 2 : *Map()
    }

    .PeakArenaData {
        curStage 0 : integer # 当前阶段
        stages 1 : *PeakArenaStageDataMap() # 阶段数据
        selfTeam 2 : *ComArenaTeamDetail() # 自己的队伍数据
        selfGuess 3 : *PeakArenaSelfGuessDataMap() # 自己的竞猜数据
        selfSettle 4 : PeakArenaSelfSettleData # 自己的结算数据
    }

    .PeakArenaParam {
        configGroupId 0 : integer # 活动配置组 Id
    }

    .PeakArenaTeamInfoMap {
        uid 0 : integer # 玩家 Id
        power 1 : integer # 队伍战力
    }

    .PeakArenaInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        param 3 : PeakArenaParam # 参数
        data 4 : PeakArenaData
    }

    .peakArenaGetPlayerInfoResponseMapMap {
        uid 0 : integer # 玩家 Id
        teamPower 1 : integer # 战力
    }

    .peakArenaGetPlayerInfoResponseMap {
        stage 0 : integer # 阶段
        value 1 : *peakArenaGetPlayerInfoResponseMapMap() # 玩家队伍数据
    }

    .peakArenaGetLastRoundInfoResponseMapStruct {
        rank 0 : integer # 名次
        teamPower 1 : integer # 战力
    }

    .peakArenaGetLastRoundInfoResponseMap {
        uid 0 : integer # 玩家 Id
        value 1 : peakArenaGetLastRoundInfoResponseMapStruct # 玩家数据
    }

    .peakArenaGetGuessNumResponseMap {
        uid 0 : integer # 玩家 Id
        value 1 : integer # 竞猜人数
    }
]]

activityPeakArenaProto.c2s = activityPeakArenaProto.struct .. [[
    peakArenaClaimRankReward 7501 { # 领取名次奖励
        request {
            actId 0 : uint32 # 活动 id
        }
        response {}
    }

    peakArenaClaimAllianceRankReward 7502 { # 领取联盟名次奖励
        request {
            actId 0 : uint32 # 活动 id
            aid 1 : uint32 # 联盟 id
            uid 2 : uint32 # 玩家 id
        }
        response {}
    }

    peakArenaSetTeam 7503 { # 设置队伍
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            team 2 : *ComArenaTeamDetail() # 队伍数据
        }
        response {}
    }

    peakArenaGuess 7504 { # 竞猜
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            battleId 2 : uint32 # 战斗 id
            selectUid 3 : uint32 # 选择的玩家 id
        }
        response {}
    }

    peakArenaClaimGuessReward 7505 { # 领取竞猜奖励
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            battleId 2 : uint32 # 战斗 id
        }
        response {}
    }

    peakArenaGetPlayerInfo 7506 { # 获取参赛玩家信息
        request {
            actId 0 : uint32 # 活动 id
        }
        response {
            playerInfo 0 : *ComPlayerInfo(uid) # 玩家信息            
            teamInfo 1 : *peakArenaGetPlayerInfoResponseMap() # 队伍信息
        }
    }

    peakArenaGetLastRoundInfo 7507 { # 获取上一轮八强数据
        request {
            actId 0 : uint32 # 活动 id
        }
        response {
            info 0 : *peakArenaGetLastRoundInfoResponseMap() # 结算数据
            playerInfo 1 : *ComPlayerInfo(uid) # 玩家信息
        }
    }

    peakArenaGetPlayerTeam 7508 { # 获取玩家队伍
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            uid 2 : uint32 # 玩家 id
        }
        response {
            team 0 : PeakArenaTeam # 队伍数据
        }
    }

    peakArenaGetBattleLog 7509 { # 获取战斗日志
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            battleId 2 : uint32 # 战斗 id
        }
        response {
            log 0 : PeakArenaBattleResult
        }
    }

    peakArenaGetGuessNum 7510 { # 获取竞猜人数
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            battleId 2 : uint32 # 战斗 id
        }
        response {
            guessNum 0 : *peakArenaGetGuessNumResponseMap()
        }
    }
]]

activityPeakArenaProto.s2c = activityPeakArenaProto.struct .. [[

]]

return activityPeakArenaProto