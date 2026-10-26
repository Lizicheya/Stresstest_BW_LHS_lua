-- 城墙 4901 ~ 5000
local campongWarProto = {}

campongWarProto.struct = [[
    #聚落战争聚落信息
    .ComCampongWarBuildInfoEx {
        id 0: integer                   # 聚落ID
        status  1: integer              # 状态 MapBuildStatusType
        endTime  2: integer             # 当前状态结束时间
        round 3: integer                # 最终开启时间段
        rounds 4: *integer              # 报名开始时间的索引
        autoRegist 5: boolean           # 是否自动报名
        aid 6: integer                  # 占领/归属联盟ID
        aliInfo 7: ComAllianceBrief     # 占领/归属联盟信息 可nil
        npcId 8: integer                # npc ID
        time 9: integer                 # 占领结束时间
        objId 10: integer               # 对象ID
    }

    .ComCampongWarBuildDivide {
        id 0: integer                   # 聚落ID
        killDivideId 1: integer        # id(分配ID)
        occupyDivideId 2: integer      # id(分配ID)
    }

    #聚落战争活动信息
    .ComCampongWarActivityInfo {
        seasonId 0: integer      # 第几赛季
        round 1: integer         # 第几轮
        startTime 3: integer     # 开始时间
        status 4: integer        # 活动状态 campongWarStatus
        durations 5: *integer    # 状态时间
        groupId 6: integer       # 赛季奖励组id
        buildDivides 7 : *ComCampongWarBuildDivide(id) #建筑随机分配id
    }

    #聚落战争分配奖励信息
    .ComCampongWarDivideRewardInfo {
        divideId 0: integer      # id(分配ID)
        divideNum 1: integer     # 已经分配了数量
        players 2: *integer      # 已经领取了玩家ID
    }

    #聚落战争联盟积分信息
    .ComCampongWarAllianceInfo {
        id 0: integer                                   #联盟id
        fullName 1: string                              #联盟全称
        abbName 2: string                               #联盟简称
        flagId 4: integer                               #旗帜id
        patternId 5: integer                            #图案id
        colorId 6: integer                              #颜色id
        leaderId 7: integer                             #盟主ID
        leaderName 8: string                            #盟主名字
        point  9: integer                               #积分
    }

    #聚落战争历史数据
    .ComCampongWarOccupyHistoryData {
        idx 0: integer                                  #第几任
        aid 1: integer                                  #联盟id
        fullName 2: string                              #联盟全称
        abbName 3: string                               #联盟简称
        flagId 4: integer                               #旗帜id
        patternId 5: integer                            #图案id
        colorId 6: integer                              #颜色id
        leaderId 7: integer                             #盟主ID
        leaderName 8: string                            #盟主名字
        headId 9: integer                               #头像id
        headFrameId 10: integer                         #头像框id
        createTime 11: integer                          #创建时间
    }

    #聚落战争数据
    .ComCampongWarData {
        actInfo 0: ComCampongWarActivityInfo
        divideList 1: *ComCampongWarDivideRewardInfo(divideId)     #无players
    }

    .ComCampongWarPlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        power 5: integer                                #战力
    }

    .ComCampongWarRegistInfo {
        campongId 0: integer
        rounds 1: *integer        # 报名开始时间的索引
        autoRegist 2: boolean     # 是否自动报名
    }
 ]]

campongWarProto.c2s = campongWarProto.struct .. [[

    campongWarRegist 4901 { #聚落战争报名
        request {
            campongId 0: uint32
            rounds 1: *uint32 #开始时间的索引
        }
        response {
            campongId 0: integer
            voteStats 1: *integer #投票统计数量
            voteInfo 2: *integer  #自己投了哪几个
            registInfos 3: *ComCampongWarRegistInfo(campongId)        # 本联盟的所有报名信息（有值时覆盖ComCampongWarBuildInfoEx里面的rounds）
        }
    }

    campongWarVote 4902 { #聚落战争投票
        request {
            campongId 0: uint32
            rounds 1: *uint32 #开始时间的索引
        }
        response {
            campongId 0: integer
            voteStats 1: *integer #投票统计数量
            voteInfo 2: *integer  #自己投了哪几个
            registInfos 3: *ComCampongWarRegistInfo(campongId)        # 本联盟的所有报名信息（有值时覆盖ComCampongWarBuildInfoEx里面的rounds）
        }
    }

    campongWarList 4903 { #获取聚落战争列表
        response {
            list 0: *ComCampongWarBuildInfoEx(id)
            divideList 1: *ComCampongWarDivideRewardInfo(divideId)     #无players
            score 2: integer
        }
    }

    getCampongWarVoteInfo 4904 { #获取聚落战争投票信息
        request {
            campongId 0: uint32
        }
        response {
            campongId 0: integer
            voteStats 1: *integer #投票统计数量
            voteInfo 2: *integer  #自己投了哪几个
            registInfos 3: *ComCampongWarRegistInfo(campongId)        # 本联盟的所有报名信息（有值时覆盖ComCampongWarBuildInfoEx里面的rounds）
        }
    }

    getCampongWarDivideRewardList 4905 { #获取聚落战争分配奖励列表
        request {
            campongId 0: uint32
            divideId 1: uint32  #传>0返回单个分配信息,传0返回所有分配信息
        }
        response {
            campongId 0: integer
            divideId 1: integer
            infos 2: *ComCampongWarDivideRewardInfo(divideId)          #有players
        }
    }

    getCampongWarDivideRewardInfo 4906 { #---废弃,待删除
        request {
            divideId 0: uint32
        }
        response {
            info 0: ComCampongWarDivideRewardInfo                       #有players
        }
    }

    divideCampongWarDivideReward 4907 { #分配聚落战争分配奖励
        request {
            campongId 0: uint32
            divideId 1: uint32
            playerIds 2: *uint32
        }
        response {
            campongId 0: integer
            divideId 1: integer
            info 2: ComCampongWarDivideRewardInfo                       #有players
        }
    }

    getCampongWarAlliancePointList 4908 { #获取聚落战争联盟积分列表
        request {
        }
        response {
            list 0: *ComCampongWarAllianceInfo(id)
        }
    }

    getCampongWarOccupyHistoryList 4909 { #获取聚落战争占领历史列表
        request {
            campongId 0: uint32
        }
        response {
            campongId 0: integer
            list 1: *ComCampongWarOccupyHistoryData
        }
    }

    getCampongWarVoteMembers 4910 { #聚落战争投票成员信息
        request {
            campongId 0: uint32
            round 1: uint32
        }
        response {
            campongId 0: integer
            round 1: integer
            list 2: *ComCampongWarPlayer
        }
    }
 ]]

campongWarProto.s2c = campongWarProto.struct .. [[
    showCampongWarWin 4951 { #聚落战胜利弹窗
        request {
            campongId 0: integer
            aid 1: integer  #联盟id
            abbName 2: string   #联盟简称
            fullName 3: string   #联盟名称
            npcId 4: integer     # npc ID
            dropId 5: integer     # 掉落 ID
        }
    }
 ]]

return campongWarProto
