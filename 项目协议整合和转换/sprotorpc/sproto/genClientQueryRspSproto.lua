local sprotoparser = require("sprotoparser")
local sprotoloader = require("sprotoloader")
local sprotoGettr = require("sproto.sprotoGetter")
local sprotoConfig = require("sproto.sprotoConfig")
local nodeType = "client"
local sprotos = sprotoGettr.getSprotoStrTable(nodeType)
local spb_c2s = sprotoparser.parse(sprotos.c2s)
local spb_s2c = sprotoparser.parse(sprotos.s2c)

local config = sprotoConfig[nodeType]
assert(config, "sprotoConfig nodeType err:"..nodeType)

if config.c2s then
    sprotoloader.save(spb_c2s, 1)
    gLog.debug("----------------spb_c2s-------------",spb_c2s)
end

if config.s2c then
    sprotoloader.save(spb_s2c, 2)
    gLog.debug("----------------s2c-------------",spb_s2c)
end

local function parser(text,filename)
    local lpeg = require "lpeg"
        
    
    local exception = lpeg.Cmt( lpeg.Carg(1) , function ( _ , pos, parser_state)
        error(string.format("syntax error at [%s] line (%d)", parser_state.file or "", parser_state.line))
        return pos
    end)

    local function count_lines(_,pos, parser_state)
        if parser_state.pos < pos then
            parser_state.line = parser_state.line + 1
            parser_state.pos = pos
        end
        return pos
    end
    
    local P = lpeg.P
    local S = lpeg.S
    local R = lpeg.R
    local C = lpeg.C
    local Ct = lpeg.Ct
    local Cg = lpeg.Cg
    local Cc = lpeg.Cc
    local V = lpeg.V
    
    local eof = P(-1)
    local newline = lpeg.Cmt((P"\n" + "\r\n") * lpeg.Carg(1) ,count_lines)
    local line_comment = "#" * (1 - newline) ^0 * (newline + eof)
    local blank = S" \t" + newline + line_comment
    local blank0 = blank ^ 0
    local blanks = blank ^ 1
    local alpha = R"az" + R"AZ" + "_"
    local alnum = alpha + R"09"
    local word = alpha * alnum ^ 0
    local name = C(word)
    local typename = C(word * ("." * word) ^ 0)
    local tag = R"09" ^ 1 / tonumber
    local mainkey = "(" * blank0 * C((word ^ 0)) * blank0 * ")"
    local decimal = "(" * blank0 * C(tag) * blank0 * ")"

    local function multipat(pat)
        return Ct(blank0 * (pat * blanks) ^ 0 * pat^0 * blank0)
    end

    local function namedpat(name, pat)
        return Ct(Cg(Cc(name), "type") * Cg(pat))
    end

    local typedef = P {
        "ALL",
        FIELD = namedpat("field", name * blanks * tag * blank0 * ":" * blank0 * (C"*")^-1 * typename * (mainkey + decimal)^0),
        STRUCT = P"{" * multipat(V"FIELD" + V"TYPE") * P"}",
        TYPE = namedpat("type", P"." * name * blank0 * V"STRUCT" ),
        SUBPROTO = Ct((C"request" + C"response") * blanks * (typename + V"STRUCT")),
        PROTOCOL = namedpat("protocol", name * blanks * tag * blank0 * P"{" * multipat(V"SUBPROTO") * P"}"),
        ALL = multipat(V"TYPE" + V"PROTOCOL"),
    }

    local proto = blank0 * typedef * blank0

    local state = { file = filename, pos = 0, line = 1 }
    local r = lpeg.match(proto * -1 + exception , text , 1, state )
    local str = "local clientQueryRspProto = {}\n"
    str = str .. "clientQueryRspProto.struct = [[\n"
    str = str .. "]]\n"
    str = str .. "clientQueryRspProto.c2s = clientQueryRspProto.struct..[[\n"
    str = str .. "]]\n"
    str = str .. "clientQueryRspProto.s2c = clientQueryRspProto.struct..[[\n"
    for _, v in pairs(r) do
        if v.type == "protocol" then
            local protoName = v[1]
            local protoId = v[2]
            local protos = v[3]
            for _, tbProto in pairs(protos) do
                local protoType = tbProto[1]
                if protoType == "response" and #tbProto[2] > 0 then
                    -- gLog.dump(tbProto[2], string.format("name=%s,id=%s,protoType=%s", protoName, protoId, protoType))
                    str = str .. string.format("%sRsp %s {\n", protoName, protoId)
                    str = str .. string.format("    %s {\n", "request")
                    for _, itemField in pairs(tbProto[2]) do
                        local fieldName = itemField[1]
                        local fieldIdx = itemField[2]
                        local fieldType = itemField[3]
                        local strField
                        if fieldType == "*" then
                            local fieldSubType = itemField[4]
                            local fieldSubTypeSuffix = itemField[5]
                            if fieldSubTypeSuffix then
                                strField = string.format("        %s %s: %s%s(%s)\n", fieldName, fieldIdx, fieldType, fieldSubType, fieldSubTypeSuffix)
                            else
                                strField = string.format("        %s %s: %s%s\n", fieldName, fieldIdx, fieldType, fieldSubType)
                            end
                        else
                            strField = string.format("        %s %s: %s\n", fieldName, fieldIdx, fieldType)
                        end
                        str = str .. strField
                    end
                    str = str .. "    }\n"
                    str = str .. "}\n"
                    -- gLog.debug("name=%s,id=%s,protoType=%s,str=%s", protoName, protoId, protoType, str)
                end
            end
            
        end
    end
    str = str .. "]]\n"
    str = str .. "return clientQueryRspProto\n"
    -- print(str)
    local fileUtil = require("fileUtil")
    local filePath = "../scCommon/lua/sprotorpc/sproto/game/clientQueryRspProto.lua"
    fileUtil.write(filePath, str)
end

for nt, _ in pairs(sprotoConfig) do
    if nt == "client" then
        local s = sprotoGettr.getSprotoStrTable(nt)
        parser(s.c2s)
    end
end

-- local sprotoparserExtend = require("sprotoparserExtend")
-- local route = {}
-- for nt, _ in pairs(sprotoConfig) do
--     if nt == "client" then
--         local s = sprotoGettr.getSprotoStrTable(nt)
--         local r = sprotoparserExtend.parser(s.c2s)
--         local protocol = r.protocol
--         -- gLog.dump(protocol, "[sprotoInit].init,protocol" .. nt)
--         for _, data in pairs(protocol) do
--             local tag = data.tag
--             local request = data.request
--             local name = string.sub(request, 1, -9)
            
--             print(name)
--         end
--     end
-- end