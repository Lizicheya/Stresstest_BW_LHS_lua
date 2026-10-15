@echo off
rem ============================================================
rem  LuaRocks admin launcher (project-local, Windows x64 + MinGW)
rem ============================================================
setlocal
set "LUAROCKS_ROOT=%~dp0.."
pushd "%LUAROCKS_ROOT%" >nul
set "LUAROCKS_ROOT=%CD%"
popd >nul

set "MSYSTEM="
set "PATH=%LUAROCKS_ROOT%\bin;E:\LuaYaCe\mingw64\mingw64\bin;%PATH%"
if exist "E:\Git\usr\bin\unzip.exe" set "PATH=%PATH%;E:\Git\usr\bin"

set "LUA_PATH="
set "LUA_CPATH="
set "LUA_PATH_5_3="
set "LUA_CPATH_5_3="
set "LUA_INIT="

"%LUAROCKS_ROOT%\bin\lua.exe" "%LUAROCKS_ROOT%\bin\luarocks-admin" %*
exit /b %ERRORLEVEL%
