@echo off
setlocal
set "LUAROCKS_SYSCONFDIR=E:/LuaYaCe/luarocks/etc/luarocks"
"E:\LuaYaCe\luarocks\bin\lua.exe" -e "package.path=\"E:\\LuaYaCe\\luarocks\\share\\lua\\5.3\\?.lua;E:\\LuaYaCe\\luarocks\\share\\lua\\5.3\\?\\init.lua;\"..package.path;package.cpath=\"E:\\LuaYaCe\\luarocks\\lib\\lua\\5.3\\?.dll;\"..package.cpath;local k,l,_=pcall(require,'luarocks.loader') _=k and l.add_context('lua-cjson','2.1.0.10-1')" "E:\LuaYaCe\luarocks\lib\luarocks\rocks-5.3\lua-cjson\2.1.0.10-1\bin\lua2json" %*
exit /b %ERRORLEVEL%
