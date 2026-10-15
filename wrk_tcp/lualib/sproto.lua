local core = require "sproto.core"
local assert = assert

-- sproto Lua 封装:提供类型/协议查询、编解码以及 host 端的收发能力
local sproto = {}
-- host 端封装:负责请求/响应的会话管理与消息拼装
local host = {}

-- 弱引用元表,缓存不阻止被回收
local weak_mt = { __mode = "kv" }
local sproto_mt = { __index = sproto }
-- 共享对象元表(无 __gc,由外部管理生命周期)
local sproto_nogc = { __index = sproto }
local host_mt = { __index = host }

-- 析构:释放底层 cproto 对象
function sproto_mt:__gc()
	core.deleteproto(self.__cobj)
end

-- 从二进制创建 sproto 对象(自带 __gc)
function sproto.new(bin)
	local cobj = assert(core.newproto(bin))
	local self = {
		__cobj = cobj,
		__tcache = setmetatable( {} , weak_mt ),  -- 类型缓存
		__pcache = setmetatable( {} , weak_mt ),  -- 协议缓存
	}
	return setmetatable(self, sproto_mt)
end

-- 从已存在的 cobj 创建共享 sproto 对象(无 __gc)
function sproto.sharenew(cobj)
	local self = {
		__cobj = cobj,
		__tcache = setmetatable( {} , weak_mt ),
		__pcache = setmetatable( {} , weak_mt ),
	}
	return setmetatable(self, sproto_nogc)
end

-- 从 sproto 文本创建对象(语法解析)
function sproto.parse(ptext)
	local parser = require "sprotoparser"
	local pbin = parser.parse(ptext)
	return sproto.new(pbin)
end

-- 创建 host:基于某个 package 类型构造会话宿主
function sproto:host( packagename )
	packagename = packagename or  "package"
	local obj = {
		__proto = self,
		__package = assert(core.querytype(self.__cobj, packagename), "type package not found"),
		__session = {},
	}
	return setmetatable(obj, host_mt)
end

-- 查询类型(带缓存)
local function querytype(self, typename)
	local v = self.__tcache[typename]
	if not v then
		v = assert(core.querytype(self.__cobj, typename), "type not found")
		self.__tcache[typename] = v
	end

	return v
end

-- 判断类型是否存在
function sproto:exist_type(typename)
	local v = self.__tcache[typename]
	if not v then
		return core.querytype(self.__cobj, typename) ~= nil
	else
		return true
	end
end

-- 编码:typename -> 二进制
function sproto:encode(typename, tbl)
	local st = querytype(self, typename)
	return core.encode(st, tbl)
end

-- 解码:typename + 二进制 -> 表
function sproto:decode(typename, ...)
	local st = querytype(self, typename)
	return core.decode(st, ...)
end

-- 打包编码:编码后再 pack
function sproto:pencode(typename, tbl)
	local st = querytype(self, typename)
	return core.pack(core.encode(st, tbl))
end

-- 打包解码:先 unpack 再 decode
function sproto:pdecode(typename, ...)
	local st = querytype(self, typename)
	return core.decode(st, core.unpack(...))
end

-- 查询协议(带缓存),返回 {request,response,name,tag}
local function queryproto(self, pname)
	local v = self.__pcache[pname]
	if not v then
		local tag, req, resp = core.protocol(self.__cobj, pname)
		assert(tag, pname .. " not found")
		-- 支持用数字 tag 作为 key 查询
		if tonumber(pname) then
			pname, tag = tag, pname
		end
		v = {
			request = req,
			response =resp,
			name = pname,
			tag = tag,
		}
		self.__pcache[pname] = v
		self.__pcache[tag]  = v
	end

	return v
end

-- 判断协议是否存在
function sproto:exist_proto(pname)
	local v = self.__pcache[pname]
	if not v then
		return core.protocol(self.__cobj, pname) ~= nil
	else
		return true
	end
end

-- 请求编码:返回编码后的请求体与协议 tag
function sproto:request_encode(protoname, tbl)
	local p = queryproto(self, protoname)
	local request = p.request
	if request then
		return core.encode(request,tbl) , p.tag
	else
		return "" , p.tag
	end
end

-- 响应编码:返回编码后的响应体与协议 tag
function sproto:response_encode(protoname, tbl)
	local p = queryproto(self, protoname)
	local response = p.response
	if response then
		return core.encode(response,tbl), p.tag
	else
		return "" , p.tag
	end
end

-- 获取协议 tag
function sproto:get_tag(type, protoname)
	local p = queryproto(self, protoname)
	if p then
		return p.tag
	end
end

-- 请求解码:返回请求体内容与协议名
function sproto:request_decode(protoname, ...)
	local p = queryproto(self, protoname)
	local request = p.request
	if request then
		return core.decode(request,...) , p.name
	else
		return nil, p.name
	end
end

-- 响应解码:返回响应体内容与协议名
function sproto:response_decode(protoname, ...)
	local p = queryproto(self, protoname)
	local response = p.response
	if response then
		return core.decode(response,...), p.name
	else
		return nil, p.name
	end
end

-- 直接暴露底层 pack/unpack
sproto.pack = core.pack
sproto.unpack = core.unpack

-- 取类型的默认值;type 指定 REQUEST/RESPONSE 时取协议字段默认值
function sproto:default(typename, type)
	if type == nil then
		return core.default(querytype(self, typename))
	else
		local p = queryproto(self, typename)
		if type == "REQUEST" then
			if p.request then
				return core.default(p.request)
			end
		elseif type == "RESPONSE" then
			if p.response then
				return core.default(p.response)
			end
		else
			error "Invalid type"
		end
	end
end

-- 复用 header 临时表,避免频繁分配
local header_tmp = {}

-- 生成响应闭包:用于在 dispatch 时回包,封装 header(session/ud)与 response 内容
local function gen_response(self, response, session)
	return function(args, ud)
		header_tmp.type = nil
		header_tmp.session = session
		header_tmp.ud = ud
		local header = core.encode(self.__package, header_tmp)
		if response then
			local content = core.encode(response, args)
			return core.pack(header .. content)
		else
			return core.pack(header)
		end
	end
end

-- 派发消息:区分请求与响应,返回对应类型与内容/回包闭包
function host:dispatch(...)
	local bin = core.unpack(...)
	header_tmp.type = nil
	header_tmp.session = nil
	header_tmp.ud = nil
	-- 解码 header,得到消息头与剩余内容
	local header, size = core.decode(self.__package, bin, header_tmp)
	local content = bin:sub(size + 1)
	if header.type then
		-- 请求分支:解码请求体并附带响应闭包
		local proto = queryproto(self.__proto, header.type)
		local result
		if proto.request then
			result = core.decode(proto.request, content)
		end
		if header_tmp.session then
			return "REQUEST", proto.name, result, gen_response(self, proto.response, header_tmp.session), header.ud
		else
			return "REQUEST", proto.name, result, nil, header.ud
		end
	else
		-- 响应分支:根据 session 找到对应请求,解码响应体
		local session = assert(header_tmp.session, "session not found")
		local response = assert(self.__session[session], "Unknown session")
		self.__session[session] = nil
		if response == true then
			return "RESPONSE", session, nil, header.ud
		else
			local result = core.decode(response, content)
			return "RESPONSE", session, result, header.ud
		end
	end
end

-- 生成 attach 闭包:用于发起请求,自动拼装 header + 内容并登记 session
function host:attach(sp)
	return function(name, args, session, ud)
		local proto = queryproto(sp, name)
		header_tmp.type = proto.tag
		header_tmp.session = session
		header_tmp.ud = ud
		local header = core.encode(self.__package, header_tmp)

		-- 登记该 session 期待的响应类型
		if session then
			self.__session[session] = proto.response or true
		end

		-- 拼装请求内容
		if proto.request then
			local content = core.encode(proto.request, args)
			return core.pack(header ..  content)
		else
			return core.pack(header)
		end
	end
end

return sproto
