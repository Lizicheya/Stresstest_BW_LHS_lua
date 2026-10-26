-- 试炼模块 901~1000
local trialProto = {}

trialProto.struct = [[
    .CompTrialTroop {
        type 1: uint32
        army 19: *ComArmyIdAndNum()
        heros 17: *uint32
        targetX 15: uint32
        targetY 16: uint32
    }
]]

trialProto.c2s = trialProto.struct..[[

createTrialRoom 901 { # 创建试炼房间
    request {
        trialCfgId 0: uint32           # 试炼配置表id
        troopData 1: CompTrialTroop     # 试炼部队
    }
    response {
    }
}

challengeTrial 902 { # 挑战副本
    request {
        trialCfgId 0: uint32           # 试炼配置表id
    }
    response {
    }
}

]]

trialProto.s2c = trialProto.struct..[[

]]

return trialProto