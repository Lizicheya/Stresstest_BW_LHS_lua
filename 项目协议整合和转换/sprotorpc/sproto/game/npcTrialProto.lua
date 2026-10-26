-- 怪物试炼 7551 - 7600
local npcTrialProto = {}

npcTrialProto.struct = [[
    #活动信息
    .ComNpcTrialActInfo {
        seasonId 0: integer      # 第几赛季
        round 1: integer         # 第几轮
        status 2: integer        # 状态 NpcTrialStatus
        statusEndTime 3: integer # 状态结束时间
        durations 4: *integer    # 状态时间
        startTime 5: integer     # 本轮开始时间
        groupId 6: integer       # 组id
    }

    #玩家进度数据
    .ComNpcTrialProgress {
        lv 0: integer      # 当前等级
        maxlv 1: integer   # 最高等级
        npcId 2: integer   # 怪物id
        harmRate 3: integer   # 最大伤害比例(百分比 值50=50%)
        hasQuick 4: boolean  # 是否已快速战斗
    }

    #玩家数据
    .ComNpcTrialPly {
        aid 0: integer       # 参与aid
        helpTs 1: integer    # 帮助时间戳
        helpCnt 2: integer   # 我帮助别人的次数
        beHelpCnt 3: integer # 我被帮助的次数
        progress 4: *ComNpcTrialProgress # 进度
        npcDiff 5: integer   # 当前怪物难度 1=普通 2=精英
        npcObjId 6: integer  # 当前怪物地图对象ID
        awardId 7: integer   # 玩家档位奖励
        score 8: integer     # 玩家个人积分
        npcFailCnt 9: integer  # 怪物挑战失败次数
        stat 10 : *ComIntInt() # 玩家杀怪统计 npcId=数量
        helpDot 11: integer    # 小红点>0
        npcPosX 12: integer    # 当前怪物地图对象坐标
        npcPosY 13: integer    # 当前怪物地图对象坐标
        beHelpUids 14 : *ComIntBool() # 我被哪些帮助 uid=true
    }

    #联盟数据
    .ComNpcTrialAli {
        awardId 0: integer   # 联盟档位奖励
        score 1: integer     # 联盟积分
        stat 2 : *ComIntInt() # 联盟杀怪统计 npcId=数量
    }

    #怪物试炼数据
    .ComNpcTrialData {
        actInfo 0: ComNpcTrialActInfo # 活动信息
        trials 1: ComNpcTrialPly # 玩家数据
        trialAli 2: ComNpcTrialAli # 联盟数据
    }

    #怪物协助阵容数据
    .ComNpcTrialFormationData {
        uid 0: integer                                          # 玩家id
        nickName 1: string                                      # 玩家昵称
        headId 2: integer                                       # 玩家头像id
        headFrameId 3: integer                                  # 玩家头像框id
        helpTs 4: integer                                       # 协助次数时间戳
        helpCnt 5: integer                                      # 协助次数
        power 6: integer                                        # 战力
        formation 7: ComFormation                              # 阵型信息

    }

    #怪物协助阵容数据
    .ComNpcTrialHelpData {
        uid 0: integer                                          # 玩家id
        nickName 1: string                                      # 玩家昵称
        npcDiff 2: integer                                      # 怪物难度 1=普通 2=精英
        npcLv 3: integer                                        # 怪物等级 allianceMonsterTrial表的lv
        npcId 4: integer                                        # 怪物id
        award 5: boolean                                        # 是否已领奖
        ts 6: integer                                           # 时间戳
    }
 ]]

npcTrialProto.c2s = npcTrialProto.struct .. [[
 getNpcTrialInfo 7551 { #获取怪物试炼信息
    request {
    }
    response {
        trialAli 0: ComNpcTrialAli # 联盟数据
    }
 }

 getNpcTrialMonster 7552 { # 获取怪物试炼怪物信息
    request {
        npcDiff 0: uint64 # 怪物难度 1=普通 2=精英
    }
    response {
        npcId 0: integer   #  npc id
        npcObjId 1: integer   #  npc对象id
        npcPosX 2: integer   #  npc地图坐标
        npcPosY 3: integer   #  npc地图坐标
    }
 }

 getNpcTrialFormations 7553 { # 获取怪物试炼协助阵容
    request {
    }
    response {
        formations 0: *ComNpcTrialFormationData(uid)
    }
 }

 getNpcTrialHelpedList 7554 { # 获取协助成功列表
    request {
    }
    response {
        list 0: *ComNpcTrialHelpData
    }
 }

 getNpcTrialHelpedAward 7555 { # 获取协助奖励
    request {
        keys 0: *uint64                #传数组下标
    }
    response {
        list 0: *ComNpcTrialHelpData
        ress 1: *ComRes                 # 获得的资源
    }
 }

  setNpcTrialFailCnt 7556 { # 设置挑战失败次数
    request {
        cnt 0: uint32
    }
    response {
    }
 }

 reqNpcTrialQuickBattle 7557 { # 请求快速战斗
    request {
        npcDiff 0: uint64                                      # 怪物难度 1=普通 2=精英
    }
    response {
        lv 0: integer                   # 快速战斗到哪个等级
        ress 1: *ComRes                 # 获得的资源
    }
 }

]]

npcTrialProto.s2c = npcTrialProto.struct .. [[

]]

return npcTrialProto
