-- 逐段测试 c2s.proto 解析,定位语法错误行
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"
local f = assert(io.open("./lualib/protocol/c2s.proto"))
local data = f:read("a")
f:close()

-- 把内容按行切分
local lines = {}
for line in data:gmatch("[^\r\n]+") do
    lines[#lines + 1] = line
end
print("total lines:", #lines)

-- 二分法查找出错位置:从 N 行开始解析,逐步增加
local function try_parse(n)
    local sub = table.concat(lines, "\n", 1, n) .. "\n"
    local ok, err = pcall(parser.parse, sub)
    return ok, err
end

-- 先看完整文件错误行
local ok, err = try_parse(#lines)
print("full file:", ok, err)

-- 二分:从 1 行开始逐步增加,找到第一个失败点
local last_ok = 0
for i = 10, #lines, 5 do
    local ok = try_parse(i)
    if not ok then
        -- 在 last_ok..i 之间细查
        for j = math.max(last_ok + 1, i - 4), i do
            local ok2, err2 = try_parse(j)
            if not ok2 then
                print(string.format("FAIL at line %d: %s", j, err2))
                print("  content:", lines[j])
                return
            end
        end
    end
    last_ok = i
end
print("no fail found in step 5")
