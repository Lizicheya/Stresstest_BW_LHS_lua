-- 任务模块 1201~1200
local taskProto = {}

taskProto.struct = [[    

    .ComTaskTypeTasks {
        type  0: integer                # 任务类型
        tasks 1: *ComTask(id)           # 任务数据
    }

    .ComTaskDay {
        ids 0: *integer   #已经领取的宝箱ID
        activityValue  1: integer  #活跃值
        resetTime 2:integer
    }

    .ComTaskChpaterLimitData  {
        taskId 1: uint32     # 限时任务id
        status 2: uint32     # 任务状态
        limitTs 3: uint32    # 限时完成时间戳
        completeTs 4: uint32 # 时间完成时间戳
        sceneObjId 5: uint64 # 场景对象obj
        posX 6: uint32       # x坐标
        posY 7: uint32       # y坐标
    }

    .ComTaskChapter {
        curChapter 1: uint32            # 当前的章节id
        isChapterFinish 2: boolean      # 所有章节是否已完成
        limitData 3: ComTaskChpaterLimitData # 章节限时任务数据
    }

    .ComTaskAllianceNovice {
        isReceiveReward 0: boolean
    }
]]

taskProto.c2s = taskProto.struct..[[

awardTask 1202 { #领取任务奖励
    request {
        id 0: uint32                   # id(每个玩家的任务id唯一)
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getTaskDayBoxReward 1203 { #领取宝箱奖励
    request {
        id 0: uint32                   # id(宝箱ID)
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getTaskChapterReward 1204 { #领取章节奖励
    request {
        chapterId 0: uint32             # 章节id
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getAlliancNoviceReward 1205 { #领取联盟新手奖励
    request {
    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getTaskTimeLimitReward 1206 { # 领取章节限时任务奖励
    request {

    }
    response {
        ress 0: *ComRes                 # 获得的资源
    }
}

getAllTaskDayAndBoxReward 1207 { # 一键领取每日任务和宝箱奖励
    request {

    }
    response {
        ress 1: *ComRes                 # 获得的资源
    }
}

]]

taskProto.s2c = taskProto.struct..[[
    autoTaskDayBoxReward 1206 { #领取宝箱奖励
        request {
            id 0: integer                   # id(宝箱ID)
            ress 1: *ComRes                 # 获得的资源
        }
    }
]]

return taskProto