-- 测试最小 sproto 文本,逐个排除可能的问题点
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"

local cases = {
    {"simple no comment",
        ".package {\n    type 0 : integer\n}\n"},
    {"with english comment",
        ".package {\n    type 0 : integer # proto\n}\n"},
    {"with chinese comment",
        ".package {\n    type 0 : integer # 协议\n}\n"},
    {"two fields no comment",
        ".package {\n    type 0 : integer\n    session 1 : integer\n}\n"},
    {"two fields with chinese comment",
        ".package {\n    type 0 : integer # 协议\n    session 1 : integer # client server\n}\n"},
    {"ud field chinese",
        ".package {\n    type 0 : integer\n    session 1 : integer\n    ud 2 : integer # response:错误码;推送:用户包确认\n}\n"},
    {"two types no comment",
        ".package {\n    type 0 : integer\n}\n\n.ComPath {\n    x 0 : integer\n}\n"},
    {"two types with chinese comment",
        ".package {\n    type 0 : integer # 协议\n}\n\n.ComPath {\n    x 0 : integer # 路径\n}\n"},
}

for _, c in ipairs(cases) do
    local ok, err = pcall(parser.parse, c[2])
    print(string.format("[%s] ok=%s err=%s", c[1], tostring(ok), tostring(err)))
end
