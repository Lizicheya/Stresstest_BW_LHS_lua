-- 新手活动古迹探险 7231 ~ 7250
local activityAncientSearchProto = {}

activityAncientSearchProto.struct = [[
    .ComActivityAncientSearch {
        actId 1: integer               #活动id
        param 2: AncientSearchParam    #活动参数
        data  3: AncientSearchData     #活动数据
    }

    .ComSyncActivityAncientSearch {
        news 0: *ComActivityAncientSearch(actId)
        changes 1: *ComActivityAncientSearch(actId)
        removes 2: *integer
    }

    .AncientSearchParam {
        taskGroupId 1: integer #任务组id
        rewardGroupId 2: integer #奖励组id
    }

    .AncientSearchData {
        stage 1: integer        #阶段
        complete 2: boolean     #是否结束
        item 3: *ComIntInt()    #活动物品
        rewardList 4: *integer  #已领奖任务阶段

    }

    .ComSyncAncientSearchItem {
        actId 0: integer
        news 1: *ComIntInt()                           # 新增
        changes 2: *ComIntInt()                        # 修改
        removes 3: *integer                            # 删除
    }    
]]

activityAncientSearchProto.c2s = activityAncientSearchProto.struct .. [[
    reqAncientSearchStageReward 7231 { #完成拼接
        request {
            actId 1: uint32 #活动id
        }
        response {
            actId 1: integer #活动id
            stage 2: integer #阶段
            complete 3: boolean #是否完成
            ress 4: *ComRes
            rewardList 5: *integer  #已领奖任务阶段
        }
    }

]]

activityAncientSearchProto.s2c = activityAncientSearchProto.struct .. [[
    syncAncientSearchItem 7232 { #活动物品变化
        request {
            item 1: ComSyncAncientSearchItem
        }
        response {

        }
    }
]]

return activityAncientSearchProto