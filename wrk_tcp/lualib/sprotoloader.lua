local parser = require "sprotoparser"
local core = require "sproto.core"
local sproto = require "sproto"

-- sproto 协议加载器(单文件版):从单个 .proto 文件注册并加载协议
local loader = {}

-- 从 .proto 文件注册协议到指定 index 槽位
function loader.register(filename, index)
	local f = assert(io.open(filename), "Can't open sproto file")
	local data = f:read "a"
	f:close()
	local sp = core.newproto(parser.parse(data))
	core.saveproto(sp, index)
end

-- 从已解析的二进制注册协议到指定 index 槽位
function loader.save(bin, index)
	local sp = core.newproto(bin)
	core.saveproto(sp, index)
end

-- 加载已注册协议:按 index 取出并返回可用的 sproto 对象(无 __gc)
function loader.load(index)
	local sp = core.loadproto(index)
	--  no __gc in metatable
	return sproto.sharenew(sp)
end

return loader
