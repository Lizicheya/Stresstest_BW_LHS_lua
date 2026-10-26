-- kingWar 6701 ~ 6750
local kingWarProto = {}

kingWarProto.struct = [[
    #国王战活动信息
    .ComKingWarActInfo {
        round 0: integer         # 第几轮
        status 1: integer        # 状态 kingWarStatus
        statusEndTime 2: integer # 状态结束时间
        durations 3: *integer    # 状态时间
        groupId 4: integer       # 组id
    }

    #国王信息
    .ComKingInfoData {
        kingAid 0: integer       # 国王联盟ID
        kingUid 1: integer       # 国王玩家ID
        kingEndTs 2: integer     # 国王选择截止时间
        kingPack 3: *ComIntInt() # 国王礼包剩余数量
        noticeCd 4: integer      # 公告发布CD
        kingKid 5: integer       # 国王KID
        isCW 6: boolean          # 是否跨服战
        kingSetTime 7: integer   # 上任时间戳
        kingServerMailCdEndTime 8: integer # 国王服务器邮件CD结束时间

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        fullName 14: string      # 联盟全称
        abbName 15: string       # 联盟简称
        flagId 16: integer       # 标志样式
        colorId 17: integer      # 标志颜色
        patternId 18: integer    # 标识图案
    }

    #国王技能信息
    .ComKingSkillData {
        skillId 0: integer       # 技能ID
        cnt 1: integer           # 技能使用次数
        endTs 2: integer         # 技能截止时间
    }

    #国王官职信息
    .ComOfficialData {
        id 0: integer           # 官职ID
        uid 1: integer          # 玩家ID
        kid 2: integer          # KID
        setTime 3: integer      # 上岗时间戳（秒）

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        aid 14: integer          # 玩家联盟ID
        abbName 15: string       # 联盟简称
    }

    .ComOfficialOptType {       # 官职上岗方式
        id 0: integer           # 官职ID
        optType 1: integer      # 1 批准上岗，2 预约上岗
    }
    .ComSyncOfficialOptType {   # 同步官职上岗方式
        news 0: *ComOfficialOptType(id)
        changes 1: *ComOfficialOptType(id)
        removes 2: *integer
    }

    .ComOfficialWaitQueueItem {
        uid 0: integer               # 玩家uid
        turnOfficialsTime 1: integer # 排队排到可以上岗的时间戳

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        fullName 14: string      # 联盟全称
        abbName 15: string       # 联盟简称
    }

    .ComOfficialWaitQueue {                     # 预约上岗, 等待上岗数据
        id 0: integer                           # 官职ID
        list 1: *ComOfficialWaitQueueItem(uid)  # 等待上岗玩家UID列表
        offOfficialTime 2: integer              # 当前岗位上的玩家离任时间戳（秒）
    }
    .ComSyncOfficialWaitQueue {
        news 0: *ComOfficialWaitQueue(id)
        changes 1: *ComOfficialWaitQueue(id)
        removes 2: *integer
    }

    .ComOfficialApplyListItem {
        uid 0: integer         # 申请的玩家uid
        applyTime 1: integer   # 申请时间戳（秒）

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        fullName 14: string      # 联盟全称
        abbName 15: string       # 联盟简称
    }
    .ComOfficialApplyList {    # 批准上岗, 申请列表
        id 0: integer          # 官职ID
        list 1: *ComOfficialApplyListItem # 申请的玩家列表
    }
    .ComSyncOfficialApplyList {
        news 0: *ComOfficialApplyList(id)
        changes 1: *ComOfficialApplyList(id)
        removes 2: *integer
    }

    .ComOfficialsApplyWaitQueueItem {
        uid 0: integer              # 玩家uid
        setOfficialsTime 1: integer # 批准上任时间戳（秒）

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        fullName 14: string      # 联盟全称
        abbName 15: string       # 联盟简称
    }
    .ComOfficialsApplyWaitQueue {  # 批准上岗 等待上岗队列
        id 0: integer              # 官职ID
        list 1: *ComOfficialsApplyWaitQueueItem # 等待上岗玩家UID列表
    }
    .ComSyncOfficialsApplyWaitQueue {
        news 0: *ComOfficialsApplyWaitQueue(id)
        changes 1: *ComOfficialsApplyWaitQueue(id)
        removes 2: *integer
    }
    
    .ComOfficialOpt {                                  # 官职上岗数据
        optType 0: *ComOfficialOptType(id)             # 官职上岗方式
        waitQueue 1: *ComOfficialWaitQueue(id)         # 预约上岗, 等待上岗数据

        applyList 2: *ComOfficialApplyList(id)            # 批准上岗, 申请列表
        applyWaitQueue 3: *ComOfficialsApplyWaitQueue(id) # 批准上岗 等待上岗队列
    }
    .ComSyncOfficialOpt {
        optType 0: ComSyncOfficialOptType
        waitQueue 1: ComSyncOfficialWaitQueue

        applyList 2: ComSyncOfficialApplyList
        applyWaitQueue 3: ComSyncOfficialsApplyWaitQueue
    }

    #国王战数据
    .ComKingWarData {
        actInfo 0: ComKingWarActInfo # 活动信息
        kingInfo 1: ComKingInfoData # 国王信息
        skills 2: *ComKingSkillData(skillId) # 国王技能信息
        official 3: ComOfficialData # 自己的官职信息 注: 无则为nil
    }

    #国王礼包分配记录
    .ComKingWarDivideRecord {
        ts 0: integer
        tp 1: integer
        uid 2: integer
        aid 3: integer
        nickName 4: string
        abbName 5: string
        nickNameKing 6: string
        abbNameKing 7: string
        kidKing 8: integer  # 国王KID 旧服数据为nil
        kid 9: integer  # 玩家KID 旧服数据为nil
    }

    #累计占领时长排行
    .ComKingWarOccupyRank {
        aid 0: integer       #联盟ID
        ts 1: integer       #累计占领时长
        fullName 2: string #联盟全称
        abbName 3: string #联盟简称
        flagId 4: integer #标志样式
        colorId 5: integer #标志颜色
        patternId 6: integer #标识图案
        time 7: integer #排序时间戳
        nickName 8: string

        occupyStartTime 9: integer #占领开始时间（只当前占领者联盟值）
        occupyEndTime 10: integer #占领截止时间（只当前占领联盟有值）
        kid 11: integer  #联盟KID
    }

    #国王历史记录
    .ComKingWarHistoryRecord {
        round 0: integer       # 第几轮
        aid 1: integer       # 国王联盟ID
        uid 2: integer       # 国王玩家ID
        nickName 3: string #玩家昵称
        headId 4: integer #头像
        headFrameId 5: integer #头像框
        fullName 6: string #联盟全称
        abbName 7: string #联盟简称
        flagId 8: integer #标志样式
        colorId 9: integer #标志颜色
        patternId 10: integer #标识图案
        ts 11: integer #时间戳
        kid 12: integer # 国王玩家KID 旧服数据为nil
        isCW 13: boolean #是否跨服战
    }

    #获取国王技能使用记录
    .ComKingWarSkillRecord {
        skillId 0: integer       # 技能
        aid 1: integer       # 国王联盟ID
        uid 2: integer       # 国王玩家ID
        nickName 3: string #玩家昵称
        abbName 4: string #联盟简称
        ts 5: integer #时间戳
        kid 6: integer # 国王KID 旧服数据为nil
    }

    #获取战斗记录
    .ComKingWarWarRecord {
        tp 0: integer        # 类型 kingWarRecord
        uid 1: integer       # 玩家ID
        aid 2: integer       # 联盟ID
        nickName 3: string #玩家昵称
        abbName 4: string #联盟简称
        ts 5: integer #时间戳
        uid2 6: integer       # 玩家ID
        aid2 7: integer       # 联盟ID
        nickName2 8: string #玩家昵称
        abbName2 9: string #联盟简称
        kid 10: integer # uid之kid
        kid2 11: integer # uid2之kid
    }

    #死兵复活信息
    .ComKingWarResurrect {
        buyLimit 0: *ComIntInt() #复活道具购买限制 道具id-数量
        persent 1: *ComIntInt() #当前复活比例 类型-万分比
        persentHad 2: integer   #已复活的万分比
        resurrectArmyOri 3: *ComArmyIdAndNum()     # 王战复活士兵(原始)
        beHelped 4: integer     #被帮助次数
    }

    .ComAllianceResurrectHelp {
        uid 0: integer                                          # 请求帮助的玩家id
        nickName 1: string                                      # 请求帮助的玩家昵称
        headId 2: integer                                       # 请求帮助的玩家头像id
        headFrameId 3: integer                                  # 请求帮助的玩家头像框id
        helpTimes 4: integer                                    # 已帮助次数
        deadNum 5: integer                                      # 死兵数量
    }

    .ComSyncAllianceResurrectHelp {
        news 0: *ComAllianceResurrectHelp(uid)                   # 帮助数据列表
        changes 1: *ComAllianceResurrectHelp(uid)                # 帮助数据列表
        removes 2: *integer                                      # 删除帮助uid
    }
    
    .ComKingWarScore {                      # 积分数据
        score 0 : integer                   # 个人积分
        scoreDetail 1 : *ComIntInt()        # 个人积分明细 kingWarPointType
        gainScoreRewardList 2: *ComIntInt() # 积分奖励领取状态 【配置id] => 领取状态
    }

    .ComKingWarOfficialSetLog { # 官职岗位上任日志
        id 0: integer          # 官职配置id
        uid 1: integer         # 玩家ID
        kid 2: integer         # 玩家KID
        setTime 3: integer     # 上岗时间戳（秒）

        # 以下为给客户端的显示数据
        nickName 11: string      # 玩家昵称
        headId 12: integer       # 头像
        headFrameId 13: integer  # 头像框
        fullName 14: string      # 联盟全称
        abbName 15: string       # 联盟简称
    }
 ]]

kingWarProto.c2s = kingWarProto.struct .. [[

 getKingWarInfo 6701 { #获取王战信息
    request {
    }
    response {
        score 0 : integer                   # 个人积分
        scoreDetail 1 : *ComIntInt()        # 个人积分明细 kingWarPointType
        gainScoreRewardList 2: *ComIntInt() # 积分奖励领取状态 【配置id] => 领取状态
    }
 }

  setKingUid 6702 { #任命国王 (跨服共用)
    request {
        kingUid 0: uint32         # 国王UID
        serverId 1: uint32        # 服务器ID
    }
    response {
        kingInfo 0: ComKingInfoData # 国王信息
    }
 }

 divideKingWarReward 6703 { #分配国王礼包 (跨服共用)
    request {
        tp 0 : uint32
        uids 1: *uint32
        serverId 2: uint32 # 分配哪个服务器的官职
    }
    response {
        tp 0 : integer
        num 1: integer
        uids 2: *integer
    }
 }

 setKingWarOfficial 6704 { #任命国王官职 (跨服共用)
    request {
        id 0: uint32
        uid 1: uint32
        serverId 2: uint32 # 任命哪个服务器的官职
    }
    response {
        id 0: integer
        uid 1: integer
    }
 }

  useKingWarSkill 6705 { #使用国王技能 (跨服共用)
    request {
        skillId 0: uint32
        serverId 1: uint32 # 使用哪个服务器的国王技能
    }
    response {
        skillId 0: integer
        svrItems 1: *ComIntInt()
    }
  }

  setKingWarNotice 6706 { #设置国王公告 (跨服共用)
    request {
        notice 0: string
        serverId 1: uint32
    }
    response {
    }
  }

  getKingWarOfficial 6707 { #获取所有国王官职 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        officials 0: *ComOfficialData(id)
    }
  }

  getKingWarKingInfo 6708 { #获取国王信息 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        kingInfo 0: ComKingInfoData # 国王信息
        notice 1: string # 公告
    }
  }

  getKingWarDivideRecord 6709 { #获取分配记录 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        records 0: *ComKingWarDivideRecord # 数组尾部为最新记录
    }
  }

  getKingWarOccupyRank 6710 { #获取占领排行信息 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        aid 0: integer #当前占领联盟ID
        ranks 1: *ComKingWarOccupyRank(aid) #占领排行信息(未排序)
    }
  }

  getKingWarHistory 6711 { #获取国王历史记录 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        list 0: *ComKingWarHistoryRecord #尾部为最新
    }
  }

  getKingWarSkillRecords 6712 { #获取国王技能使用记录 (跨服共用)
    request {
        serverId 0: uint32
    }
    response {
        list 0: *ComKingWarSkillRecord #尾部为最新
    }
  }

  getKingWarWarRecords 6713 { #获取战斗记录 (跨服共用)
    request {
        capitalId 0: uint32
        serverId 1: uint32
    }
    response {
        list 0: *ComKingWarWarRecord #尾部为最新
    }
  }

  getSvrItems 6714 { #获取全服物品信息 (跨服共用)
    request {
        serverId 1: uint32
    }
    response {
        svrItems 0: *ComIntInt()
    }
  }
  
  getKingWarSkills 6715 { #获取所有国王技能 (跨服用, 本王国的技能有常驻kingWarData.skills)
    request {
        serverId 0: uint32
    }
    response {
        skills 0: *ComKingSkillData(skillId) # 国王技能信息
    }
  }

  buyKingWarResurrectItems 6716 { #购买王战复活道具
    request {
        id 0: uint32
    }
    response {
        ress 0: *ComRes
    }
  }

  getKingWarResurrectArmy 6717 { #王战复活士兵
    request {
    }
    response {
        ress 0: *ComRes
    }
  }

  helpKingWarResurrectArmy 6718 { #王战帮助复活士兵
    request {
        uid 0: uint32
        num 1: uint32
    }
    response {
    }
  }

    chgOfficialsOptType 6719 { # 更改官职上岗方式
        request {
            id 0: uint32         # 官职id
            optType 1: uint32    # 1 批准，2 预约
        }
        response {
        }
    }

    joinOfficialsWaitQueue 6720 { # 预约上岗模式：申请加入官职等待上岗队列
        request {
            id 0: uint32          # 官职id
        }
        response {
        }
    }

    officialsApply 6721 { # 批准上岗模式：玩家申请官职
        request {
            id 0: uint32          # 官职id
        }
        response {
        }
    }

    approveOfficialsApply 6722 {       # 批准上岗模式：管理员批准官职申请
        request {
            id 0: uint32               # 官职id
            uid 1: uint32              # 被操作的玩家UID
            approve 2: boolean         # 是否批准
            setOfficialsTime 3: uint32 # 上任时间，0 表示立即上任
        }
        response {
        }
    }

    gainKingWarScoreReward 6723 {    # 领取王战积分奖励
        request {
            index 0: uint32          # 奖励配置id
        }
        response {
            reward 0: *ComRes        # 奖励内容
        }
    }

    getKingWarOfficialSetLog 6724 {           # 获取官职岗位上任日志
        request {
            id 0: uint32                      # 官职配置id，如果要获取所有官职的日志，传0
        }
        response {
            logs 0: *ComKingWarOfficialSetLog # 官职任命日志列表，按时间倒序排列
        }
    }
    
    getKingWarOfficialOpt 6725 {   # 获得操作官职的信息
        request {
            id 0: uint32           # 官职配置id，如果要获取所有官职的日志，传0
        }
        response {
            opt 0: ComOfficialOpt  # 官职操作信息
        }
    }

    cancelOfficialsWait 6726 {    # 取消官职等待上岗
        request {
            id 0: uint32          # 官职id
        }
        response {
        }
    }

    sendKingServerMail 6727 { # 发送国王服务器邮件
        request {
            title 0: string
            content 1: string
        }
        response {
        }
    }
]]

kingWarProto.s2c = kingWarProto.struct .. [[

]]

return kingWarProto
