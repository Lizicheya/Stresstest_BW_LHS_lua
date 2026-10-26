-- 基础资源 8071～8090
local basicRessProto = {}

basicRessProto.struct = [[
    .ComBasicRess {
        cfgId 0: uint32               # 资源配置id
        curVal 1: double              # 当前值
        settleTs 2: uint32            # 上一次结算时间戳
        incrRate 6: double            # 增加速度(N/h)
        decrRate 7: double            # 消耗速度(N/h)
    }
]]

basicRessProto.c2s = basicRessProto.struct .. [[

]]

basicRessProto.s2c = basicRessProto.struct .. [[

]]

return basicRessProto