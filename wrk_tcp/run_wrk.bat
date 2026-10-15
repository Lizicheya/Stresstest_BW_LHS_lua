@echo off
setlocal
cd /d e:\LuaYaCe\wrk_tcp
if not exist logs mkdir logs

rem 注入项目内 LuaRocks 路径:让 wrk 内嵌的 Lua 也能从 LuaRocks 加载 rock
rem lualib/loader.lua 是把默认路径追加在后面(package.path .. path),不会覆盖项目自身模块
rem 结尾的 ;; 表示同时保留 Lua 编译时内置的默认搜索路径
set "LUA_PATH=E:\LuaYaCe\luarocks\share\lua\5.3\?.lua;E:\LuaYaCe\luarocks\share\lua\5.3\?\init.lua;;"
set "LUA_CPATH=E:\LuaYaCe\luarocks\lib\lua\5.3\?.dll;;"

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set ts=%%I
.\wrk.exe > "logs\wrk_run_%ts%.log" 2>&1
