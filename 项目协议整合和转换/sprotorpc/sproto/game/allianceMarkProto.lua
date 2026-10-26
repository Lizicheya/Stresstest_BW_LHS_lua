--联盟标记 6891 ~ 6910
local allianceMarkProto = {}

allianceMarkProto.struct = [[    

    .ComMarkMessage {
        id 0: integer #留言板id
        time 1: integer #时间戳
        content 2: string #内容
        uid 3: integer #留言玩家
        nickName 4: string #玩家昵称
        headId 5: integer #头像
        headFrameId 6: integer #头像框
        customHead 7: string #自定义头像
    }
]]

allianceMarkProto.c2s = allianceMarkProto.struct .. [[
    setMark 6891 { #设置联盟标记
        request {
            markType 0: uint32 #标记类型
            sceneId 1: uint64  #64位场景id
            x 2: uint32
            y 3: uint32
            text 4: string #文本
            expireTime 5: uint32 #过期时间戳，秒
        }
        response {

        }
    }

    delMark 6892 { #删除联盟标记
        request {
            markId 0: uint32 #标记id
        }
        response {

        }
    }

    delMultiMark 6897 { #删除多条联盟标记
        request {
            markIdList 0: *uint32 #标记id
        }
        response {

        }
    }

    changeMark 6893 { #修改联盟标记
        request {
            markId 0: uint32 #标记id
            markType 1: uint32 #标记类型
            text 2: string #文本
            expireTime 4: uint32 #过期时间戳，秒
        }
        response {

        }
    }

    leaveMessage 6894 { #留言
        request {
            markId 0: uint32 #标记id
            content 2: string #留言内容
        }
        response {
            markId 0: integer #标记id
            message 1: ComMarkMessage
        }
    }

    delMessage 6895 { #删除单条留言
        request {
            markId 0: uint32 #标记id
            msgId 1: uint32 #留言板id
        }
        response {
            
        }
    }

    reqMessage 6896 { #请求留言
        request {
            markId 0: uint32 #标记id
        }
        response {
            messages 0: *ComMarkMessage(id)
            uid 1: integer
            nickName 2: string #玩家昵称
            headId 3: integer #头像
            headFrameId 4: integer #头像框
            customHead 5: string #自定义头像
        }
    }
]]

allianceMarkProto.s2c = allianceMarkProto.struct .. [[

]]

return allianceMarkProto