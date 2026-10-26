-- buff模块 501~600
local buffProto = {}

buffProto.struct = [[
    .ComBuff {
        buffCfgId 0: integer            # id(每个玩家的建筑id唯一)
        expiredTs 1: double             # 结束时间
        overrideTimes 2: integer        # 叠加次数
        startTime 3: double             # 开始时间
    }
]]

buffProto.c2s = buffProto.struct..[[

]]

buffProto.s2c = buffProto.struct..[[

]]

return buffProto