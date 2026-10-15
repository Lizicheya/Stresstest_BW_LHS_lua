-- LuaSocket 安装验证脚本
-- 在 wrk_tcp 目录下运行:lua.exe test_luasocket.lua

-- 复用 loader 的路径配置
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local function check(name)
    local ok, mod = pcall(require, name)
    print(string.format("[%-15s] %s", name, ok and "OK" or ("FAIL: " .. tostring(mod))))
    return ok
end

print("=== LuaSocket require 测试 ===")
check("socket")
check("socket.core")
check("mime")
check("mime.core")
check("socket.http")
check("socket.url")
check("socket.headers")
check("socket.tp")
check("ltn12")

print("\n=== 实际 HTTP 请求测试(可选) ===")
local http = require("socket.http")
local res, code = http.request("http://www.example.com")
if res then
    print("HTTP request OK, body len:", #res)
else
    print("HTTP request fail:", code)
end
