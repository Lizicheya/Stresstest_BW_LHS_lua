-- 游服信息 6991 ~ 7000
local serverInfoProto = {}

serverInfoProto.struct = [[
    .ComServerKingInfo {
        kingUid 0: integer    # 国王id
        kingName 1: string    # 国王名称
    }

    .ComServerInfo {
        serverId 0: integer    # 服务器id
        serverKingInfo 1: ComServerKingInfo # 国王id 未接入
        serverOpenTime 2: integer # 服务器开服时间
        serverState 3: integer    # 服务器状态 1 对外， 2 非对外
    }
]]

serverInfoProto.c2s = serverInfoProto.struct .. [[

]]

serverInfoProto.s2c = serverInfoProto.struct .. [[

]]

return serverInfoProto