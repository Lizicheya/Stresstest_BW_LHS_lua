-- 排行榜 4001 ~ 4100
local rankProto = {}

rankProto.struct = [[
    .ComRankPlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        rank 5: integer                                 #排名
        score 6: integer                                #排行值
        abbName 7: string                               #联盟简称
        serverId 8: integer                             #服务器id
        gloryLv 9: integer                              #赛季荣耀等级
    }

    .ComRankAlliance {
        id 0: integer                                   #联盟id
        fullName 1: string                              #联盟全称
        abbName 2: string                               #联盟简称
        serverId 3: integer                             #服务器id
        flagId 4: integer                               #旗帜id
        patternId 5: integer                            #图案id
        colorId 6: integer                              #颜色id
        rank 7: integer                                 #排名
        value 8: integer                                #排行值
    }

    .ComRankKingdom {
        id 0: integer                                   #服务器id
        rank 1: integer                                 #排名
        value 2: integer                                #排行值
    }

    .ComRankList {
        playerList 0: *ComRankPlayer
        allianceList 1: *ComRankAlliance
        kingdomList 2: *ComRankKingdom
    }

    .ComRankNScore {
        rankCfgId 0: integer
        rank 1: integer
        score 2: integer
    }

    .ComRankParams {                                # 排行榜额外参数
        actId 0: uint32                            # 活动id 
    }

    .ComRankCfgIdNParams {
        rankCfgId 0: uint32
        params 1: ComRankParams
    }
]]

rankProto.c2s = rankProto.struct..[[

queryRank 4001 {                                        # 查询排行榜
    request {
        rankCfgId 0: uint32                            # 排行榜配置id
        startPos 1: uint32                             # 开始位置 (从1开始)
        endPos 2: uint32                               # 结束位置 (从1开始)
        params 3: ComRankParams                         # 排行榜额外参数
        minScore 4: uint32                             # 最小积分值(返回>=minScore的)
    }
    response {
        selfRank 0: integer                             # 自己的排名
        rank 1: ComRankList                             # 排行榜信息
        selfScore 2: integer                            # 自己的排行值
    }
}

querySelfRank 4002 {                                    # 自己在某榜中的排行与分数
    request {
        rankCfgId 0: uint32                            # 排行榜配置id
        params 1: ComRankParams                         # 排行榜额外参数
    }
    response {
        selfRank 0: integer                             # 自己的排名
        selfScore 1: integer                            # 自己的排行值
    }
}

querySelfRankBatch 4003 {                               # 批量查询各个榜单中自己排名
    request {
        rankCfgIdList 0: *ComRankCfgIdNParams                            # 排行榜配置id
    }
    response {
        rankNScore 0: *ComRankNScore
    }
}

]]

rankProto.s2c = rankProto.struct..[[

]]

return rankProto