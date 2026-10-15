-- 调试 sproto_create 失败原因
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"
local core = require "sproto.core"

local f = io.open("./lualib/protocol/c2s.proto", "rb")
local data = f:read("a")
f:close()

local bin = parser.parse(data)
print("bin len:", #bin)
print("first 16 bytes hex:")
local hex = ""
for i = 1, 16 do
    hex = hex .. string.format("%02X ", string.byte(bin, i))
end
print(hex)

-- struct_field 期望:前 2 字节是字段数 fn
-- fn 应该是 1 或 2(对应 typedata / protocoldata)
local fn = string.byte(bin, 1) + string.byte(bin, 2) * 256
print("fn (field count from first 2 bytes):", fn)

-- 如果 fn > 2,create_from_bundle 返回 NULL
-- 这说明 sprotoparser 输出的二进制格式不对

-- 对比原项目 sproto.dll 能否解析
-- 但我们 sproto.dll 就是用同一个源码编译的...

-- 让我看 sproto_create 源码期望的格式
-- create_from_bundle:
--   fn = struct_field(stream, sz)  -- stream 是 bin, sz 是长度
--   struct_field 内部:fn = toword(stream) -- 取前 2 字节
--   if (fn < 0 || fn > 2) return NULL

-- 所以 fn 应该是 0、1 或 2
-- 我们的 fn 是多少?
print("expected fn: 0, 1, or 2")
print("actual fn:", fn)
if fn > 2 then
    print("ERROR: fn > 2, this is why sproto_create returns NULL")
    print("This means the sprotoparser output is in wrong format")
end
