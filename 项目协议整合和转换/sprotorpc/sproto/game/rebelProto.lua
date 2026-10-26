-- 叛军入侵 8451 ～ 8480
local rebelProto = {}

rebelProto.struct = [[
    .ComInvasionTask { # 叛军入侵任务
        taskId 1: integer # 叛军入侵任务id
        createTime 2: integer # 任务创建时间戳
        status 3: integer # 任务状态 RebelInvasionStatus
        statistics 4: *ComIntInt() # 任务关联的统计
        isPopUp 5: boolean # 是否弹窗
        isBoxReward 6: boolean # 是否领取过宝箱奖励
    }

    .ComRaidTask { # 叛军突袭任务
        taskId 1: integer # 叛军突袭任务id
        createTime 2: integer # 任务创建时间戳
    }

    .ComSyncDataInvasionTask {
        news 1: *ComInvasionTask(taskId)
        changes 2: *ComInvasionTask(taskId)
        removes 3: *integer
    }

    .ComRebelInvasion {
        isTaskFinish 1: boolean           # 所有叛军入侵任务是否已完成
        tasks 2: *ComInvasionTask(taskId) # 叛军入侵任务列表
    }

    .ComSyncDataRebelInvasion {
        isTaskFinish 1: boolean           # 所有叛军入侵任务是否已完成
        tasks 2: ComSyncDataInvasionTask  # 叛军入侵任务列表
    }

    .ComSyncDataRebelRaid {
        news 1: *ComRaidTask(taskId)
        changes 2: *ComRaidTask(taskId)
        removes 3: *integer
    }

]]

rebelProto.c2s = rebelProto.struct .. [[
    reqRebelInvasionReward 8451 { # 领取叛军入侵任务奖励
        request {
            taskId 1: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    reqRebelRaidReward 8452 { # 领取叛军突袭任务奖励
        request {
            taskId 1: uint32
            isWin 2: boolean
        }
        response {
            ress 1: *ComRes
        }
    }

    rebelCancelInvasionPopUp 8453 { # 取消弹窗
        request {
            taskId 1: uint32
        }
        response {
            
        }
    }

    reqRebelInvasionBoxReward 8454 { #领取叛军入侵任务宝箱奖励
        request {
            taskId 1: uint32
        }
        response {
            ress 1: *ComRes
        }
    }
]]

rebelProto.s2c = rebelProto.struct .. [[

]]

return rebelProto