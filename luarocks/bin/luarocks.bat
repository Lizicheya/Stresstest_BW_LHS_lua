@echo off
rem ============================================================
rem  LuaRocks launcher (project-local, Windows x64 + MinGW)
rem
rem  Usage:
rem    luarocks.bat install luafilesystem
rem    luarocks.bat list
rem    luarocks.bat show luafilesystem
rem    luarocks.bat --help
rem
rem  Rocks tree is fixed to this project: E:\LuaYaCe\luarocks
rem  Toolchain: E:\LuaYaCe\mingw64 (gcc / mingw32-make)
rem ============================================================
setlocal
set "LUAROCKS_ROOT=%~dp0.."
pushd "%LUAROCKS_ROOT%" >nul
set "LUAROCKS_ROOT=%CD%"
popd >nul

rem Force LuaRocks into its "mingw" platform branch
rem (mingw32-make + x86_64-w64-mingw32-gcc)
set "MSYSTEM="

rem PATH: this bin (lua53.dll) + MinGW toolchain + Git POSIX tools (unzip/tar/md5sum)
set "PATH=%LUAROCKS_ROOT%\bin;E:\LuaYaCe\mingw64\mingw64\bin;%PATH%"
if exist "E:\Git\usr\bin\unzip.exe" set "PATH=%PATH%;E:\Git\usr\bin"

rem Drop external Lua env vars to keep the interpreter clean
set "LUA_PATH="
set "LUA_CPATH="
set "LUA_PATH_5_3="
set "LUA_CPATH_5_3="
set "LUA_INIT="

"%LUAROCKS_ROOT%\bin\lua.exe" "%LUAROCKS_ROOT%\bin\luarocks" %*
exit /b %ERRORLEVEL%
