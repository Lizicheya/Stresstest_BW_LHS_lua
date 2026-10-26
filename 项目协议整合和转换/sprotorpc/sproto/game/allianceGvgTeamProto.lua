-- 联盟队伍 7851 ～ 7900
local alliancesGvgTeamProto = {}

alliancesGvgTeamProto.struct = [[
    .ComGvgTeamSimpleInfo {
        teamId 0: integer # 队伍id
        name 1: string # 队伍名字
        memberNum 2: integer # 队伍人数
        power 3: integer # 队伍战力
        score 4: integer # 积分
        isSignUp 5: boolean # 是否报名
        isUnlock 6: boolean # 是否解锁
        index 8: integer # 队伍索引
        applications 9: boolean # 是否有申请
    }

    .ComAllianceGvgTeamsSimpleInfo {
        aid 0: integer # 联盟 id
        allianceName 1: string # 联盟名字
        flagId 2: integer # 标志样式
        colorId 3: integer # 标志颜色
        patternId 4: integer # 标志图案
        teams 5: *ComGvgTeamSimpleInfo(teamId) # 队伍简略信息
    }

    .ComGvgTeamLog {
        isLeader 0: boolean # 是否是队长
        timestamp 1: integer # 时间戳
        abbName 2: string # 联盟简称
        playerName 3: string # 玩家名称
        headId 4: integer # 头像
        opType 5: integer # 操作类型
        param 6: *string # 参数列表
    }

    .ComGvgHistoryTeam {
        teamId 1: integer # 队伍id
        abbName 2: string # 联盟简称
        teamName 3: string # 队伍名字
        score 4: integer # 队伍积分
        fightMemberNum 5: integer # 出战成员数量
        flagId 6: uint32 #标志样式
        colorId 7: uint32 #标志颜色
        patternId 8: uint32 #标识图案
    }

    .ComGvgTeamHistory {
        isPlayoffs 0: boolean # 是否是季后赛
        timestamp 1: integer # 时间戳
        winner 2: integer # 获胜队伍id
        teamInfo 3: *ComGvgHistoryTeam(teamId) # 队伍信息
    }

    .ComGvgTeamMember {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        role 2: integer # 玩家队伍角色
        headId  3: integer #头像
        headFrameId 4: integer #头像框
        isOnline 5: boolean #是否在线
        lastLoginTime 6: integer #上次登陆时间
        power 7: integer #战力
    }

    .ComAppointMember {
        uid 0: integer #玩家id
        # nickName 1: string #玩家昵称
        teamId 2: integer # 玩家所在队伍id
        teamName 3: integer # 玩家所在队伍名字
        role 4: integer # 玩家队伍角色
        # headId 5: integer #头像
        # headFrameId 6: integer #头像框
        # power 7: integer #战力
        # rank 8: integer #成员等级 MemberRankType
        # joinTime 9: integer #加入时间
        # castleLv 10: integer # 城堡等级
    }

    .ComApplyMember {
        uid 0: integer #玩家id
        nickName 1: string #玩家昵称
        headId 2: integer #头像
        headFrameId 3: integer #头像框
        power 4: integer #战力
    }

    .ComGvgTeamAppoint {
        uid 0: integer # 玩家id
        role 1: integer # 队伍角色 AllianceGvgTeamRoleEnum
    }

    .ComGvgTeamRecord {
        gameType 0: integer # 比赛类型
        win 1: integer # 胜场次
        lose 2: integer # 负场次
    }

    .ComGvgTeamEnemy {
        aid 0: integer # 联盟 id
        allianceName 1: string # 联盟名字
        allianceAbbName 2: string # 联盟简称
        flagId  3: integer # 标志样式
        colorId 4: integer # 标志颜色
        patternId 5: integer # 标志图案
        teamId 6: integer # 队伍id
        name 7: string # 队伍名字
        serverId 8: integer # 所属王国
        power 9: integer # 队伍战力
        record 10: *ComGvgTeamRecord(gameType) # 队伍记录
    }

    .ComGvgTeamMatchInfo {
        teamId 0: integer # 队伍id
        name 1: string # 队伍名字
        isSignUp 2: boolean # 是否报名
        isUnlock 3: boolean # 是否解锁
        index 4: integer # 队伍索引
        enemy 5: *ComGvgTeamEnemy # 对手信息
    }

    .ComAllianceGvgTeamMatchInfo {
        aid 0: integer # 联盟 id
        allianceName 1: string # 联盟名字
        flagId 2: integer # 标志样式
        colorId 3: integer # 标志颜色
        patternId 4: integer # 标志图案
        teams 5: *ComGvgTeamMatchInfo(teamId) # 队伍简略信息
    }
]]

alliancesGvgTeamProto.c2s = alliancesGvgTeamProto.struct..[[

# 我方所有队伍
reqAllAlliancesGvgTeamInfo 7851 {
    request {
    }
    response {
        info 0: *ComAllianceGvgTeamsSimpleInfo(aid) #联盟信息
    }
}

# 请求队伍详细信息
reqAllianceGvgTeamDetailInfo 7852 {
    request {
        teamId 0: uint32 # 队伍id
    }
    response {
        members 0: *ComGvgTeamMember(uid) # 队伍成员信息
        teamName 1: string # 队伍名字
        score 2: integer # 队伍积分
    }
}

# 变更队伍名字
reqChangeGvgTeamName 7853 {
    request {
        teamId 0: uint32 # 队伍id
        name 1: string #名字
    }
    response {
    }
}

# 请求委任界面信息
reqAppointMemberInfo 7854 {
    request {
    }
    response {
        allianceMember 0: *ComAppointMember(uid)
    }
}

# 委任队员
appointGvgTeamMember 7855 {
    request {
        teamId 0: uint32 # 队伍id
        appoint 1: *ComGvgTeamAppoint(uid) # 委任操作
    }
    response {
    }
}

# 请求申请界面
reqGvgTeamApplyInfo 7856 {
    request {
        teamId 0: uint32 # 队伍id
    }
    response {
        apply 0: *ComApplyMember(uid) # 申请玩家信息
    }
}

# 申请加入Gvg队伍
reqApplyJoinTeam 7857 {
    request {
        teamId 0: uint32 # 申请加入的队伍id
    }
    response {
    
    }
}

# 同意申请
acceptGvgTeamApply 7858 {
    request {
        teamId 0: uint32 # 队伍id
        appoint 1: *ComGvgTeamAppoint(uid) # 同意申请操作
    }
    response {
    
    }
}

# 移出队伍
reqKickTeam 7859 {
    request {
        teamId 0: uint32 # 队伍id
        uid 1: uint64 # 玩家id
    }
    response {

    }
}

# 改变队伍内玩家队伍角色
reqChangeTeamMemberRole 7860 {
    request {
        teamId 0: uint32 # 队伍id
        uid 1: uint64 # 玩家id
        role 2: uint32 # 队伍角色
    }
    response {
    }
}

# 更换队伍
reqResetTeamMemberTeam 7861 {
    request {
        fromTeamId 0: uint32 # 原队伍id
        uid 1: uint64 # 玩家id
        toTeamId 2: uint32 # 目标队伍id
        role 3: uint32 # 目标队伍角色
    }
    response {
    
    }
}

# 同队伍成员主力替补互换
reqSwitchTeamMemberRole 7862 {
    request {
        teamId 0: uint32 # 队伍id
        luid 1: uint64 # 玩家id_1
        ruid 2: uint64 # 玩家id_2
    }
    response {
    
    }
}

# 请求队伍操作日志
reqGvgTeamOperateLog 7863 {
    request {
        teamId 0: uint32 # 队伍id
    }
    response {
        logs 0: *ComGvgTeamLog # 操作日志
    }
}

# 请求队伍战绩历史
reqGvgTeamHistory 7864 {
    request {
        teamId 0: uint32 # 队伍id
    }
    response {
        history 0: *ComGvgTeamHistory # 队伍战绩
    }
}

# 查看队伍报名状态
reqGvgTeamSignUp 7865 {
    request {
        teamId 0: uint32 # 队伍id
    }
    response {
        state 0: integer # 报名状态
        timeIdList 1: *integer # 报名时段
    }
}

# 查看我的队伍匹配完成阶段联盟队伍信息
reqAlliancesGvgTeamMatchInfo 7866 {
    request {
    }
    response {
        info 0: ComAllianceGvgTeamMatchInfo #联盟信息
    }
}

]]

alliancesGvgTeamProto.s2c = alliancesGvgTeamProto.struct..[[

]]

return alliancesGvgTeamProto