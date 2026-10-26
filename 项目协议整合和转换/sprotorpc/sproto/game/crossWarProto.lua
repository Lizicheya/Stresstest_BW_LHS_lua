-- 跨服战 7901 ~ 7950
local crossWarProto = {}

crossWarProto.struct = [[
    #跨服战活动信息
    .ComCrossWarActInfo {
        round 0: integer         # 第几轮
        status 1: integer        # 状态 crossWarStatus
        statusEndTime 2: integer # 状态结束时间
        durations 3: *integer    # 状态时间
        startTime 4: integer     # 活动开始时间
        groupId 5: integer       # 组id
        vsKid 6: integer         # 对战方王国ID
    }
    
    .ComCrossWarPlyInfo {
        score 0 : integer            # 个人积分
        scoreDetail 1 : *ComIntInt() # 个人积分明细 kingWarPointType
        changeWorldCnt 2 : integer   # 跨服迁城次数
        changeWorldCd 3 : integer    # 跨服迁城cd  
    }
    
    .ComCrossWarSvrInfo {
        score 0 : integer            # 积分
        vsscore 1 : integer          # 对方积分
        isWin 2 : integer            # 是否胜利 0:未结算 1:win 2:lose
    }

    #跨服战数据
    .ComCrossWarData {
        actInfo 0: ComCrossWarActInfo # 活动信息
        plyInfo 1: ComCrossWarPlyInfo # 个人信息
        svrInfo 2: ComCrossWarSvrInfo # 王国信息
        vsKingInfo 3: ComKingInfoData # 对战国的国王信息  注: 可为nil
        vsOfficial 4: ComOfficialData   # 自己的对战国官职信息  注: 无则为nil
    }
    
    #当前占领中联盟信息
    .ComCrossWarCurOccupy {
        aid 0: integer                                  # 当前占领联盟ID
        occupyStartTime 1: integer                      # 当前占领联盟ID之占领开始时间
        occupyEndTime 2: integer                        # 当前占领联盟ID之占领截止时间
    }
 ]]

crossWarProto.c2s = crossWarProto.struct .. [[
 getCrossWarInfo 7901 { #获取个人、王国信息 
    request {
    }
    response {
    }
 }
]]

crossWarProto.s2c = crossWarProto.struct .. [[

]]

return crossWarProto
