
package.path = package.path .. ";" .. "./sprotolib/?.lua;" .. "../scCommon/lua/sprotorpc/?.lua;" .. "../scCommon/lua/?.lua;"

local sprotoGettr = require("sproto.sprotoGetter")

local nodeType = "client"
local sprotos = sprotoGettr.getSprotoStrTable(nodeType)

local f = io.open("./sproto/src/c2s.sproto", "w")
f:write(sprotos.c2s)
f:close()

f = io.open("./sproto/src/s2c.sproto", "w")
f:write(sprotos.s2c)
f:close()