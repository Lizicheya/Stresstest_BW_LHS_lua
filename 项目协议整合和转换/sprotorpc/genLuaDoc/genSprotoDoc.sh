#!/bin/bash
cd `dirname $0`;

python3 ./genSproto2LuaDoc.py ../sproto/game
if [ $? -ne 0 ]; then
    echo "\nError: genSproto2LuaDoc ./game failed\n"
    exit 1
fi

python3 ./genSproto2LuaDoc.py ../sproto/login
if [ $? -ne 0 ]; then
    echo "\nError: genSproto2LuaDoc ./login failed\n"
    exit 1
fi

echo "\nSproto Parse Success\n"