-- 收复区域 9081 ~ 9090
local innerCityRegionProto = {}

innerCityRegionProto.struct = [[
    .ComInnerCityRegionTask { # 内城区域任务
        taskId 1: integer # 任务id
        status 2: integer # 任务状态 1:进行中 2:完成
        count 3: integer # 任务当前进度数量
    }

    .ComSyncDataInnerCityRegionTask { # 内城区域任务同步
        news 1: *ComInnerCityRegionTask(taskId)
        changes 2: *ComInnerCityRegionTask(taskId)
        removes 3: *integer
    }
    
    .ComInnerCityRegion { # 内城区域
        regionId 1: uint32 # 当前区域id
        tasks 2: *ComInnerCityRegionTask(taskId) # 任务列表
        isFinish 3: boolean # 是否全部完成
    }
    
    .ComSyncDataInnerCityRegion { # 内城区域同步
        regionId 1: uint32 # 当前区域id
        tasks 2: ComSyncDataInnerCityRegionTask # 任务同步
        isFinish 3: boolean # 是否全部完成
    }
]]

innerCityRegionProto.c2s = innerCityRegionProto.struct .. [[
    innerCityRegionRecover 9081 { # 请求收复内城区域
        request {
            regionId 1: uint32 # 区域id
        }
        response {
            ress 1: *ComRes # 奖励列表
        }
    }
]]

innerCityRegionProto.s2c = innerCityRegionProto.struct .. [[

]]

return innerCityRegionProto