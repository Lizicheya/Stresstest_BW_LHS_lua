-- 阵型模块 1400~1500
local formationProto = {}

formationProto.struct = [[

    .ComFormation {
        id 0: uint32                         # id队列ID
        heros 1: *ComIntInt()                # 英雄ID [pos]->heroId
    }
]]

formationProto.c2s = formationProto.struct..[[

arrangeFormation 1401 { #布置阵型
    request {
        formations 0: *ComFormation(id)   #阵型信息
    }
    response {
    }
}

]]

formationProto.s2c = formationProto.struct..[[

]]

return formationProto