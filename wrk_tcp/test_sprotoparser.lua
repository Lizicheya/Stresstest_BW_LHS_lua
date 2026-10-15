-- 测试 sprotoparser 对 ActivityAgenda 的解析
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"
local f = io.open("./lualib/protocol/c2s.proto", "rb")
local data = f:read("a")
f:close()

-- 用 pcall 捕获错误
local ok, result = pcall(parser.parse, data)
if not ok then
    print("parse error:", result)
    os.exit(1)
end
print("parse OK, bin len:", #result)

-- 检查 adjust 阶段是否正确
-- 直接调用内部函数(但 sprotoparser 只导出 parse)
-- 我们用 sproto.core 测试
local core = require "sproto.core"
local ok2, sp = pcall(core.newproto, result)
print("newproto:", ok2, sp)
if not ok2 or sp == nil then
    print("newproto failed, testing with debug...")
    -- 尝试 dump 解析后的结构
    -- sprotoparser 内部有 adjust 函数,但未导出
    -- 我们看 bin 的二进制结构
    -- 找 ActivityAgenda 类型在 bin 中的位置

    -- 实际上,问题可能是 sprotoparser 的 lpeg 版本不对
    -- 检查 lpeg
    local lpeg = require "lpeg"
    print("lpeg version:", lpeg.version and lpeg.version() or "unknown")
end
