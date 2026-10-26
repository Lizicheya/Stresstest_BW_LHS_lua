--联盟科技 3501~3600
local allianceProto = {}

allianceProto.struct = [[

    .ComTechnologyRanking {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像id
        headFrameId 3: integer #头像框id
        customHead 4: string #自定义头像
        val 5: integer #捐献值
        honor 6: integer #荣誉值
        updateTime 7: integer #捐献值更新时间
    }

    .ComTechnologyLastRanking {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像id
        headFrameId 3: integer #头像框id
        customHead 4: string #自定义头像
        rank 5: integer #排名值
        reward 6: *ComRes #奖励
    }

    .ComNormalDonate {
        count 0: integer                                        # 当前可捐献次数
        lastRecoverTime 1: integer                              # 上次恢复时间 当次数达到上限后为0
    }

    .ComGemDonate {
        count 0: integer                                        # 宝石已捐献次数
        updateTime 1: integer                                   # 更新时间
    }

]]

allianceProto.c2s = allianceProto.struct .. [[
    donateAllianceTechnology 3501 {                              # 捐献联盟科技
        request {
            techId 0: uint32                                   # 科技id
            donateType 1: uint32                               # 捐献类型 AllianceTechnologyDonateType
        }
        response {
            multiple 0: integer                                 # 暴击倍数
            addExp 1: integer                                   # 本次加的经验
            preDonateMultiCircularList 2: integer               # 预捐献循环暴击倍数环形列表
            indexCircularList 3: integer                        # 当前环形列表索引
            countNormalDonate 4: integer                        # 当前可捐献次数
            countGemDonate 5: integer                           # 当前宝石已捐献次数
        }
    }

    recommendAllianceTechnology 3502 {                          # 推荐联盟科技
        request {
            techId 0: uint32
        }
        response {
    
        }
    }

    upgradeAllianceTechnology 3503 {                            # 研究或升级科技
        request {
            techId 0: uint32
        }
        response {

        }
    }

    cancelRecommendAllianceTechnology 3511 {                    # 取消推荐联盟科技
        request {
        }
        response {
    
        }
    }
]]

allianceProto.s2c = allianceProto.struct .. [[
    syncClearTechnologyForQuitAlliance 3506 {                   # 同步清除退出联盟的玩家的科技数据
        request {

        }
    }
]]

return allianceProto