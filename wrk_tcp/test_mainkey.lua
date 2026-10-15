-- 测试 mainkey 的 lpeg 捕获行为
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local lpeg = require "lpeg"
local P, C, S, R, V = lpeg.P, lpeg.C, lpeg.S, lpeg.R, lpeg.V
local alpha = R"az" + R"AZ" + "_"
local alnum = alpha + R"09"
local word = alpha * alnum ^ 0
local blank0 = (S" \t" + P"\n") ^ 0

-- 原项目
local mainkey_orig = "(" * blank0 * C((word ^ 0)) * blank0 * ")"
-- 我们之前
local mainkey_ours = "(" * blank0 * C(word) * blank0 * ")" -- 需要 word 至少 1 次

print("原项目 mainkey:")
print("  '()' ->", mainkey_orig:match("()"))
print("  '(name)' ->", mainkey_orig:match("(name)"))
print("  '' ->", mainkey_orig:match(""))

-- 在 sproto 语法中,*Type() 后面的 () 是 mainkey
-- C((word^0)) 对 '()' 捕获的是空字符串还是 nil?
local m = mainkey_orig:match("()")
print("  类型:", type(m))
print("  长度:", #m)

-- 如果是空字符串,那 f.key == "" 触发 map 模式
-- 但很多字段是非 map 用法,如 *ComArmyIdAndNum() 不是 map
-- 这意味着原项目对 mainkey 的处理可能有别的判断

-- 看 sprotoparser 中 f.key 如何从 AST 中取出
-- FIELD = namedpat("field", (name * blanks * tag * blank0 * ":" * blank0 * (C"*")^-1 * typename * (mainkey + decimal)^0))
-- mainkey 出现在 typename 之后,作为可选附加
-- 如果 mainkey 捕获空字符串,f.key = "" 就会触发 map 模式
-- 但 c2s.proto 中所有 *Type() 都这样,除非 c2s.proto 中 Type 只有 2 字段才算 map

-- 实际上,ComArenaTeamDetail 有 2 个字段,所以触发 map 模式是预期的
-- 但错误说 "must only have two fields",说明 c ~= 2
-- 让我检查 ComArenaTeamDetail 的 fields 表内容
print("\n--- 检查 fields 构建 ---")
local parser = require "sprotoparser"
local f = io.open("./lualib/protocol/c2s.proto")
local data = f:read("a")
f:close()
-- 只解析 ComArenaTeamDetail
local test_text = [[
.ComArenaTeamDetail {
    key 0: uint32
    value 1: *ComArenaTeamDetail()
}
]]
local ok, err = pcall(parser.parse, test_text)
print("ComArenaTeamDetail self-ref:", ok, err)
