-- 沙盘集体boss 8151 ~ 8180
local invasionBossProto = {}

invasionBossProto.struct = [[
    .ComInvasionBossParam {
        groupId 1: uint32 #invasionBoss.id
        rankId 2: uint32
    }

    .ComInvasionBossHero {
        key 1: uint32
        value 2: ComHero
    }

    .ComInvasionBossRecord {
        recordId 0: uint32 # 记录id
        damage 1: uint32 # 伤害值
        heros  2: *ComInvasionBossHero() # 英雄
        time 3: uint32 # 时间戳
        
    }

    .ComInvasionBossStageAward {
        monsterCfgId 1: uint32 #boss配置表id invasionBossMonster.id
        stageIdList 2: *ComIntBool() #已领取的最高伤害档位奖励
    }

    .ComInvasionBossTopDamage {
        monsterCfgId 1: uint32
        topDamage 2: uint32
    }

    .ComInvasionBossActInfo {
        actId 0: uint32 # 活动id
        startTimestamp 1: uint32 # 活动开始时间戳
        stagesDuration 2: *uint32 # 活动阶段时间
        isOver 3: boolean # 活动是否结束
        param 4: ComInvasionBossParam # 活动参数
        monsterCfgId 5: uint32 #invasionBossMonster.id
        x 6: double #x坐标
        y 7: double #y坐标
        objId 8: integer #沙盘对象id
        attackNum 9: uint32 #当日进攻次数
        attackAwardList 10: *ComIntBool() #当日已领取的进攻次数档位奖励
        damageAwardList 11: *ComInvasionBossStageAward() #已领取的最高伤害档位奖励
        topDamageList 12: *ComInvasionBossTopDamage() #boss对应的最高伤害
    }

    .ComSyncInvasionBossActInfo {
        news 1: *ComInvasionBossActInfo(actId)
        changes 2: *ComInvasionBossActInfo(actId)
        removes 3: *uint32
    }
]]

invasionBossProto.c2s = invasionBossProto.struct..[[
    reqInvasionBossAttckRecord 8181 { #获取挑战记录
        request {
            actId 1: uint32
            monsterCfgId 2: uint32 #boss配置表id invasionBossMonster.id
        }
        response {
            topRecord 1: ComInvasionBossRecord   #对当前boss造成的最高伤害记录
            recordList 2: *ComInvasionBossRecord #战斗记录列表
        }
    }

    reqInvasionBossDamageRank 8182 { #获取boss伤害排名
        request {
            actId 1: uint32
        }
        response {
            rank 1: uint32 #没上榜为0
        }
    }
    
    reqInvasionBossDamageReward 8183 { #领取boss伤害档位奖励
        request {
            actId 1: uint32
            monsterCfgId 2: uint32
            stageIdList 3: *uint32 #档位id列表
        }
        response {
            ress 1: *ComRes
        }
    }

    reqInvasionBossAttackNumReward 8184 { #领取攻击次数档位奖励
        request {
            actId 1: uint32
            stageIdList 2: *uint32 #档位id列表
        }
        response {
            ress 1: *ComRes
        }
    }

    reqInvasionBossBattleReport 8185 { # 请求战报详情
        request {
            actId 1: uint32
            monsterCfgId 2: uint32 #boss配置表id invasionBossMonster.id
            recordId 3: uint32
        }
        response {
            battleReport 1: ComMailBattleReport
        }
    }
]]

invasionBossProto.s2c = invasionBossProto.struct..[[

]]



return invasionBossProto