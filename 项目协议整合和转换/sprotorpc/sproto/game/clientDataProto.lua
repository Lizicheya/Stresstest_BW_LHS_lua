-- 客户端数据 6201 ~ 6300
local clientDataProto = {}

clientDataProto.struct = [[
    .ComClientDataIntInt {
        key 0: integer           # ClientDataType枚举，客户端自己维护
        value 1: *ComIntInt()    # 客户端自己存储的数据结构
    }
    .ComClientData {
        structIntInt 0: *ComClientDataIntInt()
    }

    .ComSyncClientDataIntInt {
        news 0 : *ComClientDataIntInt()                           # 新增
        changes 1 : *ComClientDataIntInt()                        # 更新
        removes 2 : *integer                                      # 移除
    }

    .ComSyncClientData {
        structIntInt 0: ComSyncClientDataIntInt
    }
]]

clientDataProto.c2s = clientDataProto.struct..[[

setClientStructIntInt 6201 { # 设置客户端数据
    request {
        dataType 0: uint32     # ClientDataType枚举（客户端自己定义不重复即可）
        key 1: uint32          # map的key值
        value 2: uint32        # map的value值 不填服务器默认1
    }
    response {
    }
}

]]

clientDataProto.s2c = clientDataProto.struct..[[

]]

return clientDataProto