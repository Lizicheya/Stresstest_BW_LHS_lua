@echo off

@REM set LUA_PATH=c:\lua-5.2.4
set LUA_PATH=c:\lua-5.3.6

c:/vc/bin/cl.exe  /c /nologo /Ox /MD /W3 /GS- /DNDEBUG -DCYTHON_CLINE_IN_TRACEBACK=0 /DLUA_BUILD_AS_DLL /I%LUA_PATH%\include *.c

set LIB=%LIB%;%LUA_PATH%\lib
@REM link /DLL /out:sproto.dll *.obj lua52.lib
@REM set LIB=%LIB%;
c:/vc/bin/link.exe /DLL /out:crypt.dll lua-crypt.obj lua53.lib

