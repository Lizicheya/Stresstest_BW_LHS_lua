-- 皮肤收集活动 6871 ～ 6880
local activitySkinCollectProto = {}

activitySkinCollectProto.struct = [[
    .ComActivitySkinCollectData {
        # taskIndexList 0: *ComIntInt() # 经历的任务阶段下标
        curIndex 1: integer # 客户端当前阶段
    }

    .ComActivitySkinCollectParam {
        configId 0: integer # 活动配置Id
    }

    .ComActivitySkinCollectInfo {
        actId 0: integer # 活动 id
        round 1: integer # 轮次
        state 2: integer # 状态
        param 3: ComActivitySkinCollectParam # 参数
        data 4: ComActivitySkinCollectData
    }
]]

activitySkinCollectProto.c2s = activitySkinCollectProto.struct .. [[
    reqSkinCollectTaskReward 6871 { # 领取任务奖励
        request {
            actId 0: uint32 # 活动id
            index 1: uint32 # 第几阶段
            taskId 2: uint32 # 任务id
        }
        response {
            ress 0: *ComRes     # 获得的资源
        }
    }
]]

activitySkinCollectProto.s2c = activitySkinCollectProto.struct .. [[

]]

return activitySkinCollectProto