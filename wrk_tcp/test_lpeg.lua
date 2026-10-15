package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local ok, err = pcall(require, "lpeg")
print("require lpeg:", ok, err)
if ok then
    local lpeg = require "lpeg"
    print("lpeg version:", lpeg.version and lpeg.version() or "?")
    -- 测试简单匹配
    local P = lpeg.P
    local pattern = P"hello"
    print("match 'hello world':", pattern:match("hello world"))
    print("match 'world':", pattern:match("world"))
end
