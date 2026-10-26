del /Q sproto\src\c2s.sproto
del /Q sproto\src\s2c.sproto

del /Q sproto\c2s.spb
del /Q sproto\s2c.spb

del /Q sproto_dump\c2s.sproto
del /Q sproto_dump\s2c.sproto

del /Q sproto_dump\c2s.spb
del /Q sproto_dump\s2c.spb

lua\luaexe.exe writeSproto.lua

echo begin
cd sproto_dump
echo enter src
COPY /Y ..\sproto\src\c2s.sproto c2s.sproto
..\lua\luaexe.exe sprotodump.lua -spb c2s.sproto -o c2s.spb
COPY /Y c2s.spb ..\sproto\c2s.spb

COPY /Y ..\sproto\src\s2c.sproto s2c.sproto
..\lua\luaexe.exe sprotodump.lua -spb s2c.sproto -o s2c.spb
COPY /Y s2c.spb ..\sproto\s2c.spb

cd ..