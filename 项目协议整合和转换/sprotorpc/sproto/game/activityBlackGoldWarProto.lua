-- 黑金战场 9001 ～ 9050
local activityBlackGoldWarProto = {}

activityBlackGoldWarProto.struct = [[
    .BlackGoldWarVoteInfo {
        uid 1: integer # uid
        headId 2: integer # 头像id
        headFrameId 3: integer # 头像框id
        customHead 4: string # 自定义头像
        nickName 5: string # 昵称
        power 6: integer # 战力
        rank 7: integer # 联盟R1～R5
    }

    .BlackGoldWarCombatantInfo {
        uid 1: integer # uid
        headId 2: integer # 头像id
        headFrameId 3: integer # 头像框id
        customHead 4: string # 自定义头像
        nickName 5: string # 昵称
        score 6: uint64 # 实力分
        rank 7: integer # 联盟R1～R5
        teamId 8: integer # 入选小队id
        voteData 9: *ComIntBool() #投票信息
    }

    .BlackGoldWarTeamInfo {
        teamId 0: uint32 #小队id
        starterUsers 1: *uint32 #首发名单
        subUsers 2: *uint32 #替补名单
    }

    .BlackGoldWarBattleInfo {
        aid 0: integer # aid
        fullName 1: string #联盟全称
        abbName 2: string #联盟简称
        flagId 3: uint32 #标志样式
        colorId 4: uint32 #标志颜色
        patternId 5: uint32 #标识图案
        serverId 6: integer #王国id
        teamId 7: integer #小队id
        enterNum 8: integer #当前进入战场人数
        totalNum 9: integer #实际参与战场总人数（战场结束阶段）
        score 10: uint64 #当前积分
    }

    .BlackGoldWarSectionInfo {
        timeId 1: integer # 场次id
        isOver 2: boolean # 是否结束
        status 3: integer # 0:无 1:战场开启 2:战场结束
        startTs 4: integer # 当前场次开始时间戳
    }

    .BlackGoldWarBattleRecord {
        battles 1: *BlackGoldWarBattleInfo(aid) #对战双方
        winner 2: integer #胜利方aid
        time 3: integer #时间戳
    }
]]

activityBlackGoldWarProto.c2s = activityBlackGoldWarProto.struct .. [[
    blackGoldWarVote 9001 { #投票
        request {
            actId 1: uint32 #活动id
            voteData 2: *ComIntBool() #投票时间段列表 timeId => ture or false
        }
        response {

        }
    }

    blackGoldWarGetVoteNumList 9002 { #查看各个时间段投票成员数量
        request {
            actId 1: uint32 #活动id
        }
        response {
            voteNumList 1: *uint32
        }
    }

    blackGoldWarGetVoteDetailInfo 9003 { #查看某个时间段投票详情
        request {
            actId 1: uint32 #活动id
            timeId 2: uint32 #时间段id
        }
        response {
            userList 1: *BlackGoldWarVoteInfo(uid)
        }
    }

    blackGoldWarJoinWar 9004 { #申请参战
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #小队id
            isJoin 3: boolean #是否参战
        }
        response {
            
        }
    }

    blackGoldWarChangeBattleTime 9005 { # 修改小队战场时间
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #小队id
            timeId 3: boolean #时间段id
        }
        response {
            
        }
    }

    blackGoldWarSubmitBattleUsers 9006 { # 提交小队名单
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #小队id
            starterUsers 3: *uint32 #首发名单
            subUsers 4: *uint32 #替补名单
        }
        response {
            
        }
    }

    blackGoldWarGetTeamInfo 9007 { # 查看小队信息
        request {
            actId 1: uint32 #活动id
        }
        response {
            teams 1: *BlackGoldWarTeamInfo(teamId)
            combatants 2: *BlackGoldWarCombatantInfo(uid) #参战人员信息
        }
    }

    blackGoldWarGetBattleInfo 9008 { #查看对战信息
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #小队id
        }
        response {
            battles 1: *BlackGoldWarBattleInfo(aid)
            isBye 2: boolean # 是否轮空
            beginTime 3: integer # 战斗开始时间
            isOver 4: boolean # 是否结束
            isWin 5: boolean # 是否胜利
            
        }
    }

    blackGoldWarGetBattleRecord 9009 { #获取历史战绩
        request {
            actId 1: uint32 #活动id
        }
        response {
            winCount 1: integer # 胜利场次
            failCount 2: integer # 失败场次
            records 3: *BlackGoldWarBattleRecord #战斗记录列表
        }
    }


]]

activityBlackGoldWarProto.s2c = activityBlackGoldWarProto.struct .. [[

]]

return activityBlackGoldWarProto