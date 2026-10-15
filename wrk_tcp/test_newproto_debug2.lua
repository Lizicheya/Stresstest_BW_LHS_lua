-- 更深入调试:用 sproto 库源码逻辑手动模拟 create_from_bundle
package.path = "lualib/?.lua;lualib/?/init.lua;" .. package.path
package.cpath = "lualib/?.dll;luaclib/?.dll;luaclib/?.so;" .. package.cpath

local parser = require "sprotoparser"
local f = io.open("./lualib/protocol/c2s.proto", "rb")
local data = f:read("a")
f:close()
local bin = parser.parse(data)

-- 模拟 sproto.c 的逻辑
local SIZEOF_LENGTH = 4
local SIZEOF_HEADER = 2
local SIZEOF_FIELD = 2

-- toword: 取 2 字节小端
local function toword(offset)
    return string.byte(bin, offset+1) + string.byte(bin, offset+2) * 256
end

-- struct_field
local sz = #bin
local fn = toword(0)  -- stream[0]
print("fn:", fn)
local header = SIZEOF_HEADER + SIZEOF_FIELD * fn
print("header:", header)
if sz < header then
    print("ERROR: sz < header")
    os.exit(1)
end
if sz < SIZEOF_LENGTH then
    print("ERROR: sz < SIZEOF_LENGTH")
    os.exit(1)
end

-- content 指向 header 之后
-- 但 create_from_bundle 中:
--   stream += SIZEOF_HEADER
--   content = stream + fn*SIZEOF_FIELD
-- 所以 content 偏移 = SIZEOF_HEADER + fn*SIZEOF_FIELD = header
local content_offset = header + 1  -- Lua 1-based
print("content_offset:", content_offset)

-- count_array:读 4 字节长度
local function count_array(offset)
    -- 读取 4 字节长度(小端)
    if offset + 3 > #bin then return -1 end
    local len = string.byte(bin, offset) + string.byte(bin, offset+1) * 256 +
                string.byte(bin, offset+2) * 65536 + string.byte(bin, offset+3) * 16777216
    -- 检查后续数据长度
    if offset + SIZEOF_LENGTH + len > #bin then
        print(string.format("count_array: offset=%d len=%d, but bin_len=%d, need %d",
              offset, len, #bin, offset + SIZEOF_LENGTH + len))
        return -1
    end
    -- 返回数组元素数(每个元素 2 字节?不,count_array 返回 n,表示元素数)
    -- 实际 sproto.c count_array:
    --   length = todword(stream)
    --   n = length / 2  -- 每个 word 2 字节
    --   if length % 2 != 0 return -1
    --   return n
    if len % 2 ~= 0 then
        print("count_array: len not even:", len)
        return -1
    end
    return len / 2
end

for i = 0, fn-1 do
    local value = toword(SIZEOF_HEADER + i * SIZEOF_FIELD)
    print(string.format("field %d value: %d", i, value))
    if value ~= 0 then
        print("ERROR: value != 0")
        os.exit(1)
    end
    -- count_array(content)
    local content_ptr = content_offset + (i == 0 and 0 or 0)  -- 简化,实际 content 指针移动
    -- 但 i==0 时 content 是 typedata 开始
    -- i==1 时 content 是 protocoldata 开始(在 typedata 之后)
    -- 这里简化只看 i=0
    if i == 0 then
        local n = count_array(content_offset)
        print(string.format("count_array for typedata: %d", n))
    end
end

-- 直接检查 content_offset 处的 4 字节
print("\n--- content at offset", content_offset, "---")
local hex = ""
for i = content_offset, content_offset + 7 do
    hex = hex .. string.format("%02X ", string.byte(bin, i))
end
print("hex:", hex)
local len = string.byte(bin, content_offset) + string.byte(bin, content_offset+1) * 256 +
            string.byte(bin, content_offset+2) * 65536 + string.byte(bin, content_offset+3) * 16777216
print("length field:", len)
print("remaining after length:", #bin - content_offset - 4)
