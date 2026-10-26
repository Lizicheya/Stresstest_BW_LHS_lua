local M = {}
local rootPath = ""

local function initClientPath(path)
    -- package.path = package.path .. ";./src/app/localserver/?.lua;"
    if path:match("/$") then
        path = path .. "?.lua;"
    else
        path = path .. "/?.lua;"
    end

    package.path = package.path .. ";" .. path .. "?.lua;"
end

function M.init(mode, filePath, searchPath)
    if "client" == mode then
        initClientPath(filePath)
        M.setRootPath(searchPath)
    end
end

function M.setRootPath(path)
    rootPath = path
end

-- return table { c2s = ... ,s2c = ...}
function M.getSprotoStrTable(nodeType)
    local sprotoCreator = require("sprotorpc.sproto.sprotoCreator")
    local sprotoConfig = require("sprotorpc.sproto.sprotoConfig")

    local config = sprotoConfig[nodeType]
    assert(config, "sprotoConfig nodeType Err "..nodeType)
    local sproto = sprotoCreator.createSproto(rootPath, config.protoFiles)
    return sproto
end

return M