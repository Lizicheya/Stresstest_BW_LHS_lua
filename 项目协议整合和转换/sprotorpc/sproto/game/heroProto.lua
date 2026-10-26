-- 英雄模块 601~700
local heroProto = {}

heroProto.struct = [[
    .ComHeroBackgroundData {
        heroId 0: integer #英雄ID
        ids 1: *integer   #领取的奖励列表
    }

    .ComHeroLevelResonanceData {
        id 0: integer #唯一ID
        heroId 1: integer #英雄ID
        cdTime 2: integer #cd时间
    }
]]

heroProto.c2s = heroProto.struct..[[

upgradeHeroSkill 601 { #英雄技能升级
    request {
        heroCfgId 0: uint32                    # 配置表id
        slotId 1: uint32                       # 技能槽
    }
    response {
    }
}

upgradeHeroStarLv 602 { #英雄升星
    request {
        heroCfgId 0: uint32                    # 配置表id
        resExchanges 2: *ComUint32Uint32()      # 资源兑换(资源兑换配置id->兑换数量)
    }
    response {
        power 0: uint32                        # 新的战力
    }
}

getHeroBackgroundReward 603 { #获取英雄背景奖励
    request {
        heroCfgId 0: uint32                    # 配置表id
        id      1: uint32                      # 背景ID
    }
    response {
        ress 0: *ComRes                         # 获得的资源
    }
}

resetHeroLv 604 { #重置英雄等级
    request {
        heroCfgId 0: uint32                    # 英雄ID
    }
    response {
        ress 0: *ComRes                         # 获得的资源
    }
}

beginHeroLevelResonance 605 { #开始英雄等级共鸣
    request {
        heroCfgId 0: uint32                    # 英雄ID
        id 1: uint32                           # 配置表id 
    }
    response {
    }
}

endHeroLevelResonance 606 { #结束英雄等级共鸣
    request {
        id 1: uint32                           # 配置表id 
    }
    response {
    }
}

resetHeroLevelResonanceCd 607 { #重置英雄等级共鸣CD时间
    request {
        id 1: uint32                           # 配置表id 
    }
    response {
    }
}

getHeroRelationshipReward 608 { #获取英雄羁绊奖励
    request {
        heroCfgId 1: uint32                    # 英雄配置ID
    }
    response {
        ress 0: *ComRes                         # 获得的资源
    }
}

upgradeHeroLv 609 { #英雄升级
    request {
        heroCfgId 0: uint32                    # 配置表id
    }
    response {
        power 0: uint32                        # 新的战力
    }
}

resetHeroSkill 610 { #重置英雄技能
    request {
        heroCfgId 0: uint32
        slotId 1: uint32
    }
    response {
        ress 0: *ComRes                         # 返还的资源
    }
}

unlockHeroLevelResonance 611 { # 解锁共鸣槽位
    request {
        id 0: uint32                    # 配置表id
    }
    response {
    }
}

clearHeroResetLvCd 612 { # 清除英雄重置等级CD
    request {
        heroCfgId 0: uint32                    # 英雄ID
    }
    response {
    }
}

upgradeHeroHonorLv 613 { # 英雄升级荣誉等级
    request {
        heroCfgId 0: uint32                    # 配置表id
        resExchanges 2: *ComUint32Uint32()     # 资源兑换(资源兑换配置id->兑换数量)
    }
    response {
        power 0: uint32                        # 新的战力
    }
}

upgradeExclusiveEquipLv 614 { # 英雄升级专属装备等级
    request {
        heroCfgId 0: uint32                    # 配置表id
        resExchanges 2: *ComUint32Uint32()     # 资源兑换(资源兑换配置id->兑换数量)
    }
    response {
        power 0: uint32                        # 新的战力
    }
}

]]

heroProto.s2c = heroProto.struct..[[

]]

return heroProto