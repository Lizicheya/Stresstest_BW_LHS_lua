-- 友盟 7801 ～ 7850
local unitedAlliancesProto = {}

unitedAlliancesProto.struct = [[
    .ComSimpleInfoOfAlliance {
        fullName 0: string #联盟全称
        abbName 1: string #联盟简称
        flagId 4: integer #标志样式
        colorId 5: integer #标志颜色
        patternId 6: integer #标识图案
    }
    .ComUnitedAlliancesSimpleInfo {
        uaid 0: integer # 友盟id
        allianceInfo 1: *ComSimpleInfoOfAlliance #联盟简略信息
        power 2: integer # 友盟战力
    }
]]

unitedAlliancesProto.c2s = unitedAlliancesProto.struct..[[

#我的友盟
reqSelfUnitedAlliancesInfo 7801 {
    request {
    }
    response {
        allianceList 0: *ComSearchAllianceInfo #联盟信息
    }
}

#友盟列表
reqUnitedAlliancesList 7802 { 
    request {
        beginPos 0: uint32 # 起始点
        endPos 1: uint32 #结束点
    }
    response {
        info 0: *ComUnitedAlliancesSimpleInfo(uaid) #友盟信息
    }
}

#玩家查看友盟的申请列表
reqUnitedAlliancesApplyInfo 7803 { 
    request {
    }
    response {
        allianceList 0: *ComSearchAllianceInfo #联盟信息
    }
}

#友盟申请
applyJoinUnitedAlliances 7804 {
    request {
        uaid 0: uint32 # 友盟id
    }
    response {
    }
}

#邀请成为友盟
inviteJoinUnitedAlliances 7805 {
    request {
        aid 0: uint32 # 邀请对象的联盟id
    }
    response {
    }
}

#同意友盟申请
agreeApplication 7806 {
    request {
        aid 0: uint32 # 申请对象的联盟id
    }
    response {
    }
}

#退出友盟
quitUnitedAlliances 7807 {
    request {
    }
    response {
    }
}

]]

unitedAlliancesProto.s2c = unitedAlliancesProto.struct..[[

]]

return unitedAlliancesProto