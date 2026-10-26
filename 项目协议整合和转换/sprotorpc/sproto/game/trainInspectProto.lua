-- 暗区行动 （养成校验） 8781 ~ 8810
local trainInspect = {}

trainInspect.struct = [[
    .ComTrainInspect {   # 暗区行动一个主题的信息
        cfgId 0: integer
        round 1: integer

        startTimestamp 3: integer
        overTimestamp 4: integer

        damage 5: integer          # 造成最高伤害
        gainList 6: *ComIntInt()   # 奖励领取状态
    }

    .ComSyncTrainInspect {
        news 0: *ComTrainInspect(cfgId)
        changes 1: *ComTrainInspect(cfgId)
        removes 2: *integer
    }

    .ComTrainInspectBaseHisGain {
        cfgId 0: integer
        gainList 1: *ComIntInt()
    }    

    .ComTrainInspectBase {                                   # 暗区行动基础数据
        hisDamage 0: *ComIntInt()                            # 每个主题的历史最高伤害
        hisGainList 1: *ComTrainInspectBaseHisGain(cfgId)    # 每个主题的历史最高伤害奖励领取状态
        hisTotalGainList 2: *ComIntInt()                     # 所有主题历史最高伤害总和的达标奖励状态
    }

    .ComTrainInspectRecordHero {
        heroCfgId 0: integer
        power 1: integer
        starLv 2: uint32
        lv 3: uint32
        pos 4: uint32
    }

    .ComTrainInspectRecordEnemyArmy {     # 敌方军队信息
        army 1: *ComUint32Uint32()
        curLoseNum 2: integer             # 损失数量
        ruce 3: *ComArmyIdAndNum()        # 轻伤
        wound 4: *ComArmyIdAndNum()       # 重伤
        dead  5: *ComArmyIdAndNum()      # 死亡    
        remain 6: *ComArmyIdAndNum()     # 生还
    }

    .ComTrainInspectRecord {              # 暗区行动的战斗记录
        id 0: integer
        cfgId 1: integer
        army 2: *ComUint32Uint32()
        heros 3: *ComTrainInspectRecordHero(pos)
        damage 4: integer
        createTime 5: integer
        fightPower 6: integer

        enemyArmy 7: ComTrainInspectRecordEnemyArmy # 敌方军队信息
    }
    
    .ComSyncTrainInspectRecord {
        news 0: *ComTrainInspectRecord(id)
        removes 2: *integer
    }
]]

trainInspect.c2s = trainInspect.struct .. [[
    challengeTrainInspect 8781 {        # 挑战暗区行动
        request {
            cfgId 0: uint32 

            army 10: *ComArmyIdAndNum()  # 派出军队
            heros 11: *ComUint32Uint32() # 派出英雄
        }
        response {
            damage 0: integer           # 伤害
            ress 1: *ComRes             # 伤害达标获得的资源
            hisRess 2: *ComRes          # 历史伤害获得的资源
        }
    }

    reqTrainInspectTotalHisAward 8782 { # 领取暗区行动，所有主题总历史最高伤害达标奖励
        request {
            index 0: uint32
        }
        response {
            ress 0: *ComRes             # 伤害达标获得的资源
        }
    }

    trainInspectReport 8783 {           # 暗区行动战报
        request {
            cfgId 0: uint32             # 主题配置id
            index 1: uint32
        }
        response {
            report 2: ComMailBattleReport   # 数据对撞的战报
        }
    }

    trainInspectPveBattleResult 8784 {          # 暗区行动 pve 战斗结果
        request {
            levelId 0: uint32                   # 关卡ID
            formation 1: *ComUint32Uint32()     # 阵容数据
            iswin 2: boolean
            sceneObjId 3: uint64                # 沙盘对象id
            damage 4: uint64                    # 造成伤害
        }
        response {
            ress 1: *ComRes             # 伤害达标获得的资源
            hisRess 2: *ComRes          # 历史伤害获得的资源
        }
    }
]]

trainInspect.s2c = trainInspect.struct .. [[
]]

return trainInspect
