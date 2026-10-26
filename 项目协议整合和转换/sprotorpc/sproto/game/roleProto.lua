-- 角色信息 7101 ~ 7200
local roleProto = {}

roleProto.struct = [[
    .ComRoleInfo {
        uid 0: integer                                  #玩家id
        nickName 1: string                              #玩家昵称
        headId 2: integer                               #头像
        headFrameId 3: integer                          #头像框
        customHead 4: string                            #自定义头像
        abbName 7: string                               #联盟简称
        serverId 8: integer                             #服务器id
        castleLv 9: integer                             #城堡等级
        power 10: integer                               #战力
    }

]]

roleProto.c2s = roleProto.struct..[[

getRoleList 7101 {                                      # 查询玩家角色列表
    request {
    }
    response {
        roleList 0: *ComRoleInfo(uid)
    }
}

]]

roleProto.s2c = roleProto.struct..[[

]]

return roleProto