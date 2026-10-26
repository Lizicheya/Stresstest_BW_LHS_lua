-- 联盟对决 8481 ～ 8580
local allianceDuelProto = {}

allianceDuelProto.struct = [[
    .ComActivityAllianceDuelParam {
        relationId 1: integer
    }

    .ComActivityAllianceDuel {
        actId 1: integer # 活动id 保留字段无用
        state 2: integer # 活动阶段 1:预告 2开始 3结算 4结束
        isOver 3: boolean # 活动是否结束
        startTimestamp 4: integer # 活动开始时间戳
        stagesDuration 5: *integer # 各阶段持续时间
        stageList 6: *ComIntBool() # 今日已领取积分档位奖励 [档位id] = true
        score 7: integer # 玩家今日积分
        targetAid 8: integer # 匹配到的联盟
        param 9: ComActivityAllianceDuelParam # 活动参数
        nextTargetAid 10: integer # 下一轮匹配到的联盟
    }

    .ComDuelDailyMvp {
        key 1: integer
        value 2: ComDuelPlayer
    }

    .ComDuelPlayer {
        uid 1: integer         # 玩家uid
        nickName 2: string     # 昵称
        headId 3: integer      # 头像
        headFrameId 4: integer # 头像框
        customHead 5: string   # 自定义头像
        serverId 6: integer    # 玩家所在王国id
    }

    .ComDuelAllianceData {
        aid 1: integer          # 联盟id
        fullName 2: string      # 联盟全称
        abbName 3: string       # 联盟简称
        flagId 4: integer       # 标志样式
        colorId 5: integer      # 标志颜色
        patternId 6: integer    # 标识图案
        serverId 7: integer     # 联盟所在王国id
        dailyScore 8: integer   # 联盟当日积分
        duelScore 9: integer    # 联盟对决总积分
        mvpUser 10: ComDuelPlayer # 联盟mvp玩家
        power 11: integer       # 联盟战力
        isDisband 12: boolean   # 联盟是否已解散
        scoreList 13: *ComIntInt() # 每日积分 [dayId] = score
    }
]]

allianceDuelProto.c2s = allianceDuelProto.struct .. [[
    allianceDuelGetTargetData 8481 {                        # 获取匹配对手信息
        request {

        }
        response {
            aid 1: integer          # 联盟id
            fullName 2: string      # 联盟全称
            abbName 3: string       # 联盟简称
            flagId 4: integer       # 标志样式
            colorId 5: integer      # 标志颜色
            patternId 6: integer    # 标识图案
            serverId 7: integer     # 联盟归属王国id
            isDisband 8: boolean    # 是否已经解散
        }
    }

    allianceDuelQueryRank 8482 {                            # 查询排行榜
        request {
            rankCfgId 0: uint32                             # 排行榜配置id
        }
        response {
            selfRank 0: integer                             # 自己的排名
            rankList 1: *ComRankPlayer                      # 排行榜信息
            selfScore 2: integer                            # 自己的排行值
        }
    }

    allianceDuelGetStageAward 8483 {                        # 领取积分档位奖励
        request {
            stageId 0: uint32
        }
        response {
            stageId 0: uint32
            ress 1: *ComRes  
        }
    }

    allianceDuelMatchSituation 8484 {                    # 赛况
        request {

        }
        response {
            aid2duelData 1: *ComDuelAllianceData(aid)    # 联盟对决信息
            dayId2mvp 2: *ComDuelDailyMvp()              # 每日mvp [dayId] = player
            dayId2aid 3: *ComIntInt()                    # 每日获胜联盟 [dayId] = aid
            isWin 4: boolean                             # 是否胜利
            finalMvp 5: ComDuelPlayer                    # 最终对决mvp
            aidOfmvp 6: integer                          # 最终对决mvp归属的联盟id    
        }
    }

    allianceDuelKillEnemy 8485 {                         # 杀敌日
        request {

        }
        response {
            aid2duelData 1: *ComDuelAllianceData(aid)    # 联盟对决信息
            mvpUser 2: ComDuelPlayer                     # 杀敌日对决mvp
            aidOfmvp 3: integer                          # 对决mvp归属的联盟id
            abbNameOfmvp 4: string                       # 对决mvp归属的联盟简称
            scoreOfmvp 5: integer                        # 对决mvp杀敌日积分
        }
    }

    allianceDuelGetMoveCastlePos 8486 {                  # 获取迁城坐标
        request {

        }
        response {
            pos 1: ComPoint
            isDisband 2: boolean
        }
    }

    allianceDuelGetYesterdayMatch 8487 {                 # 获取昨日赛况 
        request {

        }
        response {
            aid2duelData 1: *ComDuelAllianceData(aid)    # 联盟对决信息
            isWin 2: boolean                             # 是否胜利
        }
    }


]]

allianceDuelProto.s2c = allianceDuelProto.struct .. [[

]]

return allianceDuelProto