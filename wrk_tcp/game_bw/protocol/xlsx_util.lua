-- xlsx_util.lua
-- 纯 Lua xlsx 读写工具(无外部依赖)
-- 读取支持 DEFLATE(方法8)解压,写入使用 STORED(方法0)以避免压缩
-- Lua 5.3 原生位运算

local M = {}

----------------------------------------------------------------------
-- CRC32 (ZIP 校验用)
----------------------------------------------------------------------
local crc32_table = {}
do
    for i = 0, 255 do
        local crc = i
        for _ = 1, 8 do
            if crc & 1 == 1 then
                crc = (crc >> 1) ~ 0xEDB88320
            else
                crc = crc >> 1
            end
        end
        crc32_table[i] = crc
    end
end

local function crc32(data)
    local crc = 0xFFFFFFFF
    for i = 1, #data do
        crc = crc32_table[(crc ~ string.byte(data, i)) & 0xFF] ~ (crc >> 8)
    end
    return crc ~ 0xFFFFFFFF
end

----------------------------------------------------------------------
-- DEFLATE 解压(inflate)
----------------------------------------------------------------------
local function inflate(data)
    local pos = 1
    local data_len = #data
    local output = {}
    local output_len = 0

    local bitbuf = 0
    local bitcnt = 0

    local function read_byte()
        if pos > data_len then return nil end
        local b = string.byte(data, pos)
        pos = pos + 1
        return b
    end

    local function need_bits(n)
        while bitcnt < n do
            local b = read_byte()
            if not b then error("inflate: unexpected end of data") end
            bitbuf = bitbuf | (b << bitcnt)
            bitcnt = bitcnt + 8
        end
        local val = bitbuf & ((1 << n) - 1)
        bitbuf = bitbuf >> n
        bitcnt = bitcnt - n
        return val
    end

    local function align_byte()
        bitbuf = 0
        bitcnt = 0
    end

    -- 由 code lengths 构造 Huffman 解码表:table[bits][code] = symbol
    local function build_decoder(code_lengths)
        local max_bits = 0
        for _, cl in ipairs(code_lengths) do
            if cl > max_bits then max_bits = cl end
        end
        local bl_count = {}
        for i = 0, max_bits + 1 do bl_count[i] = 0 end
        for _, cl in ipairs(code_lengths) do
            if cl > 0 then bl_count[cl] = bl_count[cl] + 1 end
        end
        local next_code = {}
        local code = 0
        bl_count[0] = 0
        for bits = 1, max_bits do
            code = (code + bl_count[bits - 1]) << 1
            next_code[bits] = code
        end
        local decoder = { max_bits = max_bits }
        for bits = 1, max_bits do decoder[bits] = {} end
        for sym_idx = 1, #code_lengths do
            local cl = code_lengths[sym_idx]
            if cl > 0 then
                local c = next_code[cl]
                next_code[cl] = next_code[cl] + 1
                decoder[cl][c] = sym_idx - 1
            end
        end
        return decoder
    end

    local function decode_symbol(decoder)
        local code = 0
        for bits = 1, decoder.max_bits do
            code = (code << 1) | need_bits(1)
            local sym = decoder[bits][code]
            if sym ~= nil then return sym end
        end
        error("inflate: invalid huffman code")
    end

    -- 固定 Huffman 表
    local function get_fixed_tables()
        local lit_len = {}
        for i = 1, 144 do lit_len[i] = 8 end
        for i = 145, 256 do lit_len[i] = 9 end
        for i = 257, 280 do lit_len[i] = 7 end
        for i = 281, 288 do lit_len[i] = 8 end
        local dist = {}
        for i = 1, 30 do dist[i] = 5 end
        return build_decoder(lit_len), build_decoder(dist)
    end

    local length_base = {
        3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
        35,43,51,59,67,83,99,115,131,163,195,227,258
    }
    local length_extra = {
        0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
        3,3,3,3,4,4,4,4,5,5,5,5,0
    }
    local dist_base = {
        1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
        257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577
    }
    local dist_extra = {
        0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,
        7,7,8,8,9,9,10,10,11,11,12,12,13,13
    }

    local function decode_block(lit_dec, dist_dec)
        while true do
            local sym = decode_symbol(lit_dec)
            if sym < 256 then
                output_len = output_len + 1
                output[output_len] = string.char(sym)
            elseif sym == 256 then
                return
            else
                local len_idx = sym - 257 + 1
                local length = length_base[len_idx]
                if length_extra[len_idx] > 0 then
                    length = length + need_bits(length_extra[len_idx])
                end
                local dist_sym = decode_symbol(dist_dec)
                local distance = dist_base[dist_sym + 1]
                if dist_extra[dist_sym + 1] > 0 then
                    distance = distance + need_bits(dist_extra[dist_sym + 1])
                end
                local start = output_len - distance + 1
                for i = 1, length do
                    output_len = output_len + 1
                    output[output_len] = output[start + i - 1]
                end
            end
        end
    end

    local function read_dynamic_tables()
        local hlit = need_bits(5) + 257
        local hdist = need_bits(5) + 1
        local hclen = need_bits(4) + 4
        local order = {16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15}
        local cl_lengths = {}
        for i = 1, 19 do cl_lengths[i] = 0 end
        for i = 1, hclen do
            cl_lengths[order[i] + 1] = need_bits(3)
        end
        local cl_dec = build_decoder(cl_lengths)
        local all = {}
        local total = hlit + hdist
        while #all < total do
            local s = decode_symbol(cl_dec)
            if s < 16 then
                all[#all + 1] = s
            elseif s == 16 then
                local prev = all[#all] or 0
                local cnt = need_bits(2) + 3
                for _ = 1, cnt do all[#all + 1] = prev end
            elseif s == 17 then
                local cnt = need_bits(3) + 3
                for _ = 1, cnt do all[#all + 1] = 0 end
            elseif s == 18 then
                local cnt = need_bits(7) + 11
                for _ = 1, cnt do all[#all + 1] = 0 end
            end
        end
        local lit_l = {}
        for i = 1, hlit do lit_l[i] = all[i] end
        local dist_l = {}
        for i = 1, hdist do dist_l[i] = all[hlit + i] end
        return build_decoder(lit_l), build_decoder(dist_l)
    end

    local bfinal = 0
    repeat
        bfinal = need_bits(1)
        local btype = need_bits(2)
        if btype == 0 then
            align_byte()
            local len = read_byte() | (read_byte() << 8)
            read_byte(); read_byte()
            for i = 1, len do
                output_len = output_len + 1
                output[output_len] = string.char(read_byte())
            end
        elseif btype == 1 then
            local lit, dist = get_fixed_tables()
            decode_block(lit, dist)
        elseif btype == 2 then
            local lit, dist = read_dynamic_tables()
            decode_block(lit, dist)
        else
            error("inflate: invalid block type " .. btype)
        end
    until bfinal == 1

    return table.concat(output)
end

----------------------------------------------------------------------
-- ZIP 读取
----------------------------------------------------------------------
local function u16(data, p)
    return string.byte(data, p) | (string.byte(data, p + 1) << 8)
end
local function u32(data, p)
    return string.byte(data, p) | (string.byte(data, p + 1) << 8)
        | (string.byte(data, p + 2) << 16) | (string.byte(data, p + 3) << 24)
end

local function read_zip(data)
    local eocd = nil
    -- EOCD 最小 22 字节,最大 65557 字节(含 65535 字节注释)
    -- 无注释时起始于 #data-21,有最大注释时起始于 #data-65556
    for i = #data - 21, math.max(1, #data - 65556), -1 do
        if u32(data, i) == 0x06054b50 then
            eocd = i
            break
        end
    end
    if not eocd then error("zip: EOCD not found") end

    local cd_offset = u32(data, eocd + 16) + 1
    local cd_size = u32(data, eocd + 12)
    local entries = {}
    local order = {}
    local pos = cd_offset

    while pos < cd_offset + cd_size do
        if u32(data, pos) ~= 0x02014b50 then break end
        local method = u16(data, pos + 10)
        local comp_size = u32(data, pos + 20)
        local name_len = u16(data, pos + 28)
        local extra_len = u16(data, pos + 30)
        local comment_len = u16(data, pos + 32)
        local lh_offset = u32(data, pos + 42) + 1

        local name = string.sub(data, pos + 46, pos + 46 + name_len - 1)

        local lh_name_len = u16(data, lh_offset + 26)
        local lh_extra_len = u16(data, lh_offset + 28)
        local data_off = lh_offset + 30 + lh_name_len + lh_extra_len
        local comp_data = string.sub(data, data_off, data_off + comp_size - 1)

        local file_data
        if method == 0 then
            file_data = comp_data
        elseif method == 8 then
            file_data = inflate(comp_data)
        else
            error("zip: unsupported method " .. method .. " for " .. name)
        end

        entries[name] = { data = file_data, method = method }
        order[#order + 1] = name
        pos = pos + 46 + name_len + extra_len + comment_len
    end

    return entries, order
end

----------------------------------------------------------------------
-- ZIP 写入(所有条目使用 STORED 方法)
----------------------------------------------------------------------
local function write_zip(entries, order)
    local parts = {}
    local central = {}
    local offset = 0

    for _, name in ipairs(order) do
        local entry = entries[name]
        local data = entry.data
        local crc = crc32(data)
        local size = #data
        local name_bytes = name

        local lh = {}
        lh[#lh + 1] = string.char(0x50, 0x4b, 0x03, 0x04)
        lh[#lh + 1] = string.char(20, 0)
        lh[#lh + 1] = string.char(0, 0)
        lh[#lh + 1] = string.char(0, 0)
        lh[#lh + 1] = string.char(0, 0, 0, 0)
        lh[#lh + 1] = string.char(crc & 0xFF, (crc >> 8) & 0xFF, (crc >> 16) & 0xFF, (crc >> 24) & 0xFF)
        lh[#lh + 1] = string.char(size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF)
        lh[#lh + 1] = string.char(size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF)
        lh[#lh + 1] = string.char(#name_bytes & 0xFF, (#name_bytes >> 8) & 0xFF)
        lh[#lh + 1] = string.char(0, 0)
        local lh_str = table.concat(lh) .. name_bytes
        parts[#parts + 1] = lh_str
        parts[#parts + 1] = data

        local ch = {}
        ch[#ch + 1] = string.char(0x50, 0x4b, 0x01, 0x02)
        ch[#ch + 1] = string.char(20, 0)
        ch[#ch + 1] = string.char(20, 0)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0, 0, 0)
        ch[#ch + 1] = string.char(crc & 0xFF, (crc >> 8) & 0xFF, (crc >> 16) & 0xFF, (crc >> 24) & 0xFF)
        ch[#ch + 1] = string.char(size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF)
        ch[#ch + 1] = string.char(size & 0xFF, (size >> 8) & 0xFF, (size >> 16) & 0xFF, (size >> 24) & 0xFF)
        ch[#ch + 1] = string.char(#name_bytes & 0xFF, (#name_bytes >> 8) & 0xFF)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0)
        ch[#ch + 1] = string.char(0, 0, 0, 0)
        ch[#ch + 1] = string.char(offset & 0xFF, (offset >> 8) & 0xFF, (offset >> 16) & 0xFF, (offset >> 24) & 0xFF)
        central[#central + 1] = table.concat(ch) .. name_bytes

        offset = offset + #lh_str + size
    end

    local central_data = table.concat(central)
    local central_size = #central_data
    local central_offset = offset
    local total = #order

    local eocd = {}
    eocd[#eocd + 1] = string.char(0x50, 0x4b, 0x05, 0x06)
    eocd[#eocd + 1] = string.char(0, 0)
    eocd[#eocd + 1] = string.char(0, 0)
    eocd[#eocd + 1] = string.char(total & 0xFF, (total >> 8) & 0xFF)
    eocd[#eocd + 1] = string.char(total & 0xFF, (total >> 8) & 0xFF)
    eocd[#eocd + 1] = string.char(central_size & 0xFF, (central_size >> 8) & 0xFF, (central_size >> 16) & 0xFF, (central_size >> 24) & 0xFF)
    eocd[#eocd + 1] = string.char(central_offset & 0xFF, (central_offset >> 8) & 0xFF, (central_offset >> 16) & 0xFF, (central_offset >> 24) & 0xFF)
    eocd[#eocd + 1] = string.char(0, 0)

    parts[#parts + 1] = central_data
    parts[#parts + 1] = table.concat(eocd)
    return table.concat(parts)
end

----------------------------------------------------------------------
-- 简易 XML 解析与序列化
----------------------------------------------------------------------
local function xml_unescape(s)
    s = string.gsub(s, "&lt;", "<")
    s = string.gsub(s, "&gt;", ">")
    s = string.gsub(s, "&quot;", '"')
    s = string.gsub(s, "&apos;", "'")
    s = string.gsub(s, "&#(%d+);", function(n) return string.char(tonumber(n)) end)
    s = string.gsub(s, "&#x(%x+);", function(h) return string.char(tonumber(h, 16)) end)
    s = string.gsub(s, "&amp;", "&")
    return s
end

local function xml_escape(s)
    s = tostring(s or "")
    s = string.gsub(s, "&", "&amp;")
    s = string.gsub(s, "<", "&lt;")
    s = string.gsub(s, ">", "&gt;")
    s = string.gsub(s, '"', "&quot;")
    return s
end

local function parse_xml(xml_str)
    local root = nil
    local stack = {}
    local pos = 1
    local len = #xml_str

    local function skip_ws()
        while pos <= len do
            local c = string.sub(xml_str, pos, pos)
            if c == " " or c == "\t" or c == "\n" or c == "\r" then
                pos = pos + 1
            else break end
        end
    end

    while pos <= len do
        skip_ws()
        if pos > len then break end
        local c2 = string.sub(xml_str, pos, pos + 1)
        if c2 == "<?" then
            local ep = string.find(xml_str, "?>", pos, true)
            pos = ep + 2
        elseif c2 == "<!" then
            if string.sub(xml_str, pos, pos + 3) == "<!--" then
                local ep = string.find(xml_str, "-->", pos, true)
                pos = ep + 3
            elseif string.sub(xml_str, pos, pos + 8) == "<![CDATA[" then
                local ep = string.find(xml_str, "]]>", pos, true)
                local text = string.sub(xml_str, pos + 9, ep - 1)
                if #stack > 0 then
                    stack[#stack].text = (stack[#stack].text or "") .. text
                end
                pos = ep + 3
            else
                local ep = string.find(xml_str, ">", pos, true)
                pos = ep + 1
            end
        elseif string.sub(xml_str, pos, pos) == "<" then
            local ep = string.find(xml_str, ">", pos, true)
            local content = string.sub(xml_str, pos + 1, ep - 1)
            local is_close = false
            if string.sub(content, 1, 1) == "/" then
                is_close = true
                content = string.sub(content, 2)
            end
            local self_close = false
            if string.sub(content, -1) == "/" then
                self_close = true
                content = string.sub(content, 1, -2)
            end
            local tag_name, rest = string.match(content, "^(%S+)(.*)$")
            local attrs = {}
            if rest then
                for an, av in string.gmatch(rest, '([%w:_-]+)="([^"]*)"') do
                    attrs[an] = xml_unescape(av)
                end
            end
            if is_close then
                table.remove(stack)
            else
                local elem = { tag = tag_name, attrs = attrs, children = {}, text = "" }
                if #stack > 0 then
                    table.insert(stack[#stack].children, elem)
                else
                    root = elem
                end
                if not self_close then
                    table.insert(stack, elem)
                end
            end
            pos = ep + 1
        else
            local np = string.find(xml_str, "<", pos, true)
            if not np then np = len + 1 end
            local text = string.sub(xml_str, pos, np - 1)
            if #stack > 0 and text ~= "" then
                stack[#stack].text = (stack[#stack].text or "") .. xml_unescape(text)
            end
            pos = np
        end
    end
    return root
end

local function serialize_xml(elem)
    local parts = { "<" .. elem.tag }
    for k, v in pairs(elem.attrs) do
        parts[#parts + 1] = string.format(' %s="%s"', k, xml_escape(v))
    end
    local has_text = elem.text and elem.text ~= ""
    local has_children = #elem.children > 0
    if not has_text and not has_children then
        parts[#parts + 1] = "/>"
    else
        parts[#parts + 1] = ">"
        if has_text then
            parts[#parts + 1] = xml_escape(elem.text)
        end
        for _, child in ipairs(elem.children) do
            parts[#parts + 1] = serialize_xml(child)
        end
        parts[#parts + 1] = "</" .. elem.tag .. ">"
    end
    return table.concat(parts)
end

----------------------------------------------------------------------
-- 列名与引用转换
----------------------------------------------------------------------
local function col_letters_to_num(letters)
    local n = 0
    for i = 1, #letters do
        n = n * 26 + (string.byte(letters, i) - string.byte("A") + 1)
    end
    return n
end

local function col_num_to_letters(n)
    local s = ""
    while n > 0 do
        local rem = (n - 1) % 26
        s = string.char(string.byte("A") + rem) .. s
        n = math.floor((n - 1) / 26)
    end
    return s
end

local function parse_cell_ref(ref)
    local letters, digits = string.match(ref, "^([A-Z]+)(%d+)$")
    if not letters then return nil, nil end
    return col_letters_to_num(letters), tonumber(digits)
end

----------------------------------------------------------------------
-- 读取 xlsx
----------------------------------------------------------------------
function M.read_xlsx(path)
    local f = io.open(path, "rb")
    if not f then return nil, "file not found: " .. path end
    local data = f:read("*a")
    f:close()

    local entries, order = read_zip(data)

    -- 共享字符串
    local shared_strings = {}
    local ss_entry = entries["xl/sharedStrings.xml"]
    if ss_entry then
        local root = parse_xml(ss_entry.data)
        for _, si in ipairs(root.children) do
            if si.tag == "si" then
                local text = ""
                for _, child in ipairs(si.children) do
                    if child.tag == "t" then
                        text = text .. (child.text or "")
                    elseif child.tag == "r" then
                        for _, rc in ipairs(child.children) do
                            if rc.tag == "t" then
                                text = text .. (rc.text or "")
                            end
                        end
                    end
                end
                shared_strings[#shared_strings + 1] = text
            end
        end
    end

    -- workbook sheets
    local sheets_info = {}
    local wb_root = parse_xml(entries["xl/workbook.xml"].data)
    for _, child in ipairs(wb_root.children) do
        if child.tag == "sheets" then
            for _, sheet in ipairs(child.children) do
                if sheet.tag == "sheet" then
                    sheets_info[#sheets_info + 1] = {
                        name = sheet.attrs.name,
                        r_id = sheet.attrs["r:id"],
                    }
                end
            end
        end
    end

    -- rels
    local rels_map = {}
    local rels_entry = entries["xl/_rels/workbook.xml.rels"]
    if rels_entry then
        local rels_root = parse_xml(rels_entry.data)
        for _, rel in ipairs(rels_root.children) do
            if rel.tag == "Relationship" then
                rels_map[rel.attrs.Id] = rel.attrs.Target
            end
        end
    end

    local result = {
        sheets = {},
        shared_strings = shared_strings,
        _entries = entries,
        _order = order,
    }

    for _, info in ipairs(sheets_info) do
        local target = rels_map[info.r_id]
        local sheet_path = "xl/" .. target
        local sheet_entry = entries[sheet_path]
        if not sheet_entry then
            for name, _ in pairs(entries) do
                if string.find(name, target, 1, true) then
                    sheet_path = name
                    sheet_entry = entries[name]
                    break
                end
            end
        end

        local root = parse_xml(sheet_entry.data)
        local cells = {}
        local sheet_data_elem = nil
        for _, child in ipairs(root.children) do
            if child.tag == "sheetData" then
                sheet_data_elem = child
                break
            end
        end

        if sheet_data_elem then
            for _, row in ipairs(sheet_data_elem.children) do
                if row.tag == "row" then
                    for _, c in ipairs(row.children) do
                        if c.tag == "c" then
                            local ref = c.attrs.r
                            local ctype = c.attrs.t
                            local value = nil
                            for _, cc in ipairs(c.children) do
                                if cc.tag == "v" then
                                    value = cc.text
                                elseif cc.tag == "is" then
                                    for _, isc in ipairs(cc.children) do
                                        if isc.tag == "t" then
                                            value = (value or "") .. (isc.text or "")
                                        end
                                    end
                                end
                            end
                            if ctype == "s" and value then
                                value = shared_strings[tonumber(value) + 1]
                            elseif ctype == "b" and value then
                                value = tonumber(value) == 1
                            elseif value then
                                local num = tonumber(value)
                                if num then value = num end
                            end
                            cells[ref] = value
                        end
                    end
                end
            end
        end

        result.sheets[info.name] = {
            name = info.name,
            cells = cells,
            _xml_root = root,
            _path = sheet_path,
        }
    end

    return result
end

----------------------------------------------------------------------
-- 修改单元格
----------------------------------------------------------------------
local function find_or_create_cell(sheet_elem, ref)
    local col, row = parse_cell_ref(ref)
    local sheet_data = nil
    for _, child in ipairs(sheet_elem.children) do
        if child.tag == "sheetData" then
            sheet_data = child
            break
        end
    end
    if not sheet_data then
        sheet_data = { tag = "sheetData", attrs = {}, children = {}, text = "" }
        sheet_elem.children[#sheet_elem.children + 1] = sheet_data
    end

    local row_elem = nil
    for _, r in ipairs(sheet_data.children) do
        if r.tag == "row" and tonumber(r.attrs.r) == row then
            row_elem = r
            break
        end
    end
    if not row_elem then
        row_elem = { tag = "row", attrs = { r = tostring(row) }, children = {}, text = "" }
        local inserted = false
        for i = #sheet_data.children, 1, -1 do
            local r = sheet_data.children[i]
            if r.tag == "row" and tonumber(r.attrs.r) < row then
                table.insert(sheet_data.children, i + 1, row_elem)
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(sheet_data.children, 1, row_elem)
        end
    end

    for _, c in ipairs(row_elem.children) do
        if c.tag == "c" and c.attrs.r == ref then
            return c
        end
    end

    local cell = { tag = "c", attrs = { r = ref }, children = {}, text = "" }
    local inserted = false
    for i = #row_elem.children, 1, -1 do
        local c = row_elem.children[i]
        if c.tag == "c" then
            local cc, _ = parse_cell_ref(c.attrs.r)
            if cc < col then
                table.insert(row_elem.children, i + 1, cell)
                inserted = true
                break
            end
        end
    end
    if not inserted then
        table.insert(row_elem.children, 1, cell)
    end
    return cell
end

local function set_cell_value(cell, value)
    cell.children = {}
    if value == nil then
        cell.attrs.t = nil
        return
    end
    local vtype = type(value)
    if vtype == "number" then
        cell.attrs.t = nil
        cell.children[1] = { tag = "v", attrs = {}, children = {}, text = tostring(value) }
    elseif vtype == "boolean" then
        cell.attrs.t = "b"
        cell.children[1] = { tag = "v", attrs = {}, children = {}, text = value and "1" or "0" }
    else
        cell.attrs.t = "inlineStr"
        local is_elem = { tag = "is", attrs = {}, children = {}, text = "" }
        is_elem.children[1] = { tag = "t", attrs = {}, children = {}, text = tostring(value) }
        cell.children[1] = is_elem
    end
end

function M.set_cell(workbook, sheet_name, ref, value)
    local sheet = workbook.sheets[sheet_name]
    if not sheet then return false end
    local cell = find_or_create_cell(sheet._xml_root, ref)
    set_cell_value(cell, value)
    sheet.cells[ref] = value
    return true
end

----------------------------------------------------------------------
-- 保存 xlsx
----------------------------------------------------------------------
function M.save_xlsx(workbook, path)
    for _, sheet in pairs(workbook.sheets) do
        local xml_str = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        xml_str = xml_str .. serialize_xml(sheet._xml_root)
        workbook._entries[sheet._path].data = xml_str
    end
    local zip_data = write_zip(workbook._entries, workbook._order)
    local f = io.open(path, "wb")
    if not f then return nil, "cannot open " .. path end
    f:write(zip_data)
    f:close()
    return true
end

return M