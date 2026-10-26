-- 复兴城镇 9151 ~ 9180
local innerCityRevivalProto = {}

innerCityRevivalProto.struct = [[
    .ComInnerCityRevivalTask {  # 任务
        taskId 1: integer       # 任务id
        status 2: integer       # 任务状态 1:进行中 2:完成
        count 3: integer        # 任务当前进度数量
    }

    .ComSyncInnerCityRevivalTask { # 任务同步
        news 1: *ComInnerCityRevivalTask(taskId)
        changes 2: *ComInnerCityRevivalTask(taskId)
        removes 3: *integer
    }

    .ComInnerCityRevival {                        # 复兴城镇
        revivalId 1: uint32                       # 当前复兴城镇id
        isFinish 2: boolean                       # 是否全部完成
        tasks 3: *ComInnerCityRevivalTask(taskId) # 任务列表
    }
    
    .ComSyncInnerCityRevival { 
        revivalId 1: uint32                  # 当前区域id
        isFinish 2: boolean                  # 是否全部完成
        tasks 3: ComSyncInnerCityRevivalTask # 任务同步
    }
]]

innerCityRevivalProto.c2s = innerCityRevivalProto.struct .. [[
    innerCityRevivalRecover 9151 { # 请求收复区域
        request {
            revivalId 1: uint32    # 区域id
        }
        response {
            ress 1: *ComRes        # 奖励列表
        }
    }
]]

innerCityRevivalProto.s2c = innerCityRevivalProto.struct .. [[
]]

return innerCityRevivalProto
