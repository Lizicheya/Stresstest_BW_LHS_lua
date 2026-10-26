-- 联盟操作日志 6981 ~ 6990
local allianceOperLogProto = {}

allianceOperLogProto.struct = [[
    .ComAllianceOperLogStruct1 {
        attacker 0: string
        defender 1: string
        win 2: integer
    }

    .ComAllianceOperLogStruct2 {
        operator 0: string
        buildCfgId 1: integer
    }

    .ComAllianceOperLogStruct3 {
        operator 0: string
        techId 1: integer
    }

    .ComAllianceOperLogStruct4 {
        techId 0: integer
        level 1: integer
    }

    .ComAllianceOperLogStruct5 {
        operator 0: string
        activityId 1: integer
    }

    .ComAllianceOperLogStruct6 {
        member 0: string
    }

    .ComAllianceOperLogStruct7 {
        kicker 0: string
        beKicker 1: string
    }

    .ComAllianceOperLogStruct8 {
        operator 0: string
        beOperator 1: string
        beforeRank 2: integer
        afterRank 3: integer
    }

    .ComAllianceOperLogStruct9 {
        operator 0: string
        beOperator 1: string
        beforePosition 2: integer
        afterPosition 3: integer
    }

    .ComAllianceOperLogStruct10 {
        oldLeader 0: string
        newLeader 1: string
    }

    .ComAllianceOperLogStruct11 {
        operator 0: string
        leader 1: string
    }

    .ComAllianceOperLogStruct12 {
        operator 0: string
        abbName 1: string
        buildCfgId 2: integer
    }

    .ComAllianceOperLogDetail {
        fightAttack 0: ComAllianceOperLogStruct1
        fightAttacked 1: ComAllianceOperLogStruct1
        buildBuild 2: ComAllianceOperLogStruct2
        removeBuild 3: ComAllianceOperLogStruct2
        techResearch 4: ComAllianceOperLogStruct3
        techRecommend 5: ComAllianceOperLogStruct3
        techLevelUp 6: ComAllianceOperLogStruct4
        activityBook 7: ComAllianceOperLogStruct5
        activityOpen 8: ComAllianceOperLogStruct5
        activityOver 9: ComAllianceOperLogStruct5
        memberIn 10: ComAllianceOperLogStruct6
        memberOut 11: ComAllianceOperLogStruct6
        memberKick 12: ComAllianceOperLogStruct7
        memberRankUp 13: ComAllianceOperLogStruct8
        memberRankDown 14: ComAllianceOperLogStruct8
        memberPositionUp 15: ComAllianceOperLogStruct9
        memberPositionDown 16: ComAllianceOperLogStruct9
        memberLeaderTransfer 17: ComAllianceOperLogStruct10
        memberImpeach 18: ComAllianceOperLogStruct11
        removeBuildByOther 19: ComAllianceOperLogStruct12
    }    
]]

allianceOperLogProto.c2s = allianceOperLogProto.struct .. [[

]]

allianceOperLogProto.s2c = allianceOperLogProto.struct .. [[

]]

return allianceOperLogProto