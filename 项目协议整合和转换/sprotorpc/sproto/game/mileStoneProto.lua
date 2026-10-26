--里程碑任务 3901 ~ 4000
local mileStoneProto = {}

mileStoneProto.struct = [[
    .ComMileStoneData {
        id 0: integer                          # 里程碑id
        status 1: integer                      # 里程碑状态(MileStoneStatus)
        beginTime 2: integer                   # 开始事件
        endTime 3: integer                     # 结束时间
        awardStatus 4:boolean                  # 里程碑奖励状态(是否有奖励可以领取)
        value 5: integer                       # 里程碑数值(任务时任务数值,排行榜时排行榜的名次)
        isAward 6: boolean                     # 是否已经领取了奖励    
        rankId 7: integer                      # 排行榜
        type 8: integer                        # 里程碑类型        
        awardQualification 9: boolean          # 是否有领奖的权限      
    }
]]

mileStoneProto.c2s = mileStoneProto.struct..[[

getMileStoneList 3901 { #获取里程碑列表
    request {
        type 0: uint32                        # 里程碑类型      
    }
    response {
        type 0: integer                        # 里程碑类型   
        list 1: *ComMileStoneData(id)
    }
}

awardMileStone 3902 { #领取里程碑奖励
    request {
        type 0: uint32                        # 里程碑类型   
        id 1: uint32                          # 里程碑id
    }
    response {
        data 0: ComMileStoneData               # 领取奖励的里程碑数据
        ress 1: *ComRes                        # 获得的资源
    }
}

]]

mileStoneProto.s2c = mileStoneProto.struct..[[

]]

return mileStoneProto