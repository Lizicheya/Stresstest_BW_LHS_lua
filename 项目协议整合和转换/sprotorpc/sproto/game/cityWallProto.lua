 -- 城墙 3701 ~ 3800
local cityWallProto = {}

cityWallProto.struct = [[
    .ComCityWallGarrisonHero {
        key 1: uint32         # 驻防队伍编号
        value 2: *uint32      # 驻防英雄IDS
    }
    
    .ComCityWall {   
        garrisonHeros 0: *ComCityWallGarrisonHero()   #驻防英雄
        lostDurabilityValue 1: integer  #已经丢失的耐久度  
        burnBeginTime 2: integer  #燃烧开始时间
        burnEndTime 3: integer #燃烧结束时间
        burnSpeed 4: integer #燃烧速度
        robustnessValue 5: integer #坚固值
        repairIntervalTime 6: integer #维修间隔时间
        autoRepaireTime 7: integer # 自动修复开始时间
        autoRepaireSpeed 8: integer # 自动修复速度(n/min)
    }

    .ComTide { #潮汐数据
        id 0:integer  #潮汐ID
        state 1: integer #潮汐状态
        durations 2:*integer #潮汐状态间隔
        beginTime 3:integer #潮汐的开始时间
        lostRobustnessValue 5:integer #丢失的坚固值
        success 6:boolean #是否成功
        lastLostTime 7:integer #最近的丢失开始时间
        lastRecoverTime 8:integer #最近的恢复开始时间
        nextRepairTime 9:integer #下次维修时间 
        tideRuins          10: *ComIntInt()                # 潮汐废墟数据
        tideSuccess        11: *ComIntInt()                # 潮汐废墟数据
    }
]]

cityWallProto.c2s = cityWallProto.struct..[[

setGarrisonHeros 3701 { #设置驻防英雄
    request {
        garrisonHeros 0: *ComCityWallGarrisonHero()   #驻防英雄
    }
    response {   
    }
}

getCityWallData 3702 { #获取城墙数据
    request {
       
    }
    response {
        garrisonHeros 0: *ComCityWallGarrisonHero()   #驻防英雄
        lostDurabilityValue 1: integer  #已经丢失的耐久度  
        burnBeginTime 2: integer  #燃烧开始时间
        burnEndTime 3: integer #燃烧结束时间
        burnSpeed 4: integer #燃烧速度
        robustnessValue 5: integer #坚固值
        repairIntervalTime 6: integer #维修间隔时间
        autoRepaireTime 7: integer # 自动修复开始时间
        autoRepaireSpeed 8: integer # 自动修复速度(n/min)
    }
}

cityWallPutOutFire 3703 { #城墙灭火
    request {
       
    }
    response {
        lostDurabilityValue 1: integer  #已经丢失的耐久度  
        autoRepaireTime 2: integer # 自动修复开始时间
        autoRepaireSpeed 3: integer # 自动修复速度(n/min)
    }
}

cityWallRepair 3704 { #城墙维修
    request {
       
    }
    response {
        lostDurabilityValue 1: integer  #已经丢失的耐久度  
        repairIntervalTime 2: integer #维修间隔时间
        autoRepaireTime 3: integer # 自动修复开始时间
        autoRepaireSpeed 4: integer # 自动修复速度(n/min)
    }
}

cityDefendUpgradeBuild 3705 { # 内城防守战: 升级建筑
    request {
        id 0:uint32
        subType 1:uint32
    }
    response {
    }
}

repairRobustnessValue 3706 {  #修复坚固值   
    request {
    }

    response {
    }
}

tideClearSuccessMonsters 3707 {  #清理成功怪物   
    request {
        id 0:uint32  #怪物ID
    }

    response {
        ress 0: *ComRes
    }
}

]]

cityWallProto.s2c = cityWallProto.struct..[[

]]

return cityWallProto