-- 跑马灯（推送通知） 7441 ~ 7450
local pushNotifyProto = {}

pushNotifyProto.struct = [[

]]

pushNotifyProto.c2s = pushNotifyProto.struct..[[

]]

pushNotifyProto.s2c = pushNotifyProto.struct..[[

pushNotify 7441 { # 推跑马灯  普通推送只有 notifyId params 有值 ,系统推送 notifyId，systemMsg
    request {
       notifyId 0: integer      # 推送格式id
       params 1: *string        # 参数
       systemMsg 2: string      # 系统推送内容
    }
    response {
    }
}
]]

return pushNotifyProto