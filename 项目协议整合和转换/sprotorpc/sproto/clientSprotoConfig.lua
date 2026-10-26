local loginSprotoFiles = require("sprotorpc.sproto.loginSprotoConfig")
local gameSprotoFiles = require("sprotorpc.sproto.gameSprotoConfig")

local table_insert = table.insert

-- 合并数组(不去重)
local function mergeArrary(tableList)
    local newTable = {}
    if "table" ~= type(tableList) then
        return newTable
    end
    for i = 1, #tableList do
        local tmpTb = tableList[i]
        if "table" == type(tmpTb) then
            for _, v in pairs(tmpTb) do
                table_insert(newTable, v)
            end
        end
    end
    return newTable
end

local sprotoFilesTableList = {
    loginSprotoFiles,
    gameSprotoFiles
}

local protoFiles = mergeArrary(sprotoFilesTableList)

return protoFiles