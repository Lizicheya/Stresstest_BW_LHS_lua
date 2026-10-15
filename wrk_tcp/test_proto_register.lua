-- 直接测试 protocol.proto.register / load 链路
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local ok, err
local ok2, mod

ok, mod = pcall(require, "sprotoparser")
print("require sprotoparser:", ok, err)

ok, mod = pcall(require, "sproto.core")
print("require sproto.core:", ok, mod)

ok, mod = pcall(require, "sproto")
print("require sproto:", ok, mod)

ok, mod = pcall(require, "protocol.proto")
print("require protocol.proto:", ok, mod)
if not ok then return end

-- 测试 register
print("\n--- register test ---")
local config = dofile("game_bw/config.lua")
print("proto_index:", config.proto_index)
print("proto_files:", type(config.proto_files), #(config.proto_files or {}))

-- 检查 proto 文件存在
local fname = "./lualib/protocol/" .. config.proto_files[1] .. ".proto"
local f = io.open(fname)
print("proto file:", fname, f and "EXISTS" or "MISSING")
if f then f:close() end

-- 不用 pcall,直接调用,看真实错误
print("\n--- calling register ---")
local rok, rerr = pcall(mod.register, config.proto_index, table.unpack(config.proto_files))
print("register:", rok, rerr)

print("\n--- calling load ---")
local lok, lerr = pcall(mod.load, config.proto_index)
print("load:", lok, lerr)
