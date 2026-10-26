-- boss活动 7051 ~ 7100
local actBossProto = {}

actBossProto.struct = [[
    .ComActBoss {
        open 0 : boolean        # 是否解锁
        groupId 1 : integer     # 组Id
        npcId 2 : integer       # boss Id
        barrierId 3 : integer   # 副本Id
        maxDmg 4 : integer      # 最大伤害
        rewards 5 : *ComIntBool()    # 已领取的宝箱
        cnt 6 : integer         # 剩余进入副本的次数
        cntTs 7 : integer       # 剩余进入副本的次数ts
        cntIdx 8 : integer      # 剩余进入副本的次数idx
        endTs 9 : integer       # 进入副本的结束时间
    }

    .ComActBossBox {
        key 0: integer          # 宝箱group id
        value 1: *ComIntBool()  # 宝箱领取状态
    }

    .ComBarrierInfo {
        cntKey 0: integer           # 副本内宝箱钥匙使用数量
        boxes 1 : *ComActBossBox()  # 副本内宝箱开启信息
        doors 2 : *ComIntBool()     # 副本内开启的门
        first 3 : boolean           # 副本是否首次进入 true=首次进入
    }

    .ComActBossBoxRess {
        key 0: integer
        value 1: *ComRes
    }
]]

actBossProto.c2s = actBossProto.struct..[[

getActBossReward 7051 { # 领取boss活动宝箱奖励
    request {
        id 0 : uint32               # 宝箱id
    }
    response {
        ids 0 : *integer            # 宝箱ids
        rewards 1 : *ComIntBool()   # 已领取的宝箱
        ress 2: *ComRes             # 获得的资源
    }
}

getActBossInfo 7052 { # 获取boss活动信息
    request {
    }
    response {
        actBoss 0 : ComActBoss   #boss活动信息
    }
}

enterActBossBarrier 7053 { # 进入副本
    request {
    }
    response {
        barrierInfo 0 : ComBarrierInfo
    }
}

exitActBossBarrier 7054 { # 退出副本
    request {
    }
    response {
        ress 0: *ComIntInt()            # 获得的资源
    }
}

getActBossObjId 7055 { # 获取boss对象id
    request {
    }
    response {
        npcObjId 0 : integer            # boss objid
        npcEndTs 1 : integer            # boss 过期倒计时
    }
}

openActBossBox 7056 { # boss活动副本内开宝箱
    request {
        boxgroup 0 : uint32             # 宝箱group id
        boxid 1 : uint32                # 宝箱id
    }
    response {
        boxes 0 : *ComIntBool()  # 开启的宝箱
        ress 1: *ComActBossBoxRess() # 获得的资源
        doors 2 : *ComIntBool()  # 开启的门
        k 3 : integer            # 触发的效果
    }
}
]]

actBossProto.s2c = actBossProto.struct..[[

notifyActBossRewardTotal 7099 { # 退出副本
    request {
       ress 0: *ComIntInt()         # 获得的资源
    }
}
]]

return actBossProto