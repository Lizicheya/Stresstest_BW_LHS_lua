local table_insert = table.insert

local package = {
    "sproto.package",
    "sproto.game.commonStruct"
}

local game_proto = {}

function game_proto.createSproto(rootPath, protoFiles)
    local tmpStructs = {}
    for _, v in ipairs(package) do
        local tempPath = rootPath .. v
        -- print("=========" .. tempPath)
        local tempStruct = require(tempPath)
        if not tempStruct then
            print("========= tempStruct is nil")
        end
        table_insert(tmpStructs, tempStruct)
    end

    local typesInfos = table.concat(tmpStructs)
    game_proto.types = typesInfos

    local tmp_c2s = {}
    local tmp_s2c = {}

    table_insert(tmp_c2s, typesInfos)
    table_insert(tmp_s2c, typesInfos)
    for _, v in ipairs(protoFiles) do
        local tempPath = rootPath .. v
        local tempStruct = require (tempPath)
        if tempStruct.c2s then
            table_insert(tmp_c2s, tempStruct.c2s)
        end
        if tempStruct.s2c then
            table_insert(tmp_s2c, tempStruct.s2c)
        end
    end

    local allSprotoInfos_c2s = table.concat(tmp_c2s)
    local allSprotoInfos_s2c = table.concat(tmp_s2c)

    -- game_proto.c2s = allSprotoInfos_c2s
    -- game_proto.s2c = allSprotoInfos_s2c
    return {
        c2s = allSprotoInfos_c2s,
        s2c = allSprotoInfos_s2c
    }
end

return game_proto
