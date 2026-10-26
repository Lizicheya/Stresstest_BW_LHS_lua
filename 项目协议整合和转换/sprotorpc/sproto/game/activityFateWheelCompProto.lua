 -- fateWheel 5001 ~ 5100
local fateWheelProto = {}

fateWheelProto.struct = [[
.ComFateWheelDropItem {
    dropType 0: integer                 # 掉落类型(FateWheelDropType)
    dropId 1: integer                   # 掉落id
}

.ComFateWheelInfo {
    id 0: integer                       #ID
    dayDrawCount 3: integer             #当天已经抽奖次数
    totalDrawCount 4: integer           #总的抽奖次数
    discount 9: integer                 #折扣
    groupId 10: integer                 #fateWheelDrop.group
    boxIds 11: *integer                 #宝箱ID 
    
}

.ComFateWheelActivityInfo {
    id 0: integer                       #活动ID
    fateWheelInfo 1:ComFateWheelInfo    #转盘信息  
}

.ComFateWheelReward {
    ress 0: *ComRes
    index 1: integer
}
]]
 
fateWheelProto.c2s = fateWheelProto.struct..[[
 
fateWheelDrawOne 5001 {                    #抽奖一次
    request {
        id 0: uint32                       #ID
    }
    response {
        rewards 0: *ComFateWheelReward
        ress 1: *ComRes
    }
}
 
fateWheelDrawMutil 5002 {                  #抽奖多次次数必须大于等于10
    request {
        id 0: uint32                       #ID
        num 3: uint32                      #数量
    }
    response {
        rewards 0: *ComFateWheelReward
        ress 1: *ComRes                     # 10抽以上只显示奖励，不做表现动画
    }
}
 
getFateWheelBoxReward 5003 {               #获取幸运之轮宝箱奖励
    request {
        id 0: uint32                       #ID
        subId 1: uint32                    #子ID
    }
    response {
        ress 0: *ComRes
    }
}
 
reqFateWhellExchangeAndUse 5005 {               # 命运之轮兑换
    request {
        id 0: uint32                      #ID
        count 1: uint32                   #兑换次数+
    }
    response {
        rewards 1: *ComFateWheelReward
        ress 2: *ComRes                     # 10抽以上只显示奖励，不做表现动画
    }
}

reqFateWheelChangeGroup 5006 {   # 更换奖池组
    request {
        id 1: uint32
        groupId 2: uint32
    }
    response {

    }
}
 
]]
 
fateWheelProto.s2c = fateWheelProto.struct..[[

]]
 
return fateWheelProto