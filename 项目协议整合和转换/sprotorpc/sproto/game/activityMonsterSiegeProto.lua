-- 联盟怪物攻城 6951 ~ 6980
local activityMonsterSiegeProto = {}
activityMonsterSiegeProto.struct = [[
    .ComActivityMonsterSiege { #怪物攻城数据
        actId 0 : integer # 活动id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        param 3 : MonsterSiegeParam # 活动参数
        data  4 : MonsterSiegeData
    }

    .MonsterSiegeParam {
        allianceRankId 1: integer #联盟积分榜
        personRankId 2: integer #个人积分榜
    }

    .ComSiegeMember {
        uid 0: integer #玩家uid
        score 1: integer #玩家个人积分
        failNum 2: integer #失败次数
    }

    .MonsterSiegeData {
        lastDifficulty 0: integer #上次活动选择的难度
        difficulty 1: integer #当前选择的难度
        siegeTime 2: integer #预约开启时间
        highestScore 3: integer #历史最高联盟积分
        score 4: integer #当前联盟积分
        members 5: *ComSiegeMember(uid) #活动参与人员id
        totalRound 6: integer #攻城总轮次
        curRound 7: integer #当前攻城轮次
        attackData 8: ComSiegeAttack #攻城数据
        attackEndTime 9: integer #攻城阶段结束时间
        isOver 10: boolean #攻城是否结束
        unlockDifficulty 11: integer # 已经解锁的最高难度
    }    

    .ComSiegeAttack {
        monsterId 1: integer #怪物id
        attackType 2: integer #怪物攻击目标 1全部联盟成员 2随机抽取联盟成员 3联盟中心 4随机抽取联盟中心
        idList 3: *integer #被攻击目标id
        attackStage 4: integer # 1准备中 2刷新中
        stageEndTime 5: integer # 当前状态结束时间
    }
]]

activityMonsterSiegeProto.c2s = activityMonsterSiegeProto.struct .. [[
    siegeReservation 6951 { #预约开启
        request {
            actId 0: uint32       #活动id
            difficulty 1: uint32  #难度
            siegeTime 2: uint32   #预约攻城时间
        }
        response {

        }
    }

    siegeImmediately 6952 { #手动开启
        request {
            actId 0: uint32       #活动id
            difficulty 1: uint32  #难度
        }
        response {

        }
    }

    cancelSiegeReservation 6953 { #取消预约开启
        request {
            actId 0: uint32       #活动id
        }
        response {

        }
    } 
]]

activityMonsterSiegeProto.s2c = activityMonsterSiegeProto.struct .. [[
    playerMonsterSiegeChange 6954 {
        request {
            actId 0: integer #活动id
            uid 1: integer #玩家id
            score 2: integer #个人积分
            failNum 3: integer #失败次数
            totalScore 4: integer #联盟总积分
        }
        response {

        }
    }
]]


return activityMonsterSiegeProto