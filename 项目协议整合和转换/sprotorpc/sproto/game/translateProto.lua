--
-- author: TQING<tqing1128@gmail.com>
-- date: 2024-08-21 09:31:56
--

-- 7431 ~ 7440

local translateProto = {}

translateProto.struct = [[
]]

translateProto.c2s = translateProto.struct .. [[

translate 7431 {
    request {
        text 0 : string # 原文
    }
    response {
        channel 0 : string # 渠道
        sl 1 : string # 源语言
        text 2 : string # 译文
    }
}

# 固定请求免费的翻译
translateFree 7432 {
    request {
        text 0 : string # 原文
    }
    response {
        channel 0 : string # 渠道
        sl 1 : string # 源语言
        text 2 : string # 译文
    }
}

]]

translateProto.s2c = translateProto.struct .. [[

]]

return translateProto