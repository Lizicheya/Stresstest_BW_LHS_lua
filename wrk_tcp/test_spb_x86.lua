-- 用原项目 x86 lua.exe + x86 sproto.dll 测试 spb
package.cpath = "E:/LuaYaCe/PressureTest_BW_LHS/pythonTest1/sprotoGen/lua/?.dll;" .. package.cpath

local core = require "sproto.core"
print("core loaded")

local f = io.open("E:/LuaYaCe/PressureTest_BW_LHS/pythonTest1/sprotoGen/sproto/c2s.spb", "rb")
local bin = f:read("a")
f:close()
print("spb size:", #bin)

local ok, sp = pcall(core.newproto, bin)
print("newproto from spb:", ok, sp)
if ok and sp then
    print("SUCCESS with x86 sproto.dll!")
end
