-- 设置 6851 ～ 6870
local settingProto = {}

settingProto.struct = [[

]]

settingProto.c2s = settingProto.struct..[[
    gameSetting 6851 {  # 游戏设置
        request {
            settings 0: *ComUint32Uint32()
        }
        response {

        }
    }
]]

settingProto.s2c = settingProto.struct..[[

]]

return settingProto