-- 领主装备 7221 ~ 7230
local lordOutfitProto = {}

lordOutfitProto.struct = [[
]]

lordOutfitProto.c2s = lordOutfitProto.struct..[[

    reqActiveLordOutfit 7221 { # 激活领主装备
        request {
            part 0: uint32 # 部位
        }
        response {
            
        }
    }

    reqActiveLordbadge 7222 { # 激活领主装备宝石
        request {
            part 0: uint32 # 部位
            pos 1: uint32 # 位置
        }
        response {
            
        }
    }

    reqUpgradeLordOutfit 7223 { # 领主装备升级
        request {
            part 0: uint32 # 部位
        }
        response {
            
        }
    }

    reqUpgradeLordbadge 7224 { # 领主宝石升级
        request {
            part 0: uint32 # 部位
            pos 1: uint32 # 位置
        }
        response {
            
        }
    }

    reqSetOutfitShow 7225 { # 设置装备展示
        request {
            bShow 0: boolean # 是否展示
        }
        response {
            
        }
    }
]]

lordOutfitProto.s2c = lordOutfitProto.struct..[[

]]

return lordOutfitProto