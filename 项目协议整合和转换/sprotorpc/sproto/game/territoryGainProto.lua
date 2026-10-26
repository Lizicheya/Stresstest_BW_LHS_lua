--  领地增益  6921 ~ 6930
local territoryGainProto = {}

territoryGainProto.struct = [[

    .ComTerritoryGainFreeItem {
        territoryGainFreeId  0: integer         # TerritoryGainFree配置id
        territoryGainId 1: integer               # territoryGain配置id
        canUseCount 3: integer                  # 可使用次数
        recoverTime 4: integer                  # 恢复时间戳
        lastUseTime 5: integer                  # 上次使用时间
    }
]]

territoryGainProto.c2s = territoryGainProto.struct..[[

    getTerritoryGainFreeItem 6921 { #免费增益信息
        request {
        }
        response {
            items 0: *ComTerritoryGainFreeItem(territoryGainFreeId)
        }
    }

    useTerritoryGainFreeItem 6922 { #使用免费增益
        request {
            territoryCfgId  0: uint32                # 配置id
            freeId  1: uint32                        # 免费使用增益配置id
            x 2: uint32                              # 位置x
            y 3: uint32                              # 位置y

        }
        response {
            freeItem 1:ComTerritoryGainFreeItem       # 信息

            x 2: integer             # 免费迁城x
            y 3: integer             # 免费迁城y
        }
    }


]]

territoryGainProto.s2c = territoryGainProto.struct..[[
   
]]

return territoryGainProto