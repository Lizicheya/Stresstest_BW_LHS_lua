--联盟模块 1601~2600
local allianceProto = {}

allianceProto.struct = [[
    .ComAllianceInfo {
        fullName 0: string #联盟全称
        abbName 1: string #联盟简称
        announcement 2: string #联盟公告
        language 3: uint32 #联盟语言
        flagId 4: uint32 #标志样式
        colorId 5: uint32 #标志颜色
        patternId 6: uint32 #标识图案
        isVerify 7: boolean #是否需要审批
        power 8: integer #战力要求
        notice 9: string #联盟公告（对内）
        welcomeMailContent 10: string #欢迎邮件内容
        castleLv 11: uint32 #主堡等级要求
    }

    .ComMemberNote {
        key 1: uint32
        value 2: string
    }

    .ComAllianceBase {
        aid 0: integer #联盟id
        level 1: integer #联盟等级
        exp 2: integer #联盟经验
        maxMemberNum 3: integer #联盟成员数量上限
        isImpeach 4: boolean #盟主是否弹劾中
        impeachTime 5: integer #发起弹劾时间戳
        impeacher 6: integer #发起弹劾者
        allianceInfo 7: ComAllianceInfo #联盟基础信息
        lastCallForTime 8: integer #上次号召捐献时间戳
        lastShareInviteTime 9: integer #上次分享邀请入盟时间戳
        notes 10: *ComMemberNote() # 联盟成员备注
        alliancePoint 11: ComPoint # 当前联盟集合点坐标
        isPlacePoint 12: boolean # 是否设置过联盟集合点
    }    

    .ComSearchAllianceInfo { 
        aid 0: integer #联盟id
        level 1: integer #联盟等级
        totalPower 2: integer #联盟总战力
        memberNum 3: integer #当前联盟成员数量
        maxMemberNum 4: integer #联盟成员数量上限
        leaderId 5: integer #盟主id
        nickName 6: string #昵称
        headId 7: integer #头像
        headFrameId 8: integer #头像框
        customHead 9: string #自定义头像
        allianceInfo 10: ComAllianceInfo #联盟信息
        serverId 11: integer #服务器id
    }

    .ComDetailAllianceInfo {
        aid 0: integer #联盟id
        level 1: integer #联盟等级
        exp 2: integer #联盟经验
        totalPower 3: integer #联盟总战力
        memberNum 4: integer #当前联盟成员数量
        maxMemberNum 5: integer #联盟成员数量上限
        terrNum 6: integer #领土
        giftLevel 7: integer #联盟礼物
        leaderId 8: integer #盟主id
        nickName 9: string #盟主昵称
        headId 10: integer #头像
        headFrameId 11: integer #头像框
        customHead 12: string #自定义头像
        allianceInfo 13: ComAllianceInfo #联盟信息
        serverId 14: integer #服务器id
        rank 15: integer #联盟排名
        scoreRank 16: integer #联盟积分活动排名
        notes 17: *ComMemberNote() # 联盟成员备注
    }    

    .ComAllianceJoin {
        isJoined 0: boolean #是否加入过
        aid 1: integer # 0表示没有联盟
    }

    .ComSyncDataAllianceBlock {
        count 1: integer #当前积木数量
        useSpeed 2: double #消耗速度 N/h
        settleTime 3: integer #上一次结算时间戳
    }

    .ComAllianceWorker {
        workerId 1: integer #联盟工人id
        status 2: integer #联盟工人状态 AllianceWorkerStatusEnum
        mapId 3: integer
        buildId 4: integer
    }

    .ComSyncDataAllianceWorker {
        selectId 0: integer
        news 1: *ComAllianceWorker(workerId)
        changes 2: *ComAllianceWorker(workerId)
        removes 3: *integer
    }

    .ComRecommendInvitePlayerInfo {
        uid 0: integer #玩家uid
        nickName 1: string #昵称
        headId 2: integer #头像
        headFrameId 3: integer #头像框
        customHead 4: string #自定义头像
        power 5: integer #战力
        language 6: integer #语言 
    }    

]]

allianceProto.c2s = allianceProto.struct .. [[
    createAlliance 1601 { #创建联盟
        request {
            setInfo 0: ComAllianceInfo #联盟信息
        }
        response {

        }
    }

    disbandAlliance 1602 { #解散联盟
        request {
        }
        response {
        }
    }

    cancelDisbandAlliance 1603 { #取消解散联盟
        request {
        }
        response {
        }
    }

    applyJoinAlliance 1604 { #申请加入联盟
        request {
            aid 0: uint32 #联盟id
        }
        response {
            aid 0: integer
        }
    }

    cancelJoinAlliance 1605 { #取消申请加入联盟
        request {
            aid 0: uint32 #联盟id
        }
        response {
        }
    }

    agreeJoinAlliance 1606 { #同意加入联盟
        request {
            sid 0: uint32 #玩家id
        }
        response {
            sid 0: integer #玩家id
        }
    }

    refuseJoinAlliance 1607 { #拒绝玩家的申请
        request {
            sid 0: uint32 #玩家id
        }
        response {

        }
    }

    quitAlliance 1608 { #退出联盟
        request {

        }
        response {

        }
    }

    kickoutAlliance 1609 { #踢出联盟
        request {
            sid 0: uint32 #玩家id
            reason 1: uint32 #踢人理由
        }
        response {

        }
    }

    setAllianceMemberRank 1610 { #设置联盟成员等级
        request {
            sid 0: uint32 #玩家id
            rank 1: uint32 #成员等级
        }
        response {

        }
    }

    alterAllianceInfo 1611 { #修改联盟信息
        request {
            alterType 0: uint32 #修改类型 AlterInfoType
            alterInfo 1: ComAllianceInfo #联盟信息
        }
        response {

        }
    }

    applyAllianceLeader 1612 { #盟主申请
        request {
        }
        response {
        }
    }

    cancelApplyAllianceLeader 1613 { #取消盟主申请
        request {
        }
        response {
        }
    }

    getAllianceMembers 1614 { #获取联盟成员列表
        request {

        }
        response {

        }
    }

    getAllianceApplys 1615 { #获取联盟玩家申请列表
        request {

        }
        response {
            applys 0: *ComAllianceApplyInfo(uid)
        }
    }

    getAllianceLeaders 1616 { #获取联盟成员竞选列表
        request {

        }
        response {
            leaders 0: *ComAllianceLeaderInfo(uid)
        }
    }

    conferAllianceMemberPosition 1617 { #授命联盟成员官职
        request {
            sid 0: uint32 #玩家id
            position 1: uint32 #成员官职
        }
        response {

        }
    }

    revokeAllianceMemberPosition 1618 { #撤消联盟成员官职
        request {
            sid 0: uint32 #玩家id
        }
        response {

        }
    }

    impeachAllianceLeader 1619 { #申请弹劾盟主
        request {

        }
        response {

        }
    }

    verifyAllianceName 1620 { #验证联盟全称或联盟简称
        request {
            alterType 0: uint32 #全称或简称 AlterInfoType.FULL_NAME or ABB_NAME
            fullName 1: string #联盟全称
            abbName 2: string #联盟简称
        }
        response {

        }
    }

    searchAlliance 1621 { #联盟搜索
        request {
            matchName 0: string # 模糊匹配的名称
        }
        response {
            allianceList 0: *ComSearchAllianceInfo #联盟信息
        }
    }

    recommendAlliance 1622 { #联盟推荐
        request {
            beginPos 0: uint32 # 起始点
            endPos 1: uint32 #结束点
        }
        response {
            allianceList 0: *ComSearchAllianceInfo #联盟信息
        }
    }

    reqAllianceDetailInfo 1623 { #查看联盟信息
        request {
            aid 0: uint32 #联盟id
            serverId 1: uint32 #王国id
        }
        response {
            detailInfo 0: ComDetailAllianceInfo
        }
    }

    reqAllianceMemberInfo 1624 { #查看联盟成员信息
        request {
            aid 0: uint32 #联盟id
            serverId 1: uint32 #王国id
        }
        response {
            members 0: *ComAllianceMemberInfo(uid)
        }
    }

    reqPlayerApplyInfo 1625 { #玩家查看自己的申请列表
        request {
            
        }
        response {
            allianceList 0: *ComSearchAllianceInfo(aid) #联盟信息
        }
    }

    reqIgnoreJoinAlliance 1626 { #管理员忽略玩家的申请
        request {
            list 0: *uint32 #忽略列表[uid,]
        }
        response {
            list 0: *integer #忽略列表[uid,]
        }
    }
    
    invitePlayerToJoinAlliance 1627 { #管理员邀请玩家加入联盟
        request {
            userList 1: *uint32 #被邀请玩家列表
        }
        response {

        }
    }

    reqPlayerInviteInfo 1628 { #玩家查看自己的被邀请列表
        request {
            
        }
        response {
            allianceList 0: *ComSearchAllianceInfo(aid) #联盟信息
        }
    }

    acceptInviteJoinAlliance 1629 { #玩家同意邀请加入联盟
        request {
            aid 0: uint32
        }
        response {
            aid 0: integer
        }
    }

    reqIgnoreAllianceInvite 1630 { #玩家忽略管理员的邀请
        request {
            list 0: *uint32 #忽略列表[aid,]
        }
        response {
            list 0: *integer #忽略列表[aid,]
        }
    }

    allianceGroupSendMessage 1631 { #群发消息
        request {
            uids 0: *uint32 #发送列表
            title 1: string #邮件标题
            content 2: string #邮件内容
        }
        response {

        }
    }

    allianceBlockDonateNormal 1632 { #联盟积木普通捐献
        request {
            num 1: uint32
        }
        response {

        }
    }

    allianceBlockDonateGem 1633 { #联盟积木宝石捐献
        request {
            num 1: uint32
        }
        response {

        }
    }

    allianceWorkerSelectEffiency 1634 { #联盟工人选择工作效率
        request {
            selectId 1: uint32
        }
        response {

        }
    }

    allianceCallForDonate 1635 { #号召捐献
        request {

        }
        response {

        }
    }

    allianceInviteMoveCastle 1636 { # 邀请玩家迁城
        request {
            userID 1: uint32 # 玩家ID
        }
        response {

        }
    }

    allianceBatchInviteMoveCastle 1637 { # 批量邀请玩家迁城
        request {
        }
        response {

        }
    }

    allianceReceiveMoveCastle 1638 { # 确认收到邀请迁城消息
        request {
            
        }
        response {

        }
    }

    allianceRecommendInvitePlayer 1639 { #获取推荐邀请玩家
        request {

        }
        response {
            playerList 1: *ComRecommendInvitePlayerInfo(uid)
        }
    }

    allianceShareInvite 1640 { # 分享邀请
        request {

        }
        response {
            
        }
    }

    allianceUpdateMemberNote 1641 { # 更新联盟成员备注
        request {
            index 1: uint32 # 修改项 r1~r5 MemberRankType
            note 2: string # 备注
        }
        response {

        }
    }

    batchAgreeJoinAlliance 1642 { #批量同意加入联盟
        request {
            list 0: *uint32 #玩家id列表
        }
        response {
            list 0: *uint32 #玩家id列表
        }
    }

    reqAllianceEnemyInfo 1643 {
        request {

        }
        response {
            list 0: *ComAllianceEnemyInfo(uid)
        }
    }

    placeAlliancePoint 1644 { # 放置联盟集合点
        request {
            pos 1: ComPoint
            targetUid 2: integer
        }
        response {

        }
    }

]]

allianceProto.s2c = allianceProto.struct .. [[
    syncQuitAlliance 1651 { #解散退出被踢出联盟后同步
        request {
            exitCode 0: integer # 0:解散 1:退出 2:被踢出
        }
    }

    syncAlliancePointPlace 1652 { # 联盟管理员设置了新的联盟集合点
        request {
            uid  1: integer
            nickName 2: string
        }
    }

]]

return allianceProto