--联盟礼物与宝箱 4101 ~ 4200
local allianceProto = {}

allianceProto.struct = [[

]]

allianceProto.c2s = allianceProto.struct .. [[
    reqAnonymous 4101 { # 匿名设置
        request {
            bAnonymous 0: boolean
        }
        response {
        }
    }

    reqReceiveGiftAward 4102 { # 领取礼物奖励
        request {
            autoId 0: uint32
        }
        response {
            dropRes 1: *ComRes      # 获得的奖励
            
        }
    }

    reqReceivGiftAwardOneKey 4103 { # 一键领取礼物奖励
        request {
            group 0: uint32            # 一键领取某个标签页的礼物
        }
        response {
            newCliamdIdList 0: *integer # 领取奖励的自增id列表
            dropRes 1: *ComRes          # 获得的奖励
        }
    }

    reqReceiveBoxAward 4104 { # 领取宝箱奖励
        request {
            
        }
        response {
            dropRes 1: *ComRes          # 获得的奖励
        }
        
    }
    
]]

allianceProto.s2c = allianceProto.struct .. [[
    syncClearAllianceGiftForQuitAlliance 4105 {                     # 同步清除退出联盟的玩家的所有礼物数据
        request {

        }
    }
]]

return allianceProto