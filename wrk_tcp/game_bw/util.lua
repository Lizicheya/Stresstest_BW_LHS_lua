-- game_bw 通用工具模块
-- 提供表打印、字符串处理、随机数等通用辅助函数

local M = {}

-- 局部缓存常用内置函数以提升访问性能
local print, tconcat, tinsert, srep, type, pairs, tostring, next =
    print, table.concat, table.insert, string.rep, type, pairs, tostring, next

-- 递归打印表内容,处理循环引用,便于调试输出
function M.dumptable(root)
    if not root then return "" end

    -- cache 记录已访问过的表,用于检测循环引用
    local cache = { [root] = "." }
    -- 内部递归函数:_dump(t, space, name)
    local function _dump(t, space, name)
        local temp = {}
        for k, v in pairs(t) do
            local key = tostring(k)
            if cache[v] then
                -- 已访问过的表,标注其路径
                tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
            elseif type(v) == "table" then
                -- 嵌套表,递归打印
                local new_key = name .. "." .. key
                cache[v] = new_key
                tinsert(temp, "+" .. key .. _dump(v, space .. (next(t, k) and "|" or " ") .. srep(" ", #key), new_key))
            else
                -- 叶子节点,直接输出值
                tinsert(temp, "+" .. key .. " [" .. tostring(v) .. "]")
            end
        end
        return tconcat(temp, "\n" .. space)
    end

    print(_dump(root, "", "") or "")
end

-- 深拷贝表(仅对 table 类型递归,其他直接赋值)
function M.deepcopy(obj)
    if type(obj) ~= "table" then return obj end
    local copy = {}
    for k, v in pairs(obj) do
        copy[k] = M.deepcopy(v)
    end
    return copy
end

-- URL 转义:对非字母数字下划线字符做百分号编码
function M.url_escape(s)
    return (string.gsub(s or "", "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- 生成随机小写字母字符串,长度为 n
function M.random_char(n)
    local chars = {}
    for i = 1, n do
        tinsert(chars, string.char(math.random(97, 122)))
    end
    return tconcat(chars)
end

-- 在 [lo, hi] 范围内取一个随机整数
function M.rand_int(lo, hi)
    return math.random(lo, hi)
end

-- 按权重随机选择:weights 为 {item=item, weight=w} 列表,返回选中的 item
function M.weighted_random(items)
    local total = 0
    for _, it in ipairs(items) do
        total = total + (it.weight or 0)
    end
    if total <= 0 then return nil end

    local r = math.random(1, total)
    local cur = 0
    for _, it in ipairs(items) do
        cur = cur + (it.weight or 0)
        if r <= cur then return it.item end
    end
    return items[#items].item
end

-- 当前毫秒时间戳(luasocket/os 没有直接 ms,用 os.time()*1000 近似)
function M.now_ms()
    return os.time() * 1000
end

return M
