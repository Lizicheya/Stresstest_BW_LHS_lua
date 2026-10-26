--资源收集模块 1101~1200
local resProduceProto = {}

resProduceProto.struct = [[
    .CompResProduce {
        buildId 1: integer
        produceResCfgId 2: integer
        stock 3: integer
        startTS 4: double
        lastSettleTS 5: double
        yield 6: integer
        yieldRatio 7: integer  #buf
        yieldReduce 8: integer  #debuf
        isFull 9: boolean
    }
]]

resProduceProto.c2s = resProduceProto.struct..[[

collectResource 1101 { # 收集资源
    request {
        buildIds 0: *uint32                # 资源配置id
    }
    response {
        obtainResources 4: *ComIntInt()     # 获得的资源 buildId<=>resNum
        extraDropRess 5: *ComRes            # 获得的额外掉落资产
    }
}

]]

resProduceProto.s2c = resProduceProto.struct..[[

]]

return resProduceProto