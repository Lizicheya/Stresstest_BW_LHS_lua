-- 赛季战场 7751 ～ 7800
local seasonGvgWarProto = {}

seasonGvgWarProto.struct = [[
    .RegularGvgWarParam {
        seasonId 1: integer
    }

    .SeasonGvgWarVoteInfo {
        uid 1: integer
        headId 2: integer
        headFrameId 3: integer
        customHead 4: string #自定义头像
        nickName 5: string #昵称
        power 6: integer #战力
    }

    .ComRegularGvgWarActInfo {
        actId 1: integer # 活动id
        param 2: RegularGvgWarParam # 活动参数
        isOver 3: boolean # 活动是否结束
        warRound 4: integer # 第几轮
        stage 5: integer # 阶段
        stageOverTs 6: integer # 当前阶段结束时间戳

    }
]]

seasonGvgWarProto.c2s = seasonGvgWarProto.struct .. [[
    seasonGvgWarVote 7751 { #投票
        request {
            actId 1: uint32 #活动id
            timeIdList 2: *uint32 #投票时间段列表
        }
        response {

        }
    }

    seasonGvgWarSignUp 7752 { #报名
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #队伍id
            timeIdList 3: *uint32 #报名时间段列表
        }
        response {

        }
    }

    seasonGvgWarCancelSignUp 7753 { #取消报名
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #队伍id
        }
        response {

        }
    }

    seasonGvgWarReservation 7754 { #预约报名
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #队伍id
            timeIdList 3: *uint32 #报名时间段列表
        }
        response {

        }
    }

    seasonGvgWarCancelReservation 7755 { #取消预约报名
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #队伍id
        }
        response {

        }
    }

    seasonGvgWarGetVoteDetailInfo 7756 { #查看投票详情
        request {
            actId 1: uint32 #活动id
            teamId 2: uint32 #队伍id
            timeId 3: uint32 #时间段id
        }
        response {
            userList 1: *SeasonGvgWarVoteInfo(uid)
        }
    }
]]

seasonGvgWarProto.s2c = seasonGvgWarProto.struct .. [[

]]

return seasonGvgWarProto