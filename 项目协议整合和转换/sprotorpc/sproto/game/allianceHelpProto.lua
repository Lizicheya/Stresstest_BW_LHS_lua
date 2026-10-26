--联盟帮助 3201~3300
local allianceProto = {}

allianceProto.struct = [[
    .ComAllianceHelp {
        id 0: integer                                           # 帮助数据id
        uid 1: integer                                          # 请求帮助的玩家id
        nickName 2: string                                      # 请求帮助的玩家昵称
        headId 3: integer                                       # 请求帮助的玩家头像id
        headFrameId 4: integer                                  # 请求帮助的玩家头像框id
        queueCfgId 5: integer                                   # 队列配置id
        maxTimes 6: integer                                     # 最大帮助次数
        helpTimes 7: integer                                    # 已帮助次数
        cfgId 8: integer                                        # 帮助配置id
        lv 9: integer                                           # 帮助等级
        addTime 10: integer                                     # 添加时间
        dailyUsedTimes 11: integer                              # 已经使用的每日次数
    }
    
    .ComSyncDataAllianceHelp {
        news 1: *ComAllianceHelp(id)                            # 帮助数据列表
        changes 2: *ComAllianceHelp(id)                         # 帮助数据列表
        removes 3: *integer                                     # 删除帮助id
    }

    .ComPlayerAllianceHelp {
        gainedHonorOfToday 1: integer                       # 今日获得的荣耀
        nextRefreshTimeOfCap 2: integer                     # 下次刷新上限的时间
        helpTimesOfToday 3: integer                         # 今日帮助次数
    }

    .ComAllianceHelpDaily {                         # 联盟帮助每日信息
        nextDailyResetTime 0: integer               # 下次刷新时间戳
        dailyQueueType2BeHelpTimes 1: *ComIntInt()  # 每个队列类型被帮助的次数，单位次
    }

    .ComSyncAllianceHelpDailyHelpTimes {
        news 1:  *ComIntInt()                      # 帮助数据列表
        changes 2:  *ComIntInt()                   # 帮助数据列表
        removes 3: *integer                        # 删除帮助id
    }
    .ComSyncAllianceHelpDaily {
        nextDailyResetTime 0: integer
        dailyQueueType2BeHelpTimes 1: ComSyncAllianceHelpDailyHelpTimes
    }
]]

allianceProto.c2s = allianceProto.struct .. [[
    reqHelpAllAllianceMember 3201 {                             # 帮助所有联盟成员
        request {

        }
        response {
            beHelpedNickNames 1: *string                        # 被帮助的玩家昵称列表
        }
    }

    reqAllAllianceHelpData 3202 {                               # 请求所有联盟帮助数据（开启步增量帮助数据）
        request {

        }
        response {
            allianceHelp 0: *ComAllianceHelp(id)                # 帮助数据列表
            gainedHonorOfToday 1: integer                       # 今日获得的荣耀
            nextRefreshTimeOfCap 2: integer                     # 下次刷新上限的时间
        }
    }

    stopSyncAllianceHelp 3203 {                                 # 取消同步增量帮助数据（客户端关闭帮助界面时发送）
        request {

        }
        response {
            
        }
    }
]]

allianceProto.s2c = allianceProto.struct .. [[
    syncClearHelpDataForQuitAlliance 3251 {                     # 同步清除退出联盟的玩家的帮助数据
        request {

        }
    }

    syncPendingTimes 3252 {                                     # 同步待帮助次数
        request {
            pendingTimes 0: integer                             # 待帮助次数
        }
    }
    
    syncAllianceHelp 3253 {                                     # 同步增量帮助数据
        request {
            allianceHelp 0: ComSyncDataAllianceHelp             # 联盟帮助
            gainedHonorOfToday 1: integer                       # 今日获得的荣耀
            nextRefreshTimeOfCap 2: integer                     # 上次获得荣耀的时间
        }
    }

    syncBeHelpedByAllianceMember 3254 {                         # 被联盟成员帮助
        request {
            id 1: integer                                       # 帮助数据id
            queueCfgId 2: integer                               # 队列配置id
            uidOfHelper 3: integer                              # 帮助者id
            nickNameOfHelper 4: string                          # 帮助者昵称
        }
    }
]]

return allianceProto