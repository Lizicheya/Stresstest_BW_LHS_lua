-- 领主天赋卡牌 7251 ~ 7270
local lordTalentProto = {}

lordTalentProto.struct = [[
    .ComLordTalentList {
        talentId 0: integer
        level 1: integer
    }

    .ComLordTalentPage {
        page 0: integer
        list 1: *ComLordTalentList(talentId)
        cardCellList 2: *ComIntInt()            # 卡牌槽位情况
        usingPoints 3: integer                  # 总的点数
        typeUsingPoint 4: *ComIntInt()          # 对应类型使用的天赋点
    }

    .ComLordTalent {
        usingPoints 0: integer                  # 当前使用的点数
        usingPage 1: integer                    # 当前天赋页
        talentPage 2: *ComLordTalentPage(page)  # 天赋列表
        talentSkillCD 3: *ComIntInt()           # 天赋cd(天赋CD页面通用)
        talentCardCellCD 4: *ComIntInt()        # 天赋卡牌槽位cd(槽位CD页面通用)
        totalPoints 5: integer                  # 总的点数
    }

    .ComSyncTalentList {
        new 0: ComLordTalentList
        change 1: ComLordTalentList
    }

    .ComSyncTalentPage {
        page 0: integer
        talentList 1: ComSyncTalentList
        usingPoints 2: integer                  # 总的点数
        typeUsingPoint 3: *ComIntInt()          # 对应类型使用的天赋点
    }

    .ComSynctalentSkillCD {
        new 0: *ComIntInt()
        change 1: *ComIntInt()
    }


    .ComSyncCardCellList {
        new 0: *ComIntInt()
        change 1: *ComIntInt()
        remove 2: integer
    }

    .ComSyncCardCellPage {
        page 0: integer
        cardCellList 1: ComSyncCardCellList
    }
]]

lordTalentProto.c2s = lordTalentProto.struct..[[

reqUpgradeLordTalent 7251 { # 升级领主天赋
    request {
        talentId 0: uint32 
        bOneKey 1: boolean
    }
    response {
    }
}

reqSwitchTalentPage 7252 { # 切换天赋页
    request {
        page 0: uint32 
    }
    response {
    }
}

reqResetTalentPage 7253 { # 重置当前天赋页
    request {
    }
    response {
    }
}

reqCastTalentSkill 7254 { # 施放天赋技能
    request {
        talentId 0: uint32 
    }
    response {
    }
}

reqUpTalentCard 7255 { # 上阵卡牌
    request {
        cellId 0: uint32
        cardId 1: uint32
    }
    response {
    }
}

reqDownTalentCard 7256 { # 下阵卡牌
    request {
        cellId 0: uint32
    }
    response {
    }
}

reqUpgradeTalentCard 7257 { # 卡牌升级
    request {
        cardId 0: uint32
        useItem 1: *ComCostItem
        useCard 2: *uint32
    }
    response {
        returnRes 0: *ComRes
    }
}

reqCastTalentCardSkill 7258 { # 施放槽位卡牌技能
    request {
        cellId 0: uint32 
    }
    response {
    }
}

]]

lordTalentProto.s2c = lordTalentProto.struct..[[

syncLordTalentInfo 7261 { # 同步
    request {
        talentPage 0: ComSyncTalentPage 
        changePage 1: integer
        resetPage 2: integer
        talentSkillCD 3: ComSynctalentSkillCD
        cardCellPage 4: ComSyncCardCellPage
        talentCardCellCD 5: ComSynctalentSkillCD
        totalPoints 6: integer                  # 总的点数
    }
    response {
    }
}

]]

return lordTalentProto