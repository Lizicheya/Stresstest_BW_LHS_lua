-- x玩法 8561~8610
local xGameplayProto = {}

xGameplayProto.struct = [[
    
]]

xGameplayProto.c2s = xGameplayProto.struct..[[

xGameplayBattleResult 8561 {                          # 关卡战斗结果
    request {
        isWin 0: boolean                              # 是否胜利
        levelCfgId 1: uint32                          # 关卡id
        killList 2: *ComUint32Uint32()                # 击杀列表
    }
    response {
        ress 0: *ComRes                               # 奖励
    }
}

]]

xGameplayProto.s2c = xGameplayProto.struct..[[

]]

return xGameplayProto