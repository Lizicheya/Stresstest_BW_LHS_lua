-- 探索肉鸽副本 7271 ~ 7350
local barrierRogueProto = {}

barrierRogueProto.struct = [[
    .ComRogueSkill {
        groupId 1: integer # 技能组id
        level 2: integer # 等级
    }

    .ComRogueBuff {
        id 1: integer # id
        buffCfgId 2: integer # barrierRogueBuff.id
        level 3: integer # 等级
        isValid 4: boolean # 是否有效
    }

    .ComRogueRoom2EventId {
        roomIndex 1: integer
        eventIdList 2: *ComRogueEventId
    }

    .ComBarrierRogue {
        first 0: boolean                        # 副本是否首次进入 true=首次进入
        enterCount 1: integer                   # 剩余进入次数
        periodTime 2: integer                   # 下次恢复次数时间
        skillPoint 3: integer                   # 剩余技能点数
        sequenceId 4: integer                   # 副本难度序号
        army 5: *ComArmyIdAndNum()              # 兵力信息
        armyCapacity 6: *ComArmyIdAndNum()      # 兵力容量
        skillList 7: *ComRogueSkill(groupId)    # 永久技能组
        buffList 8: *ComRogueBuff(id)           # 副本获得的buff组
        roomIndex 9: integer                    # 房间
        doors 10: *integer                      # 开启的门
        eventData 11: ComRogueEvent             # 事件信息
        startTimestamp 12: integer              # 副本开启时间戳
        topArmy 13: *ComArmyIdAndNum()          # 各兵种历史最高数量
        endTimestamp 14: integer                # 副本结束时间戳
        throughBarrier 15: *ComIntBool()        # 已通关难度副本
        heros 16: *ComHeroInterim(heroId)       # 临时英雄
        gear2Point 17: *ComIntInt()             # 每一组技能消耗技能点数
        firstRevive 18: boolean                 # 是否首次复活  
        nextTimestamp 19: integer               # 下次副本开启时间戳
        haveEntered 20: *ComIntBool()           # 是否进入过,没有进入过的免费
        eventMap 21: *ComRogueRoom2EventId(roomIndex)
        enteredDoors 22: *integer
    }

    .ComSyncBarrierRogue { 
        first 0: boolean                         # 副本是否首次进入 true=首次进入
        enterCount 1: integer                    # 剩余进入次数
        periodTime 2: integer                    # 下次恢复次数时间
        skillPoint 3: integer                    # 剩余技能点数
        army 4: ComSyncDataArmy                  # 兵力信息
        skillList 5: ComSyncRogueSkill           # 永久技能组
        buffList 6: ComSyncRogueBuff             # 副本获得的buff组
        startTimestamp 7: integer                # 副本开启时间戳
        topArmy 8: ComSyncDataArmy               # 各兵种历史最高数量
        endTimestamp 9: integer                  # 副本结束时间戳
        sequenceId 10: integer                   # 副本难度序号
        roomIndex 11: integer                    # 房间
        armyCapacity 12: ComSyncDataArmy         # 兵力容量
        heros 13: ComSyncRogueHero               # 临时英雄
        firstRevive 14: boolean                  # 是否首次复活
        gear2Point 15: ComSyncGear2Point         # 每一组技能消耗技能点数
        nextTimestamp 16: integer                # 下次副本开启时间戳
        eventMap 21: ComSyncRogueRoom2EventId
    }

    .ComRogueSlot {
        slotId 1: integer               # 槽位ID
        itemId 2: integer               # 物品ID
        buyCount 3: integer             # 购买数量
    }

    .ComRogueEvent {
        eventId 0: integer                    # 事件id
        eventType 1: integer                  # 事件类型
        isComplete 2: boolean                 # 前置事件是否完成
        army 3: *ComArmyIdAndNum()            # 敌方兵力信息 战斗事件
        armyCapacity 4: *ComArmyIdAndNum()    # 敌方兵力容量
        buffList 5: *integer                  # 可供选择的buff列表
        slots 6: *ComRogueSlot(slotId)        # 商店数据 商店事件
        isOver 7: boolean                     # 当前房间是否结束
        heros 8: *integer                     # 敌方上阵英雄
        refreshBuffTimes 9: integer           # 当前付费刷新buff列表次数
        buffGroupId 10: integer               # buff组id
    }
    
    .ComSyncRogueBuff {
        news 1: *ComRogueBuff(id)                           # 新增buff列表
        changes 2: *ComRogueBuff(id)                        # 更新buff列表
        removes 3: *integer                                 # 删除buff
    }
    
    .ComSyncRogueSkill {
        news 1: *ComRogueSkill(groupId)                     # 新增技能列表
        changes 2: *ComRogueSkill(groupId)                  # 更新技能列表
        removes 3: *integer                                 # 删除技能
    }
    
    .ComRogueTroopHero { #上阵英雄
        heroId 0: integer #英雄ID 临时获得的英雄必填,自己养成类的英雄不填
        heroCfgId 1: integer #配置表id
    }

    .ComSyncRogueHero {
        news 1: *ComHeroInterim(heroId)                     # 新增英雄
        changes 2: *ComHeroInterim(heroId)                  # 更新英雄
        removes 3: *integer 
    }

    .ComSyncGear2Point {
        news 1: *ComIntInt()                          # 新增
        changes 2: *ComIntInt()                       # 更新
        removes 3: *integer                           # 删除
    }

    .ComRogueEventId {
        eventType 1: integer
        eventId 2: integer
    }

    .ComSyncRogueRoom2EventId {
        news 1: *ComRogueRoom2EventId(roomIndex)
        changes 2: *ComRogueRoom2EventId(roomIndex)
        removes 3: *integer
    }

]]

barrierRogueProto.c2s = barrierRogueProto.struct..[[
    enterBarrierRogue 7271 { # 进入副本
        request {
            seqId 1: uint32
        }
        response {
            enterCount 1: integer                  # 剩余进入次数
            periodTime 2: integer                  # 下次恢复次数时间
            roomIndex 3: integer                   # 房间
            seqId 4: integer
        }
    }

    exitBarrierRogue 7272 { # 退出副本
        request {

        }
        response {

        }
    }

    enterRogueRoom 7273 { # 进入房间
        request {
            doorIndex 1: uint32                   # 选择进入的门
        }
        response {
            roomIndex 1: integer                   # 房间
            eventData 2: ComRogueEvent             # 事件信息
            doorIndex 3: uint32                   # 选择进入的门
        }
    }

    rogueEventComplete 7274 { # 前置事件完成 对话剧情、拼图游戏、打开宝箱等
        request {
            
        }
        response {
            buffList 1: *integer   # 可供选择的buff列表
            reward 2: *ComRes      # 房间奖励
            isOver 3: boolean      # 当前房间是否结束
            buffGroupId 4: integer # buff组id
        }
    }

    selectRogueBuff 7275 { # 选择buff
        request {
            buffIndex 1: uint32
        }
        response {
            reward 1: *ComRes                       # 房间奖励
            isOver 2: boolean      # 当前房间是否结束
            buffList 3: *integer   # 可供选择的buff列表
            refreshBuffTimes 4: integer # 当前付费刷新次数
            buffGroupId 5: integer # buff组id
        }
    }

    buyRogueShopItem 7276 { # 商店购买
        request {
            slotId 1: uint32                   # 槽位ID
            count 2: uint32                    # 购买商品次数   
        }
        response {
            slots 1: *ComRogueSlot(slotId)      # 商店数据
            ress 2: *ComRes                     # 获得的资源
        }
    }

    reviveRogueArmy 7277 { # 复活
        request {

        }
        response {

        }
    }

    levelUpRogueSkill 7278 { # 升级技能
        request {
            groupId 1: uint32
        }
        response {
            gear2Point 1: *ComIntInt()          # 每一组技能消耗技能点数
        }
    }

    resetRogueSkill 7279 { # 重置技能
        request {
        }
        response {

        }
    }

    rogueAddTroop 7280 { # 上阵
        request {
            army 0: *ComArmyIdAndNum()
            heros 1: *ComRogueTroopHero
        }
        response {
            army 1: *ComArmyIdAndNum()            # 敌方兵力信息 战斗事件
            buffList 2: *integer   # 可供选择的buff列表
            reward 3: *ComRes      # 房间奖励
            isOver 4: boolean      # 当前房间是否结束
            battleReport 5: ComMailBattleReport #战报
            lossNum 6: integer #损失兵力
            buffGroupId 7: integer # buff组id
        }
    }

    refreshRogueBuff 7281 { # 付费属性buff列表
        request {
            
        }
        response {
            buffList 1: *integer   # 可供选择的buff列表
            refreshBuffTimes 2: integer # 当前付费刷新次数
            buffGroupId 3: integer # buff组id
        }
    }

]]

barrierRogueProto.s2c = barrierRogueProto.struct..[[
    barrierRogueOver 7230 {
        request {
            seqId 1: uint32 # 难度序号
            isThrough 2: boolean #是否通关
            isQuit 3: boolean #是否选择退出
        }
    }

    barrierRogueTargetArmySync 7282 {
        request {
            army 1: *ComArmyIdAndNum()            # 敌方兵力信息(加成前) 战斗事件
        }
    }
]]

return barrierRogueProto