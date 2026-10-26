@echo off

@REM set LUA_PATH=c:\lua-5.2.4
set LUA_PATH=c:\lua-5.3.6

cl /O2 /W3 /c /I%LUA_PATH%\include /DLUA_BUILD_AS_DLL *.c

set LIB=%LIB%;%LUA_PATH%\lib
@REM link /DLL /out:lpeg.dll *.obj lua52.lib
link /DLL /out:sproto.dll *.obj lua53.lib
