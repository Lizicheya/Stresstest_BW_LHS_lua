-- 内城PVE 5101 ~ 5200
local cityPveProto = {}

cityPveProto.struct = [[
    #内城PVE阵容数据
    .ComCityPveFormation {
        key 1: uint32   # 站位
        value 2: uint32 # 英雄ID
    }

    .ComCityPveOnhookData { #内场PVE挂机数据
       isUnlock 0: boolean # 挂机奖励是否解锁
       lastAwardTime 1: uint32 #上一次领奖时间
       formation 2: *ComCityPveFormation() #战斗阵容数据
       passMaxLevelId 3: uint32 #通关的最大关卡ID
       pveCoeff 4: uint32 #战力压制系数（服务器平均通关进度）
       stageGoals 5: *ComIntBool() #已领取的pve阶段目标奖励
       unlockBlock 6: *ComIntBool() #已通关的地块绑定的pve关卡
    }
]]

cityPveProto.c2s = cityPveProto.struct .. [[

cityPveBattleResult 5101 { #内城PVE战斗结果
    request {
        levelId 0: uint32 #关卡ID
        formation 1: *ComCityPveFormation() #阵容数据
        iswin 2: boolean
        sceneObjId 3: uint64 # 沙盘对象id
    }
    response {
        ress 0: *ComRes
    }
}


getCityPveOnhookReward 5102 { #获得内城挂机奖励
    request {
    }
    response {
        ress 0: *ComRes
    }
}


cityPveSaveBattleFormation 5104 { #保存战斗整容
    request {
        formation 1: *ComCityPveFormation() #阵容数据
    }
    response {
    }
}

cityPveQueryReward 5105 { #查看当前可以领取的奖励
    request {
    }
    response {
        ress 0: *ComRes
    }
}

reqCityPveCoeff 5106 { #请求 pve 战力压制系数
    request {
    }
    response {
        coeff 0: integer 
    }
}

cityPveStageGoalReward 5107 { # 领取pve阶段目标奖励
    request {
        stageIdList 1: *uint32
    }
    response {
        ress 1: *ComRes
    }
}

]]

cityPveProto.s2c = cityPveProto.struct .. [[

]]

return cityPveProto
