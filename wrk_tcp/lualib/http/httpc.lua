-- HTTP 客户端工具:构造原始 HTTP/1.1 请求报文
local httpc = {}

-- 构造 HTTP/1.1 请求报文:拼接请求行、header、content-length 与正文
local function request(method, host, path, header, content)
	local header_content = ""
	-- 拼装 header,缺失 host 时自动补上
    if header then
		if not header.host then
			header.host = host
		end
		for k,v in pairs(header) do
			header_content = string.format("%s%s:%s\r\n", header_content, k, v)
		end
	else
		header_content = string.format("host:%s\r\n",host)
	end

	-- 有正文则带上 content-length 与正文,否则长度置 0
	if content then
		return string.format("%s %s HTTP/1.1\r\n%scontent-length:%d\r\n\r\n%s", method, path, header_content, #content, content)
	else
		return string.format("%s %s HTTP/1.1\r\n%scontent-length:0\r\n\r\n", method, path, header_content)
	end
end

-- 发起 GET 请求,返回构造好的请求报文
function httpc.get(host, path)
	return request("GET", host, path)
end

-- 发起 POST 请求,带 header 与正文
function httpc.post(host, path, header, body)
	return request("POST", host, path, header, body)
end

return httpc
