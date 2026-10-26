local gameSprotoConfig = require("sprotorpc.sproto.gameSprotoConfig")
local loginSprotoConfig = require("sprotorpc.sproto.loginSprotoConfig")
local clientSprotoConfig = require("sprotorpc.sproto.clientSprotoConfig")

local sprotoConfig = {
    game = {
        protoFiles = gameSprotoConfig,
        c2s = true,
        s2c = true,
    },
    login = {
        protoFiles = loginSprotoConfig,
        c2s = true,
        s2c = true,
    },
    client = {
        protoFiles = clientSprotoConfig,
        c2s = true,
        s2c = true,
    },
}

return sprotoConfig