-- 前期目标 7951 ~ 7970
local earlyGoalsProto = {}

earlyGoalsProto.struct = [[
    .ComSyncEarlyGoals {
        news 1: *ComIntBool() #提交阶段目标 (阶段目标Id->true)
    }
]]

earlyGoalsProto.c2s = earlyGoalsProto.struct .. [[
earlyGoalsSubmit 7951 { #提交道具
    request {
        id 1: uint32 # 阶段目标id
    }
    response {
        ress 1: *ComRes #获得的资源
    }
}

]]

earlyGoalsProto.s2c = earlyGoalsProto.struct .. [[

]]

return earlyGoalsProto