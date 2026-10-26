local package = [[

.package {
    type 0 : integer            # 协议
    session 1: integer          # client server 各维护一套自增的id
    ud 2 : integer              # response:用于错误码;推送:用户包确认。
}

]]
return package