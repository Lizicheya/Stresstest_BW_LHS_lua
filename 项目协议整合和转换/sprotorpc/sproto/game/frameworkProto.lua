local proto = {}

proto.c2s = [[
# 心跳
heartBeat 10 {
    request {
    }
    response {
        time 0 : double # 时间戳
    }
}
# 切换后台
switchBackground 12 {
    request {
        isBackground 0 : boolean # 是否后台 true:后台 false:前台
    }
    response {
        
    }
}
# 服务器包确认
confirmNetMsg 13 {
    request {
        sessionResponse 0 : uint32 # 服务器回包确认:回包对应的请求包的session
        sessionSync 1 : uint32 # 服务器推送包确认:服务器推送包的session
    }
    response {
        time 0 : double # 时间戳
    }
}
]]

proto.s2c = [[

# 被踢了
beKicked 20 {
    request {
        reason 0 : integer # 被踢原因，为空默认是在另外一台设备登录
    }
}

# 断线重连开始
syncReconnectBegin 11 {
    request {
    }
}

# 断线重连完成
syncReconnectFinish 12 {
    request {
    }
}

]]


return proto