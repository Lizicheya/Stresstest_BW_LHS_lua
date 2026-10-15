-- 测试 protocol.proto.register + load 链路
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local proto_loader = require "protocol.proto"
local core = require "sproto.core"

-- 检查 core 的函数
print("core.saveproto:", type(core.saveproto))
print("core.loadproto:", type(core.loadproto))
print("core.newproto:", type(core.newproto))

-- 直接调用 register
print("\n--- register ---")
local config = dofile("game_bw/config.lua")
local ok, err = pcall(proto_loader.register, config.proto_index, table.unpack(config.proto_files))
print("register result:", ok, err)

-- 直接测试 core 层
print("\n--- direct core test ---")
local parser = require "sprotoparser"
local f = io.open("./lualib/protocol/c2s.proto", "rb")
local data = f:read("a")
f:close()
local bin = parser.parse(data)
print("parsed bin len:", #bin)

local ok2, csp = pcall(core.newproto, bin)
print("newproto:", ok2, csp)
if not ok2 then return end

-- 手动 saveproto
print("\n--- saveproto ---")
local ok3, err3 = pcall(core.saveproto, csp, 1)
print("saveproto:", ok3, err3)

-- loadproto
print("\n--- loadproto ---")
local ok4, loaded = pcall(core.loadproto, 1)
print("loadproto:", ok4, loaded)
if ok4 and loaded then
    print("loaded type:", type(loaded))
end
