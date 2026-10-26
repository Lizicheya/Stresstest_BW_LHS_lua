-- 引导数据 7201 ~ 7210
local guideDataProto = {}

guideDataProto.struct = [[
    .ComGuideData {
        guideId 0: integer          # 引导id
        state 1: integer            # 状态
        
    }

    .ComSyncGuideData {
        news 0 : *ComGuideData(guideId)                           # 新增
        changes 1 : *ComGuideData(guideId)                        # 更新
        removes 2 : *integer                                      # 移除
    }    
]]

guideDataProto.c2s = guideDataProto.struct..[[

setGuideData 7201 { # 设置引导数据
    request {
        guideId 0: uint32           # 引导id
        state 1: uint32             # 状态
    }
    response {
        ress 0: *ComRes     # 获得的资源
    }
}

guideDataCollect 7202 { # 采集
    request {
        resType 0: uint32         # 资源类型 1粮食 2木材
        num 1: uint32             # 资源数量
    }
    response {
        
    }
}

]]

guideDataProto.s2c = guideDataProto.struct..[[

]]

return guideDataProto