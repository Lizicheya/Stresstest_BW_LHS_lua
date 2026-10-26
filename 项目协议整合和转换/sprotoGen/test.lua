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


--将16进制串转换为字符串
function hex2str(hex)
	--判断输入类型
	if (type(hex)~="string") then
		return nil,"hex2str invalid input type"
	end
	--拼接字符串
	local index=1
	local ret=""
	for index=1,hex:len() do
		ret=ret..string.format("%02X",hex:sub(index):byte())
	end
 
	return ret
end

--将字符串按格式转为16进制串
function str2hex(str)
	--判断输入类型	
	if (type(str)~="string") then
	    return nil,"str2hex invalid input type"
	end
	--滤掉分隔符
	str=str:gsub("[%s%p]",""):upper()
	--检查内容是否合法
	if(str:find("[^0-9A-Fa-f]")~=nil) then
	    return nil,"str2hex invalid input content"
	end
	--检查字符串长度
	if(str:len()%2~=0) then
	    return nil,"str2hex invalid input lenth"
	end
	--拼接字符串
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

local strMsg = encode("reqlogin", reqlogin)
print(strMsg)