import os
from os import path as op
import lupa
from lupa import LuaRuntime

lua = lupa.LuaRuntime(encoding=None, source_encoding='UTF-8', unpack_returned_tuples=True)

strLua = '''
package.cpath = package.cpath .. ";" .. "third_party/lua-crypt/?.dll"
package.cpath = package.cpath .. ";" .. "third_party/lpeg/?.dll"
package.cpath = package.cpath .. ";" .. "third_party/sproto/?.dll"
package.path = package.path .. ";" .. "./sprotolib/?.lua;" .. "../scCommon/lua/sprotorpc/?.lua;" .. "../scCommon/lua/?.lua;" 

local core = require "sproto.core"
local sproto = require "sproto"

local function save(bin, index)
	local sp = core.newproto(bin)
	core.saveproto(sp, index)
end

local function load(index)
	local sp = core.loadproto(index)
	return sproto.sharenew(sp)
end

local sprotoparser = require("sprotoparser")
local sprotoGettr = require("sproto.sprotoGetter")
local nodeType = "client"
local sprotos = sprotoGettr.getSprotoStrTable(nodeType)
local spb_c2s = sprotoparser.parse(sprotos.c2s)
local spb_s2c = sprotoparser.parse(sprotos.s2c)
save(spb_c2s, 1)
save(spb_s2c, 2)

hostOfClient = load(1):host("package")
senderOfClient = hostOfClient:attach(load(1))

local reqlogin = {account="wg"}
local msg = senderOfClient("reqlogin", reqlogin)
local sz = #msg
print(sz)
local sprotoType, sprotoName, requestBody, response = hostOfClient:dispatch(msg, sz)
print(requestBody.account)

function hex2str(hex)
	if (type(hex)~="string") then
		return nil,"hex2str invalid input type"
	end
	local index=1
	local ret=""
	for index=1,hex:len() do
		ret=ret..string.format("%02X",hex:sub(index):byte())
	end
 
	return ret
end

function str2hex(str)
	if (type(str)~="string") then
	    return nil,"str2hex invalid input type"
	end
	str=str:gsub("[%s%p]",""):upper()
	if(str:find("[^0-9A-Fa-f]")~=nil) then
	    return nil,"str2hex invalid input content"
	end
	if(str:len()%2~=0) then
	    return nil,"str2hex invalid input lenth"
	end
	local index=1
	local ret=""
	for index=1,str:len(),2 do
	    ret=ret..string.char(tonumber(str:sub(index,index+1),16))
	end

	return ret
end

function encode(msgName, msgData)
    local msg = senderOfClient(msgName, msgData)
    local sprotoType, sprotoName, requestBody, response = hostOfClient:dispatch(msg, sz)
    print(requestBody.createNewRole)
    return hex2str(msg)
end

function decode(msg)
    local sz = #msg
    local sprotoType, sprotoName, requestBody, response = hostOfClient:dispatch(msg, sz)
    return requestBody
end

function testArrayAndDict()
	return {1, 2, 3, 4, 5, [100] = "100", wg = "wg"}
end
'''

# lua.execute(strLua)

luaRuntime = LuaRuntime()
luaRuntime.execute(strLua)
g = luaRuntime.globals()

reqlogin = {
    "account" : "wg",
    "password" : "wg",
    "sdkToken" : "wg",
    "uid" : 1,
    "createNewRole" : True,
    "serverId" : 1,
    "clientInfo" : None,
}
strMsg = g.encode("reqlogin", reqlogin)
print(strMsg)

pmsg = strMsg.decode('hex')

data = g.decode(pmsg)
print(data.createNewRole)

tb = g.testArrayAndDict()
print(tb[1])
print(tb[5])
print(tb[100])
print(tb.wg)




















# lua.execute('sproto = require "sproto"')

# lua.execute('sprotocore = require "sproto.core"')

# lua.execute('local f = io.open("sproto/src/c2s.sproto") local bin = f:read "*a" f:close() print(#bin) sprotoOfC2S = sproto.new(bin)')
# lua.execute('local f = io.open("sproto/src/s2c.sproto") local bin = f:read "*a" f:close() sprotoOfS2C = sproto.new(bin)')

# lua.execute('local reqlogin = {account="wg"} local msg = sprotoOfC2S.encode(reqlogin) print(#msg)')

# # def encode4client(sprotoName, data):
