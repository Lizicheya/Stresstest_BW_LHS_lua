--
-- author: TQING<tqing1128@gmail.com>
-- date: 2024-03-18 14:25:05
--

local pushProto = {}

pushProto.struct = [[

    .pushEventMap {
        eventGroupId 0 : integer # 事件 id
        eventValue 1 : integer # 事件开关值：0 关闭，其他 开启
    }

]]

pushProto.c2s = pushProto.struct .. [[

pushEnableEvent 6941 { # 开启推送事件
    request {
        eventGroupId 0 : uint32 # 事件 id
    }
    response {
    }
}

pushDisableEvent 6942 { # 关闭推送事件
    request {
        eventGroupId 0 : uint32 # 事件 id
    }
    response {
    }
}

]]

pushProto.s2c = pushProto.struct .. [[

]]

return pushProto