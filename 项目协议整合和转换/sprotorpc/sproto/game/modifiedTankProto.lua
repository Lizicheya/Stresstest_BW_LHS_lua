-- 改装车 8151～8180
local modifiedTankProto = {}

modifiedTankProto.struct = [[
    .ComModifiedTankBase {
        tankLv 0: uint32            # 改装车等级
        upLvTimes 1: uint32         # 升级次数

        nextDayResetTime 2: uint32   # 上次每日重置时间
        dayFreeUpLvTimes 3: uint32   # 已经使用的每日免费
        dayFreeItemCount 4: uint32   # 已领取的每日免费道具数量

        activeSuitId 5: uint32       # 激活的套装ID
        skillIds 6: *uint32          # 已激活的技能ID列表
    }
  
    .ComModifiedTankPart {
        partType 0: uint32      # 部位类型
        tankPartLv 1: uint32    # 部位等级
    }
    
    .ComSyncModifiedTankPart {
        news 0: *ComModifiedTankPart(partType)
        changes 1: *ComModifiedTankPart(partType)
        removes 2: *integer
    }

    .ComModifiedTank4Troop {
        modifiedTankParts 0: *ComModifiedTankPart(partType)   # 改装车部位列表
        tankLv 1: uint32                # 改装车等级
        attrs 2: *ComIntInt()           # 提供的属性
        activeSkillLv 3: uint32         # 激活的技能等级
        activeSkillIds 4: *uint32       # 已激活的技能ID列表
    }
]]

modifiedTankProto.c2s = modifiedTankProto.struct .. [[
upLvModifiedTank 8151 { # 升级一次改装车
    request {
    }
    response {
    }
}

multiUpLvModifiedTank 8152 { # 升级多次改装车
    request {
        times 0: uint32      # 升级次数
    }
    response {
    }
}

upLvModifiedTankPart 8153 { # 升级改装车部位
    request {
        partType 0: uint32  # 部位类型
    }
    response {
    }
}

getModifiedDayFreeItem 8154 {  # 领取每日免费道具
    request {
    }
    response {
        ress 0: *ComRes        # 奖励列表
    }
}

upLvModifiedTankSuit 8155 { # 升级改装车套装
    request {
    }
    response {
    }
}

]]

modifiedTankProto.s2c = modifiedTankProto.struct .. [[
]]

return modifiedTankProto
