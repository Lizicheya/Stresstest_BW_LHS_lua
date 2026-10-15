-- 启动加载器:根据 config.lua 的 game_module 配置动态选择业务目录并加载主模块

-- 先读取根目录 config.lua 取得 game_module / main_entry
-- 注意:C 层 wrk.c 已用独立 lua_State 读取过 config.lua 提取 connections/threads 等字段,
-- 这里在 loader 的 lua_State 中重新 dofile 一次以取得业务模块切换字段。
local cfg = dofile("config.lua")
local game_module = cfg.game_module or "game"
local main_entry = cfg.main_entry or "main"

-- 设置 Lua 模块搜索路径:包含 lualib 与所选业务目录
-- 例如 game_module == "game_bw" 时,game_bw/?.lua 会被优先搜索,
-- 其中 game_bw/config.lua / game_bw/util.lua 等会覆盖根 config.lua 的同名模块
-- lualib/?/init.lua 让 require 'socket' 找到 lualib/socket/init.lua(LuaSocket)
-- lualib/?.lua 已覆盖 require 'socket.http' -> lualib/socket/http.lua
package.path = "lualib/?.lua;lualib/?/init.lua;" .. game_module .. "/?.lua;" .. game_module .. "/?/init.lua;" .. package.path
-- 设置 C 模块搜索路径:Windows 优先 .dll,Linux 兼容 .so
-- lualib/?.dll 让 require 'socket.core' 找到 lualib/socket/core.dll(LuaSocket)
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

-- 加载类工厂(全局函数 class)
require "class"

-- 加载并返回压测主模块(由 main_entry 指定,如 "main" 或 "main_bw")
local main = require(main_entry)
return main
