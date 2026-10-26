-- 联盟祭坛 6751 ~ 6800
local allianceAltarProto = {}

allianceAltarProto.struct = [[
    .ComDamageRankPlayer {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        rank 5: integer                                 #排名
        score 6: double                                 #排行值
        abbName 7: string                               #联盟简称
    }

    .ComAltarMonsterRecord {
        id 0: integer                                   #伤害记录id
        uid 1: integer                                  #玩家id
        nickName 2: string                              #玩家昵称
        headId 3: integer                               #头像
        headFrameId 4: integer                          #头像框
        customHead 5: string                            #自定义头像
        damage 6: double                                #个人伤害
        totalDamage 7: double                           #队伍伤害
    }
]]

allianceAltarProto.c2s = allianceAltarProto.struct .. [[
    blessAltar 6751 {  #祈福
        request {
            mapId 0: uint32   #地图id
            id 1: uint32      #建筑id
            num 2: uint32     #使用祈福道具的数量
        }
        response {

        }
    }

    summonReservation 6752 { #预约召唤
        request {
            mapId 0: uint32   #地图id
            id 1: uint32      #建筑id
            summonTime 2: uint32 #预约召唤时间戳
        }
        response {

        }
    }

    summonImmediately 6753 { #手动开启召唤
        request {
            mapId 0: uint32   #地图id
            id 1: uint32      #建筑id
        }
        response {

        }
    }

    reqAltarMonsterDamageRankInfo 6754 { #获取联盟祭坛神兽伤害排行榜
        request {
            mapId 0: uint32   #地图id
            id 1: uint32      #建筑id
        }
        response {
            playerList 0: *ComDamageRankPlayer
            selfRank 1: integer  # 自己的排名
            selfScore 2: double # 自己的排行值
            totalDamage 3: double # 联盟总伤害
        }
    }

    reqAltarMonsterTotalDamage 6755 {
        request {
            mapId 1: uint32   #地图id
            id 2: uint32      #建筑id
        }
        response {
            totalDamage 1: double # 联盟总伤害
        }
    }

    reqAltarMonsterDamageRecord 6756 { # 获取个人伤害记录
        request {
            mapId 1: uint32   #地图id
            id 2: uint32      #建筑id
        }
        response {
            recordList 1: *ComAltarMonsterRecord(id) # 伤害记录
            totalDamage 2: double # 个人总伤害
        }
    }

    reqAltarMonsterDamageReport 6757 { # 战斗报告
        request {
            mapId 1: uint32     #地图id
            id 2: uint32        #建筑id
            recordId 3: uint32  #伤害记录id
        }
        response {
            playerList 0: *ComDamageRankPlayer
        }
    }

    reqAutoJoinRallyAltarMonster 6758 { #离线参与
        request {
            isJoin 0: boolean  #是否参与
            beginTime 1: uint32 #自动加入集结开始时间戳
            endTime 2: uint32 #自动加入集结结束时间戳
        }
        response {
            isJoin 0: boolean  #是否参与
        }
    }

]]

allianceAltarProto.s2c = allianceAltarProto.struct .. [[

]]

return allianceAltarProto