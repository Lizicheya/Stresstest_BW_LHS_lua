-- 精确定位 c2s.proto 的语法错误行
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"
local f = assert(io.open("./lualib/protocol/c2s.proto", "rb"))
local data = f:read("a")
f:close()

-- 完整文件解析,看错误行号
local ok, err = pcall(parser.parse, data)
print("full file parse:", ok)
print("err:", err)

-- 按实际行号切分(保留空行)
local actual_lines = {}
for line in data:gmatch("([^\r\n]*)\r?[\n]") do
    actual_lines[#actual_lines + 1] = line
end
print("actual lines (with empty):", #actual_lines)

-- 计算非空行到实际行号的映射
local nonempty_to_actual = {}
local nonempty_count = 0
for i = 1, #actual_lines do
    local line = actual_lines[i]
    if line:match("%S") then  -- 有非空白字符
        nonempty_count = nonempty_count + 1
        nonempty_to_actual[nonempty_count] = i
    end
end
print("nonempty lines:", nonempty_count)

-- sprotoparser 的 count_lines 是按 \n 计数,所以行号对应实际行号
-- 错误 "line (57)" 对应实际文件第 57 行
print("\n--- actual line 57 ---")
print(actual_lines[57])
print("--- actual line 56 ---")
print(actual_lines[56])
print("--- actual line 58 ---")
print(actual_lines[58])

-- 显示 50-70 行
print("\n--- lines 50-70 ---")
for i = 50, 70 do
    if actual_lines[i] then
        print(string.format("%3d: %s", i, actual_lines[i]))
    end
end
