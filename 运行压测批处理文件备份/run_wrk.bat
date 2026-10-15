@echo off
cd /d e:\LuaYaCe\wrk_tcp
if not exist logs mkdir logs
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set ts=%%I
.\wrk.exe > "logs\wrk_run_%ts%.log" 2>&1