local parser = require "sprotoparser"
local core = require "sproto.core"
local sproto = require "sproto"

-- sproto 协议加载器:负责把 .proto 文本注册并加载成可用对象
local loader = {}

-- 注册协议:合并多个 .proto 文件,解析后存入 index 槽位
function loader.register(index, ...)
	local proto_name = {...}
	local proto_text = ""

	-- 依次读取所有 .proto 文件内容并拼接
	for i = 1, #proto_name do
		local filename = "./lualib/protocol/"..proto_name[i]..".proto"
		local f = assert(io.open(filename), "Can't open sproto file")
		local data = f:read("a")
		f:close()
		proto_text = proto_text..data
	end

	-- 解析文本为 sproto 二进制结构
	local ok, sp = pcall(parser.parse, proto_text)
	if not ok then
	    error("sproto parse fail in "..table.concat(proto_name, ",").." , "..sp)
	    return
	end

	-- 创建并保存到指定 index 槽位
	local csp = core.newproto(sp)
	core.saveproto(csp, index)
end

-- 加载已注册协议:按 index 取出并返回可用的 sproto 对象(无 __gc)
function loader.load(index)
	local csp = core.loadproto(index)
	--  no __gc in metatable
	return sproto.sharenew(csp)
end

return loader
