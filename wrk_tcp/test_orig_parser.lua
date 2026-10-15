-- 用原项目的 sprotoparser 测试解析我们的 c2s.proto
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

-- 临时把原项目 sprotoparser 放到搜索路径最前
package.path = "E:/LuaYaCe/PressureTest_BW_LHS/pythonTest1/sprotoGen/sprotolib/?.lua;" .. package.path

-- 强制重新加载
package.loaded["sprotoparser"] = nil
local parser = require "sprotoparser"
print("using parser from:", package.searchpath and package.searchpath("sprotoparser", package.path) or "?")

local f = io.open("./lualib/protocol/c2s.proto")
local data = f:read("a")
f:close()

local ok, err = pcall(parser.parse, data)
print("parse result:", ok, err)
