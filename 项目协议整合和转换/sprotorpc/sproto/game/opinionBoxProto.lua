-- 民意信箱 8091～8110
local opinionBoxProto = {}

opinionBoxProto.struct = [[
    .ComOpinionLetter { #信件
        id 0: uint32                  # id
        cfgId 1: uint32               # 配置表id
        time 2: uint32                # 时间戳
        rid 3: uint32                 # 居民配置表id
        bid 4: uint32                 # 建筑id
        fid 5: uint32                 # 家具id
    }

    .ComOpinionMail { #紧急求助
        id 0: uint32                  # id
        cfgId 1: uint32               # 配置表id
        time 2: uint32                # 时间戳
        rid 3: uint32                 # 居民配置表id  
        handled 4: boolean            # true:处理  false:未处理 
        index 5: uint32               # 已选择选项
    }

    .ComOpinionBox {
        letters 0: *ComOpinionLetter(id)   # 信件
        mails 1: *ComOpinionMail(id)       # 紧急求助
        opValue 2: uint32                  # 民意值
        isUnlock 3: boolean
    }

    .ComSyncOpinionBox {
        letters 0: ComSyncOpinionLetter   # 信件
        mails 1: ComSyncOpinionMail       # 紧急求助
        opValue 2: uint32                 # 民意值
        isUnlock 3: boolean
    }

    .ComSyncOpinionLetter { #信件同步
        news 1: *ComOpinionLetter(id)     # 新增信件
        changes 2: *ComOpinionLetter(id)  # 更新信件
        removes 3: *integer               # 移除信件
    }    

    .ComSyncOpinionMail { #紧急求助同步
        news 1: *ComOpinionMail(id)     # 新增紧急求助
        changes 2: *ComOpinionMail(id)  # 更新紧急求助
        removes 3: *integer             # 移除紧急求助
    }
]]

opinionBoxProto.c2s = opinionBoxProto.struct .. [[
    opinionBoxGetToMailReward 8091 { # 领取回信
        request {
            id 0: uint32   # id
        }
        response {
            ress 1: *ComRes
        }
    }

    opinionBoxSelectFromMailOption 8092 { # 处理来信
        request {
            id 0: uint32   # id
            optionIndex 1: uint32
        }
        response {
            ress 1: *ComRes
        }
    }

    opinionBoxGetEvaluation 8093 { # 获取民意评价
        request {

        }
        response {
            evaluation 1: *ComUint32Uint32() # 时间戳->民意值
        }
    }

]]

opinionBoxProto.s2c = opinionBoxProto.struct .. [[

]]

return opinionBoxProto