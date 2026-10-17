@echo off
rem 单账号沙盘联调:真实登录 -> 进场景 -> 设置 AOI -> 搜怪 -> 出征打怪
rem
rem 用法:
rem   1) 直接双击:使用 robot\ycf_a.txt 里的第 1 个账号
rem   2) 指定账号:先在命令行 set WRK_TEST_ACCOUNT=A003 再运行本批处理
rem   3) 其它可调项(账号序号/怪等级/出征次数/超时)见
rem      game_bw\test\test_find_attack_monster.lua 文件头注释
rem
rem 注意:本用例强制 1 连接 / 1 线程,不走压测任务调度,也不做账号轮换。

cd /d e:\LuaYaCe\wrk_tcp
if not exist logs mkdir logs

rem ---- 用例入口与账号文件(未设置时用这里默认值) ----
if not defined WRK_MAIN_ENTRY set WRK_MAIN_ENTRY=test.test_find_attack_monster
if not defined WRK_TEST_ACCOUNT_FILE set WRK_TEST_ACCOUNT_FILE=robot/ycf_a.txt
if not defined WRK_TEST_DURATION set WRK_TEST_DURATION=180

rem 取系统时间戳:优先 wmic,较新系统无 wmic 时回退 powershell(与 run_wrk.bat 一致)
set ts=
for /f %%a in ('wmic os get localdatetime 2^>nul ^| find "."') do set ts=%%a
if not defined ts for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMddHHmmss"') do set ts=%%a

set logfile=logs\test_find_attack_%ts:~0,8%_%ts:~8,6%.log
echo.
echo 单账号沙盘联调
echo   入口    : %WRK_MAIN_ENTRY%
echo   账号文件: %WRK_TEST_ACCOUNT_FILE%
echo   指定账号: %WRK_TEST_ACCOUNT%  (为空则取第 1 条)
echo   日志    : e:\LuaYaCe\wrk_tcp\%logfile%
echo.
.\wrk.exe > "%logfile%" 2>&1
echo.
echo 联调结束,结果见: e:\LuaYaCe\wrk_tcp\%logfile%
