-- 属性及加成显示 7451 ~ 7470
local attributeDisplayProto = {}

attributeDisplayProto.struct = [[

]]

attributeDisplayProto.c2s = attributeDisplayProto.struct .. [[
    reqAttributeDisplay 7451 {
        request {
    
        }
        response {
            list 0: *ComIntDouble()
        }
    }
]]

attributeDisplayProto.s2c = attributeDisplayProto.struct .. [[

]]

return attributeDisplayProto