-- sproto/netpack/cjson 加载验证脚本
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local function check(name)
    local ok, mod = pcall(require, name)
    print(string.format("[%-15s] %s", name, ok and "OK" or ("FAIL: " .. tostring(mod))))
    return ok
end

print("=== C 扩展加载测试 ===")
check("sproto")
check("netpack")
check("cjson")
check("cjson.util")

-- 简单功能测试
print("\n=== 功能测试 ===")
local sprotoparser = require "sprotoparser"
local sproto = require "sproto"
local schema = [[
.Person {
    name 0 : string
    age 1 : integer
}
]]
local bin = sprotoparser.parse(schema)
local sp = sproto.new(bin)
local data = { name = "test", age = 18 }
local enc = sp:encode("Person", data)
print("sproto encode bytes:", #enc)
local dec = sp:decode("Person", enc)
print("sproto decode name:", dec.name, "age:", dec.age)

local cjson = require "cjson"
local jsonstr = cjson.encode({ a = 1, b = { x = 2 } })
print("cjson encode:", jsonstr)
local tbl = cjson.decode(jsonstr)
print("cjson decode b.x:", tbl.b.x)
