-- 局部缓存常用内置函数以提升访问性能
local print = print
local tconcat = table.concat
local tinsert = table.insert
local srep = string.rep
local type = type
local pairs = pairs
local tostring = tostring
local next = next

-- 通用工具模块
local M = {}

-- 递归打印表内容,处理循环引用,便于调试输出
function M.dumptable(root)
    if not root then
        return ""
    end

    -- cache 记录已访问过的表,用于检测循环引用
    local cache = {  [root] = "." }
	-- 内部递归函数:_dump(t, space, name)
	local function _dump(t,space,name)
		local temp = {}
		for k,v in pairs(t) do
			local key = tostring(k)
			if cache[v] then
				-- 已访问过的表,标注其路径
				tinsert(temp,"+" .. key .. " {" .. cache[v].."}")
			elseif type(v) == "table" then
				-- 嵌套表,递归打印
				local new_key = name .. "." .. key
				cache[v] = new_key
				tinsert(temp,"+" .. key .. _dump(v,space .. (next(t,k) and "|" or " " ).. srep(" ",#key),new_key))
			else
				-- 叶子节点,直接输出值
				tinsert(temp,"+" .. key .. " [" .. tostring(v).."]")
			end
		end
		return tconcat(temp,"\n"..space)
    end
    
	print(_dump(root, "","") or "")
end

return M
