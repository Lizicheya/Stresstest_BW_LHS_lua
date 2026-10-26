--内城怪物 4501 ~ 4600
local cityMonsterProto = {}

cityMonsterProto.struct = [[

]]

cityMonsterProto.c2s = cityMonsterProto.struct..[[

reqkillCityMonster 4501 { # 杀内城怪获得奖励，返回下次刷新时间
    request {
       
    }
    response {
        refreshTS 0: integer    # 下次刷怪时间
        dropRes 1: *ComRes      # 本次奖励
    }
}

]]

cityMonsterProto.s2c = cityMonsterProto.struct..[[

]]

return cityMonsterProto