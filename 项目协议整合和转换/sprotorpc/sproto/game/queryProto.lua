-- 查询模块 801~900
local queueProto = {}

queueProto.struct = [[
    
]]

queueProto.c2s = queueProto.struct..[[

queryCity 801 {                                         # 查询玩家城池
    request {
        uid 0: uint32
    }
    response {
        uid 0: integer
        city 1: *ComBuild(id)                           # 建筑列表
        applySkins 2: *ComIntInt()                      # 应用的皮肤（skinCfgId->lv）
        currentOpenBarrier 3: integer                   # 当前挑战副本
        latestCompletedBarrier 4: integer               # 最后通关挑战副本
        cityAreaUnlock 5: *ComCityAreaUnlock(areaCfgId) # 区域解锁
        age 6: integer                                  # 时代
        style 7: integer                                # 风格
    }
}

]]

queueProto.s2c = queueProto.struct..[[

syncCity 851 {
    request {
        uid 0: integer
        city 1: *ComBuild(id)                           # 建筑列表
        applySkins 2: *ComIntInt()                      # 应用的皮肤（skinCfgId->lv）
        currentOpenBarrier 3: integer                   # 当前挑战副本
        latestCompletedBarrier 4: integer               # 最后通关挑战副本
        cityAreaUnlock 5: *ComCityAreaUnlock(areaCfgId) # 区域解锁
    }
}

]]

return queueProto