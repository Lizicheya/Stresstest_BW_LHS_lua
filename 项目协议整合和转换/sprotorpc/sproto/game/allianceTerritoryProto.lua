-- 联盟领地 8231 ~ 8300
local allianceTerritoryProto = {}

allianceTerritoryProto.struct = [[

    

    .ComAllianceTerritoryDeclareWarInfo { # 领地宣战信息
        strongholdId 1: integer # 据点id
        declareTime 2: integer # 宣战时间
        fullName 3: string # 归属联盟名称
        abbName 4: string # 归属联盟简称
        strongholdName 5: string # 据点名称 默认无，查配置表
    }
    
    .ComAllianceTerritoryOperLog { #争夺记录
        id 0: integer
        operType 1: integer # 枚举文件AllianceTerrioryOperType
        operTime 2: integer
        strongholdId 3: integer # 据点id
        nickName 4: string # 放弃据点操作者的昵称
        strongholdName 5: string # 据点名称 默认无，查配置表
    }

    .ComTerritoryRankPlayer {
        uid 0: integer                                 # 玩家id
        nickName 1: string                             # 玩家昵称
        headId 2: integer                              # 头像
        headFrameId 3: integer                         # 头像框
        customHead 4: string                           # 自定义头像
        rank 5: integer                                # 排名
        score 6: integer                               # 总战功
        killScore 7: integer                           # 击杀怪物战功
        destroyScore 8: integer                        # 破坏耐久度战功   
    }

    .ComTerritoryRankAlliance {
        aid 0: integer                                  #联盟id
        fullName 1: string                              #联盟全称
        abbName 2: string                               #联盟简称
        serverId 3: integer                             #服务器id
        flagId 4: integer                               #旗帜id
        patternId 5: integer                            #图案id
        colorId 6: integer                              #颜色id
        rank 7: integer                                 #排名
        score 8: integer                                #排行值
    }
]]

allianceTerritoryProto.c2s = allianceTerritoryProto.struct .. [[
    allianceTerritoryDeclareWarReservation 8231 { # 预约宣战
        request {
            strongholdId 1: uint32 # 据点id
            declareTime 2: uint32 # 宣战时间
            text 3: string
        }
        response {

        }
    }

    allianceTerritoryCancelDeclareWarReservation 8232 { # 取消预约宣战
        request {
            strongholdId 1: uint32 # 据点id
        }
        response {

        }
    }

    allianceTerritoryDeclareWarImmediately 8233 { # 直接宣战
        request {
            strongholdId 1: uint32 # 据点id
            text 2: string
        }
        response {

        }
    }

    allianceTerritoryGiveUp 8234 { # 放弃据点
        request {
            strongholdId 1: uint32 # 据点id
        }
        response {

        }
    }

    allianceTerritoryCancelGiveUp 8235 { # 取消放弃据点
        request {
            strongholdId 1: uint32 # 据点id
        }
        response {

        }
    }

    allianceTerritoryRename 8236 { # 据点改名
        request {
            strongholdId 1: uint32 # 据点id
            strongholdName 2: string # 据点名称
        }
        response {

        }
    }

    allianceTerritoryReqRanking 8237 { # 最近一次战功排名
        request {
        }
        response {
            selfRank 0: integer                             # 自己的排名
            rankList 1: *ComTerritoryRankPlayer
            selfScore 2: integer                            # 自己的排行值
            declareTime 3: integer                          # 宣战时间
            strongholdId 4: integer                         # 宣战据点id
            strongholdName 5: string                       # 据点名称
            killScore 6: integer
            destroyScore 7: integer
        }
    }

    allianceTerritoryReqStrongholdList 8238 { # 获取领地列表
        request {

        }
        response {
            
        }
    }

    allianceTerritoryReqAllianceContributeRanking 8239 { # 获取据点内联盟战功排名
        request {
            strongholdId 1: uint32
        }
        response {
            rankList 1: *ComTerritoryRankAlliance
            
        }
    }

    allianceTerritoryReqMemberContributeRanking 8240 { # 获取据点内联盟成员战功排名
        request {
            strongholdId 1: uint32
        }
        response {
            rankList 1: *ComTerritoryRankPlayer
            selfRank 2: integer                             # 自己的排名
            selfScore 3: integer                            # 自己的总战功
            killScore 4: integer                            # 击杀怪物战功
            destroyScore 5: integer                         # 破坏耐久度战功  
        }
    }
]]

allianceTerritoryProto.s2c = allianceTerritoryProto.struct .. [[

]]

return allianceTerritoryProto