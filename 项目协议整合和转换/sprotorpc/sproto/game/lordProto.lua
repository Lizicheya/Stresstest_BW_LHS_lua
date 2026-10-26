--领主信息 3001~3100
local lordProto = {}

lordProto.struct = [[
    .ComHeadData {
        headId 0: integer             # 头像ID
    }

    .ComHeadFrameData {
        headFrameId 0: integer        # 头像框ID
        endTime  1: integer           # 结束时间(0代表永远有效)
    }

    .ComHeadAndFrameData {
        headId 0: integer             # 头像
        customHead 1: string          # 自定义头像
        headFrameId 2: integer        # 头像框
    }

    .ComPhysicalStrength {
        count 0: integer                # 体力数量
        lastRecoverTime 1: integer      # 上次体力恢复结算时间
        freeCount 2: integer            # 免费次数
        nextFreeRefreshTime 3: integer  # 下次免费次数刷新时间
        isUnlock 4: boolean             # 免费领取功能是否解锁
        heroFreeCount 5: integer        # 英雄提供的免费次数
    }

    .ComLordStat {
        totalStat 0: *ComIntInt()                   # 统计总数量(LoadStatType-num)
        killNormalMonsterStat 1: *ComIntInt()       # 统计杀死的每个等级的普通怪(lv-num)
    }

    .ComQueryLordInfo {
        uid 0: integer          # uid
        nickName 1: string      # 玩家昵称
        castleLv 2: integer     # 城堡等级
        power 3: integer        # 当前战力
        kill 4: integer         # 杀敌数
        serverId 5: integer     # 服务器id
        headId 6: integer       # 头像id
        headFrameId 7: integer  # 头像框id
        customHead 8: string    # 自定义头像
        aid 9: integer          # 联盟id
        fullName 10: string     # 联盟全称
        abbName 11: string      # 联盟简称
        isGdpr 12: boolean      # 是否gdpr
        sex 13: integer         # 性别
        sign 14: string         # 个性签名
        likeNum 15: integer     # 点赞数量
        buildingPower 16: integer # 建筑战力
        heroPower 17: integer   # 英雄战力
        armyPower 18: integer   # 部队战力
        technologyPower 19: integer # 科技战力
        tankPower 20: integer   # 改装车战力
        enableLike 21: boolean  # 是否允许点赞 true允许
    }

    .ComLordLikeInfo {
        id 0: integer           # id
        likeType 1: integer     # 点赞类型
        time 2: integer         # 点赞时间戳
        uid 3: integer          # uid
        nickName 4: string      # 玩家昵称
        serverId 5: integer     # 服务器id
        headId 6: integer       # 头像id
        headFrameId 7: integer  # 头像框id
        customHead 8: string    # 自定义头像
        aid 9: integer          # 联盟id
        abbName 10: string      # 联盟简称
    }
]]

lordProto.c2s = lordProto.struct..[[

rename 3001 { #修改昵称
    request {
        name 0: string                   # name新的名字
        items2use 1: *ComUint32Uint32()        # 使用的道具(道具id->使用数量)
    }
    response {
    }
}

setHead 3002 { #设置头像
    request {
        headId 0: uint32                   # 头像ID
    }
    response {
    }
}

getFreePhysicalStrength 3004 { #            #领取免费体力
    request {
    }

    response {
    }
}

getOtherLordInfo 3005 { #                  #查询其他领主信息
    request {
        uid 0: uint32          # uid
        fields 1: *string       # 指定属性列表 不指定时返回所有
    }

    response {
        uid 0: integer          # uid
        nickName 1: string      # 玩家昵称
        castleLv 2: integer     # 城堡等级
        power 3: integer        # 当前战力
        kill 4: integer         # 杀敌数
        serverId 5: integer     # 服务器id
        headId 6: integer       # 头像id
        headFrameId 7: integer  # 头像框id
        customHead 8: string    # 自定义头像
        aid 9: integer          # 联盟id
        fullName 10: string     # 联盟全称
        abbName 11: string      # 联盟简称
        isInvited 12: boolean   # 联盟是否邀请过加入
        achievementBadgesShow 13: *integer       #成就徽章展示列表
        lordOutfit 14: ComLordOutfitData # 领主装备，不展示outfitList为空值
        bUnlockOutfit 15: boolean # 是否解锁领主装备
        bUnlockBadge 16: boolean # 是否解锁领主宝石
        officialId 17: integer    # 国王官职ID
        officialId2 18: integer   # 跨服战官职ID
        isGdpr 19: boolean       # 是否gdpr
        sex 20: integer          # 性别
        sign 21: string          # 个性签名
        likeNum 22: integer      # 点赞数量
        flagId 23: integer       # 联盟旗帜
        patternId 24: integer    # 联盟图案
        buildingPower 25: integer # 建筑战力
        heroPower 26: integer   # 英雄战力
        armyPower 27: integer   # 部队战力
        technologyPower 28: integer # 科技战力
        tankPower 29: integer   # 改装车战力
        colorId 30: uint32 #标志颜色
        enableLike 31: boolean  # 是否允许点赞 true允许
    }
}

reqActivationCode 3006 { # 激活码
    request {
        code 0: string
        channelId 1: string
    }

    response {
        rtncode 0: string   # 后台返回的错误码
        ress 1: *ComRes     # 获得的资源
    }
}

queryLordInfoFuzzy 3007 { #                  #查询其他领主信息
    request {
        name 0: string          # 名称
        fields 1: *string       # 指定属性列表 不指定时返回所有
        serverId 2: uint32     # 服务器id
    }
    response {
        infos 0 : *ComQueryLordInfo
    }
}

changeLanguage 3008 {
    request {
        language 0: string
    }
    response {
        
    }
}

setLordStyle 3009 {
    request {
        style 0: uint32
    }
    response {
        
    }
}

setSex 3010 {
    request {
        sex 0: uint32
    }
    response {

    }
}

setSign 3012 {
    request {
        sign 0: string # 个性签名
    }
    response {

    }
}

lodLike 3013 { # 点赞
    request {
        targetId 0: uint64 
        likeType 1: uint32 # 点赞类型 lodLike.id
    }
    response {

    }
}

getLikeList 3014 { # 获取点赞列表信息
    request {

    }
    response {
        list 1: *ComLordLikeInfo # 点赞列表
    }
}

queryNameExist 3015 { # 查询重名
    request {
        name 1: string
    }
    response {

    }
}

enableLike 3016 { # 设置点赞
    request {
        enable 1: boolean
    }
    response {
        
    }
}


getHeroFreePs 3017 {             #领取英雄提供的免费体力
    request {
    }

    response {
    }
}

getEvaluateReward 3018 {    #领取评价奖励
    request {

    }
    response {
        
    }
}

]]

lordProto.s2c = lordProto.struct..[[
    syncLordLvChangeReward 3011 { # 领主升级奖励表现
        request {
            level 2: integer
            addTalentPoint 0: integer
            ress 1: *ComRes
        }

        response {
        }
    }

]]

return lordProto