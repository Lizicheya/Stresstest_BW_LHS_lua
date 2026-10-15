e:\LuaYaCe\run_wrk.bat
@echo off
rem 压测运行脚本: 日志输出到 wrk_tcp\logs 目录,时间戳自动命名,免手动改编号
rem 用法: 双击运行,或在任意终端执行 e:\LuaYaCe\run_wrk.bat

cd /d e:\LuaYaCe\wrk_tcp
if not exist logs mkdir logs

rem 取系统时间戳: 优先 wmic(输出形如 20261012183045.xxx+480),较新系统无 wmic 时回退 powershell
rem 注意: .bat 中循环变量必须用双 %%a(CMD 直接粘贴才是单 %)
set ts=
for /f %%a in ('wmic os get localdatetime 2^>nul ^| find "."') do set ts=%%a
if not defined ts for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set ts=%%a

set logfile=logs\wrk_run_%ts:~0,8%_%ts:~8,6%.log
echo 压测日志输出: e:\LuaYaCe\wrk_tcp\%logfile%
.\wrk.exe > "%logfile%" 2>&1
echo 压测结束