-- 用预编译的 c2s.spb 测试 sproto_create
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local core = require "sproto.core"
print("core loaded")

-- 读取预编译的 c2s.spb
local f = io.open("E:/LuaYaCe/PressureTest_BW_LHS/pythonTest1/sprotoGen/sproto/c2s.spb", "rb")
if not f then
    print("cannot open c2s.spb")
    os.exit(1)
end
local bin = f:read("a")
f:close()
print("spb size:", #bin)

-- 直接 newproto
local ok, sp = pcall(core.newproto, bin)
print("newproto from spb:", ok, sp)
if ok and sp then
    print("SUCCESS! spb is compatible with sproto.dll")
    -- 测试 saveproto/loadproto
    local ok2 = pcall(core.saveproto, sp, 2)
    print("saveproto index 2:", ok2)
    local ok3, sp2 = pcall(core.loadproto, 2)
    print("loadproto index 2:", ok3, sp2)
end
