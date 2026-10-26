--联盟道具（联盟仓库） 4201 ~ 4300
local allianceProto = {}

allianceProto.struct = [[
    .ComAllianceResChangeRecord {
        operPlayer 0: ComPlayerBaseInfo             # 操作的玩家
        operAlliance 1: ComAllianceInfo             # 操作的联盟
        changeRes 2: *ComIntInt()                   # 变动的资源列表
        operTime 3: integer                         # 时间戳
        operType 4: integer                         # 操作类型
        operData 5: integer                         # 操作类型附带数据（无不填充数据）
        id 6:integer                                # id
    }
]]

allianceProto.c2s = allianceProto.struct .. [[
    reqResChangeRecord 4201 { # 查询联盟资源变动记录
        request {
            beginId 0: uint32     # 开始位置id
            count 1: uint32       # 数量
        }
        response {
            recordList 0: *ComAllianceResChangeRecord(id)    #联盟资源变动记录
        }
    }
]]

allianceProto.s2c = allianceProto.struct .. [[

]]

return allianceProto