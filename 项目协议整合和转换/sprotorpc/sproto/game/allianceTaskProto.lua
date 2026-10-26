--联盟任务 3801 ~ 3900
local allianceTaskProto = {}

allianceTaskProto.struct = [[
    .ComAllianceCycleTaskInfo {
        cycleType 0: integer                          #类型 1:每日 2:每周
        idList 1: *integer                            #已经领取的任务ID
        tasks 2: *ComTask(id)                         # 任务数据
        nextResetTime 3: integer                      # 下次刷新时间
    }

    .ComAllianceCycleTaskNum {
        cycleType 0: integer                          #类型 1:每日 2:每周
        num 1: integer
    }

    .ComAlliancePlayerTask {
        id 0: integer                   # id(每个玩家的任务id唯一)
        status 1: integer               # 任务状态
        count 2: integer                # 任务当前进度数量
        cfgId 3: integer                # 任务配置ID
        finishTime 4: integer           # 任务完成时间
        
        overTime 5: integer             # 任务结束时间
        taskGroupId 6: integer
    }

]]

allianceTaskProto.c2s = allianceTaskProto.struct .. [[
    allianceCycleTaskInfo 3801 {                          #获取联盟循环任务请求
        request {
            cycleType 0: uint32
        }

        response {
            info 0: ComAllianceCycleTaskInfo
        }
    }

    awardAllianceCycleTask 3802 {
        request {
            cycleType 0: uint32                        #类型 1:每日 2:每周
            taskId 1: uint32                           #联盟任务ID
        }

        response {
            ress 0: *ComRes                                 # 获得的资源
            cycleType 1: integer
            idList 2: *integer                            #已经领取的任务ID
        }
    }

    alliancePlayerTaskInfo 3807 {                      # 获取联盟个人任务
        request {

        }
        response {
            freeCount 1: integer                       # 任务免费刷新次数
            groupCount 2: *ComIntInt()                 # 任务组的刷新次数
            nextResetTime 3: integer
        }
    }

    refreshAlliancePlayerTask 3809 {                    # 刷新联盟个人任务
        request {
            taskId 1: uint32                           # 联盟任务ID
        }
        response {
            taskId 1: integer                          # 联盟任务ID
            freeCount 2: integer                       # 任务免费刷新次数
            groupCount 3: *ComIntInt()                 # 任务组的刷新次数
            nextResetTime 4: integer
        }
    }
   
]]

allianceTaskProto.s2c = allianceTaskProto.struct .. [[
    allianceCycleTaskChangeNotice 3805 {
        request {
            taskNumList 0 : *ComAllianceCycleTaskNum(cycleType) #可领奖任务数量
        }

        response {
        }
    }

    allianceCycleTaskRefresh 3806 {
        request {
            cycleType 0: integer
            info 1: ComAllianceCycleTaskInfo
            taskNum 2 : integer #可领奖任务数量
        }
        response {
        }
    }

]]

return allianceTaskProto