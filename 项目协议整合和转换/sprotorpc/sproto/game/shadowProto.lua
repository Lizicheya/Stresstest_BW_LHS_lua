-- 暗影行动 8381 ~ 8430
local shadowProto = {}

shadowProto.struct = [[
    .ComShadowTaskBeHelp {    # 暗影任务活动被帮助信息
        uid 0: integer        # 帮助者 uid
        helpTime 1: integer   # 帮助时间戳，秒
        ress 2: *ComRes       # 获得的资源
    }

    .ComShadowTaskBeRob {     # 暗影任务活动被抢劫
        uid 0: integer        # 帮助者 uid
        robTime 1: integer    # 抢劫时间戳，秒
        ress 2: *ComRes       # 获得的资源
        emojiId 3: uint32     # 抢劫后设置的表情ID
    }

    .ComShadowTaskHero {
        heroId 0: uint32      # 英雄 id
    }

    .ComShadowTask { # 暗影任务活动信息
        id 0: uint32                   # 任务唯一 id
        cfgId 1: uint32                # 配置id
        createTime 2: integer          # 任务创建时间戳
        completeTime 3: integer        # 任务完成时间戳，为 0 说明还没开始执行，小于当前时间说明任务完成
        status 4: integer              # 任务状态，0：未开始，1：进行中，2：已完成未领取，3：已完成已领取

        sceneObjId 5: integer          # 任务对应的场景对象 id
        posX 6: uint32
        posY 7: uint32

        beHelpedList 8: *ComShadowTaskBeHelp(uid)  # 任务被帮助列表
        beRobList 9: *ComShadowTaskBeRob(uid)      # 任务被抢劫列表

        heros 10: *ComShadowTaskHero(heroId)        # 派遣出的英雄列表
    }

    .ComDailyShadowTasks {
        taskList 0: *ComShadowTask(id)   # 暗影任务列表
    }

    .ComSyncDailyShadowTaskList {
        news 1: *ComShadowTask(id)
        changes 2: *ComShadowTask(id)
        removes 3: *integer
    }

    .ComSyncDailyShadowTasks {
        taskList 0: ComSyncDailyShadowTaskList
    }
    
    .ComDailyShadowBase {
        openStar 0: uint32                    # 开启的星级
        lastDayResetTime 1: integer           # 上次每日重置时间 秒
        lastSpecialRewardResetTime 2: integer # 上次特殊奖励重置时间 秒
        dayRobTimes 3: uint32                 # 今日抢劫次数
        dayHelpTimes 4: uint32                # 今日帮助他人次数
    }
        
    .ComAllianceHelpShadowTask {   # 一个可以帮助的暗影任务
        id 0: uint32
        taskId 1: uint32           # 暗影任务的唯一id
        uid 2: integer             # 任务所属玩家 uid
        cfgId 3: uint32            # 暗影任务配置id
    }

    .ComSyncPlayerAllianceHelpShadowTask {
        news 0: *ComAllianceHelpShadowTask(id)
        changes 1: *ComAllianceHelpShadowTask(id)
        removes 2: *integer
    }

    .ComDailyShadowHelpRobHistoryRecord { 
        taskId 0: uint32      # 暗影任务的唯一id
        cfgId 1: uint32
        addTime 2: integer    # 被抢劫/帮助的时间戳（秒）
        logType 3: uint32     # # 被抢劫/帮助的时间戳（秒）
        uid 4: integer
        ress 5: *ComRes       # 获得的资源
        emojiId 6: uint32     # 抢劫后设置的表情ID
    }

    .ComShadowTaskReward {
        taskId 0: uint32    # 任务 id
        ress 1: *ComRes     # 获得的资源
    }
]]

shadowProto.c2s = shadowProto.struct .. [[
    reqExecShadowTask 8381 { # 执行暗影行动任务
        request {
            taskId 0: uint32   # 任务 id
            heroIds 1: *uint32 # 派遣的英雄 id 列表
        }
        response {
        }
    }
    
    reqShadowTaskReward 8382 {  # 领取暗影行动任务奖励
        request {
            taskId 0: uint32    # 任务 id
        }
        response {
            ress 0: *ComRes     # 获得的资源
        }
    }

    reqRefreshShadowTasks 8383 {   # 手动刷新暗影行动任务
        request {
            useItemType 0: uint32  # 1:道具 2:钻石
        }
        response {
        }
    }

    reqHelpShadowTask 8384 {      # 帮助暗影行动任务
        request {
            targetUid 0: uint64  # 目标玩家 uid
            taskId 1: uint32      # 任务 id
        }
        response {
            ress 0: *ComRes       # 获得的资源
        }
    }

    reqRobShadowTask 8385 {       # 抢劫暗影行动任务
        request {
            targetUid 0: uint64  # 目标玩家 uid
            taskId 1: uint32      # 任务 id
        }
        response {
            ress 0: *ComRes       # 获得的资源
        }
    }

    reqSetRobShadowTaskEmoji 8386 {  # 设置抢劫暗影行动任务表情
        request {
            targetUid 0: uint64  # 目标玩家 uid
            taskId 1: uint32      # 任务 id
            emojiId 2: uint32     # 表情 id
        }
        response {
        }
    }

    getShadowHelpRobHistory 8387 {     # 获得被抢劫/帮助历史记录
        request {
        }
        response {
            list 0: *ComDailyShadowHelpRobHistoryRecord
        }
    }

    reqShadowTaskRewards 8388 {  # 批量领取暗影行动任务奖励
        request {
            taskIds 0: *uint32   # 任务 id 列表
        }
        response {
            rewards 0: *ComShadowTaskReward      # 获得的资源
        }
    }
]]

shadowProto.s2c = shadowProto.struct .. [[
]]

return shadowProto
