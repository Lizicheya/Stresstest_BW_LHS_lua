-- 用原项目 sprotoparser,追踪 f.key 在 *Type() 场景下的值
package.path = "E:/LuaYaCe/PressureTest_BW_LHS/pythonTest1/sprotoGen/sprotolib/?..lua;lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

-- 先加载原项目 sprotoparser
package.loaded["sprotoparser"] = nil
local parser = require "sprotoparser"

-- 给 parser.parse 包一层,追踪调用
-- 实际上 sprotoparser 的 parse 函数内部构建 AST,我们看 AST 结构
-- 直接调用 parser.parse 并看返回值
local test_text = [[
.ComArmyIdAndNum {
    id 0: uint32
    num 1: uint32
}
.ComSyncDataArmy {
    news 1: *ComArmyIdAndNum()
    changes 2: *ComArmyIdAndNum()
}
]]
local ok, result = pcall(parser.parse, test_text)
print("parse:", ok)
print("result type:", type(result))
print("result len:", #result)

-- 看 result 的二进制内容(前 100 字节十六进制)
local hex = ""
for i = 1, math.min(100, #result) do
    hex = hex .. string.format("%02X ", string.byte(result, i))
end
print("hex:", hex)

-- 用 sproto.core 加载这个二进制看是否能 newproto
local core = require "sproto.core"
local ok2, sp = pcall(core.newproto, result)
print("newproto:", ok2, sp)
if ok2 then
    -- 尝试 querytype
    local ok3, t = pcall(core.querytype, sp, "ComArmyIdAndNum")
    print("querytype ComArmyIdAndNum:", ok3, t)
    local ok4, t2 = pcall(core.querytype, sp, "ComSyncDataArmy")
    print("querytype ComSyncDataArmy:", ok4, t2)
end
