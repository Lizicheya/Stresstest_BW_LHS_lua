-- 联盟聊天红包 8431 ~ 8450
local allianceChatBonusProto = {}

allianceChatBonusProto.struct = [[
    .ComAllianceChatBonusRecvDetail { # 聊天红包领取详情
        recvUid 0: integer         # 领取者uid        
        recvTime 1: integer        # 领取时间戳，秒
        ress 2: *ComRes            # 领取到的资源

        nickName 10: string        # 领取者昵称
        headId 11: integer         # 头像
        headFrameId 12: integer    # 头像框
        customHead 13: string      # 自定义头像
    }

    .ComAllianceChatBonusDetail {
        id 0: integer                # 红包唯一 id
        uid 1: integer               # 发送者uid
        cfgId 2: integer             # 配置id
        sendTime 3: integer          # 发送时间戳，秒
        expireTime 4: integer        # 过期时间戳，秒
        recvList 5: *ComAllianceChatBonusRecvDetail(recvUid)  # 领取详情列表

        nickName 10: string          # 发送者昵称
        headId 11: integer           # 头像
        headFrameId 12: integer      # 头像框
        customHead 13: string        # 自定义头像
    }

    .ComAllianceChatBonusListItem {
        id 0: integer                # 红包唯一 id
        uid 1: integer               # 发送者uid
        cfgId 2: integer             # 配置id
        sendTime 3: integer          # 发送时间戳，秒
        expireTime 4: integer        # 过期时间戳，秒
        recv 5: boolean              # 是否已领取
        recvCount 6: uint32          # 已领取次数
    }
    
    .ComSyncAllianceChatBonusList {
        news 0: *ComAllianceChatBonusListItem(id)
        changes 1: *ComAllianceChatBonusListItem(id)
        removes 2: *integer
    }
]]

allianceChatBonusProto.c2s = allianceChatBonusProto.struct .. [[
    gainAllianceChatBonus 8431 {     # 领取联盟聊天红包奖励    
        request {
            chatBonusId 0: uint32    # 红包id
        }
        response {
            ress 0: *ComRes          # 领取的资源
        }
    }

    getAllianceChatBonusDetail 8432 {   # 获取联盟聊天红包详情
        request {
            chatBonusId 0: uint32       # 红包id
        }
        response {
            detail 0: ComAllianceChatBonusDetail  # 联盟聊天红包详情
        }
    }

    getGainAllianceChatBonus 8433 {      # 获取未过期的联盟聊天红包领取信息
        request {
        }
        response {
            gainChatBonusIds 0: *integer # 领取过的联盟聊天红包id列表
        }
    }
]]

allianceChatBonusProto.s2c = allianceChatBonusProto.struct .. [[
]]

return allianceChatBonusProto
