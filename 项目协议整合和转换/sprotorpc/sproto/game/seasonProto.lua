-- 赛季/编年史 7651-7700
local seasonProto = {}

seasonProto.struct = [[
    #赛季活动信息
    .ComSeasonActInfo {
        round 0: integer         # 第几轮
        groupId 1: integer       # 组id
        startTimestamp 2: integer # 本轮开启时间
        status 3: integer        # 状态 seasonStatus
        statusStartTime 4: integer # 状态开始时间
        statusEndTime 5: integer # 状态结束时间
        durations 6: *integer    # 状态时间
        vsCamp 7: *ComIntInt()   # 对战阵营 如 [1]=2,[2]=1 表示1vs2 2vs1
        stage 8: integer         # 当前阶段
        stageEndTime 9: integer  # 当前阶段结束时间
    }

    #个人宝典数据
    .ComSeasonTreasure {
        id 0: integer            # 宝典id
        lv 1: integer            # 宝典等级
    }

    #个人科技数据
    .ComSeasonTech {
        id 0: integer            # 科技id
        lv 1: integer            # 科技等级
    }

    #个人科技数据
    .ComSeasonTechTp {
        key 0: integer           # 科技类型
        value 1: *ComSeasonTech(id)
    }

    #个人科技数据
    .ComSeasonAchievement {
        id 0: integer            # 成就id
        lv 1: integer            # 成就等级
        award 2: boolean         # 是否领奖
    }

    #赛季数据
    .ComSeasonData {
        actInfo 0: ComSeasonActInfo # 赛季活动信息
        treasures 1: *ComSeasonTreasure(id) # 宝典
        techPoint 2: integer # 科技点
        techs 3: *ComSeasonTechTp() # 科技
        previewAward 4: *integer # 预告奖励
        stageTaskAward 5: *integer # 阶段目标任务奖励
        stageTasks 6: *ComTask(id) # 阶段目标任务
        svrTaskAward 7: *integer # 全服挑战任务奖励
        svrTasks 8: *ComTask(id) # 全服挑战任务
        aliTaskAward 9: *integer # 联盟挑战任务奖励
        aliTasks 10: *ComTask(id) # 联盟挑战任务
        achievement 11: *ComSeasonAchievement(id) # 成就
        gloryLv 12: integer # 荣耀等级
        gloryMaxLv 13: integer # 荣耀最大等级
        coin 14: integer # 赛季币
        coinMax 15: integer # 赛季币
        vsCoin 16: *integer # 对战双方赛季币
        roundShow 17: integer # 展示荣耀等级的轮次
    }

    #赛季数据
    .ComSyncSeasonData {
        actInfo 0: ComSeasonActInfo # 赛季活动信息
        treasures 1: *ComSeasonTreasure(id) # 宝典
        techPoint 2: integer # 科技点数
        techs 3: *ComSeasonTechTp() # 科技
        previewAward 4: *integer # 预告奖励
        stageTaskAward 5: *integer # 阶段目标任务奖励
        stageTasks 6: ComSyncDataTask # 阶段目标任务
        svrTaskAward 7: *integer # 全服挑战任务奖励
        svrTasks 8: ComSyncDataTask # 全服挑战任务
        aliTaskAward 9: *integer # 联盟挑战任务奖励
        aliTasks 10: ComSyncDataTask # 联盟挑战任务
        achievement 11: *ComSeasonAchievement(id) # 成就
        gloryLv 12: integer # 荣耀等级
        gloryMaxLv 13: integer # 荣耀最大等级
        coin 14: integer # 赛季币
        coinMax 15: integer # 赛季币
        vsCoin 16: *integer # 对战双方赛季币
        roundShow 17: integer # 展示荣耀等级的轮次
    }

    #赛季历史成就
    .ComSeasonAchievementHistory {
        round 0: integer         # 第几轮
        groupId 1: integer       # 组id
        achievement 2: *ComSeasonAchievement(id) # 成就
        tasks 3: *ComTask(id) # 任务
    }

    #赛季历史荣耀
    .ComSeasonGloryHistory {
        round 0: integer         # 第几轮
        groupId 1: integer       # 组id
        gloryLv 2: integer       # 荣耀等级
    }
 ]]

seasonProto.c2s = seasonProto.struct .. [[
 getSeasonInfo 7651 { #获取赛季主界面信息
    request {
    }
    response {
    }
 }

 upgradeSeasonTreasure 7652 { #升级个人宝典
    request {
        id 0: uint32
    }
    response {
        treasure 0: ComSeasonTreasure
    }
 }

 upgradeSeasonTech 7653 { #升级科技
    request {
        tp 0: uint32
        id 1: uint32
    }
    response {
    }
 }

 getSeasonPreviewAward 7655 { #领取预告奖励
    request {
        id 0: uint32
    }
    response {
        ress 0 : *ComRes # 奖励列表
    }
 }

 getSeasonAllianceTaskInfo 7656 { #获取联盟挑战任务信息
    request {
    }
    response {
        aliTasks 0: *ComTask(id) # 任务数据
    }
 }

 getSeasonAllianceTaskAward 7657 { #获取联盟挑战任务奖励
    request {
        id 0: uint32
    }
    response {
        id 0: integer
    }
 }

 getSeasonStageTaskInfo 7658 { #获取阶段目标任务信息
    request {
    }
    response {
        stageTasks 0: *ComTask(id) # 任务数据
    }
 }

 getSeasonStageTaskAward 7659 { #获取阶段目标任务奖励
    request {
        id 0: uint32
    }
    response {
    }
 }

  getSeasonSvrTaskInfo 7660 { #获取全服挑战任务信息
    request {
    }
    response {
        svrTasks 0: *ComTask(id) # 任务数据
    }
 }

 getSeasonSvrTaskAward 7661 { #获取全服挑战任务奖励
    request {
        id 0: uint32
    }
    response {
    }
 }

  getSeasonAchievementAward 7662 { #获取成就奖励
    request {
        id 0: uint32
    }
    response {
        id 0: integer
        ress 1 : *ComRes
    }
 }

 getSeasonAchievementHistory 7663 { #获取历史成就
    request {
    }
    response {
        records 0: *ComSeasonAchievementHistory
    }
 }

  getSeasonGloryHistory 7664 { #获取历史荣耀
    request {
    }
    response {
        records 0: *ComSeasonGloryHistory
    }
  }

  setSeasonGloryLvShow 7665 { #设置展示的荣耀等级
    request {
        round 0: uint32         # 第几轮
    }
    response {
    }
  }
]]

seasonProto.s2c = seasonProto.struct .. [[

]]

return seasonProto
