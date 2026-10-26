-- 内城居民 8001 ~ 8050
local cityResidentProto = {}

cityResidentProto.struct = [[
    .ComResident { # 居民
        id 0: uint32 # 居民id
        cfgId 1: uint32 # 配置表id
        status 2: uint32 # 居民状态(CityResidentStatus)
        buildId 3: uint32 # 建筑唯一id 默认0
        fId 4: uint32 # 家具唯一id 默认0
        .Skill {
            id 0: uint32 # 技能配置表id
            isAct 1: boolean # 技能是否激活
            ts 2: uint32 # 时间戳 0表示技能点没有增长 大于0表示技能点开始增长的时间戳
        }
        skills 5: *Skill # 居民技能
        story 6: boolean # 是否有故事
        bindTs 7: uint32 # 绑定时间  默认0
        houseId 8: uint32 # 民居的建筑id 唯一
        bedId 9: uint32 # 绑定的床位 双人床(家具id * 10 + 下铺1 / 上铺2) 单人床(家具id * 10 + 下铺1)
    }

    .ComSyncResident {
        news 1: *ComResident(id)    # 新增居民
        changes 2: *ComResident(id) # 更新居民
        removes 3: *uint32          # 删除居民
    }

    .ComWaitResident { # 投奔居民
        id 0: uint32 # 唯一id
        cfgId 1: uint32 # 配置表id
        isBring 2: boolean # 是否携带礼物的居民
    }

    .ComSyncWaitResident {
        news 1: *ComWaitResident(id)    # 新增投奔居民
        changes 2: *ComWaitResident(id) # 更新投奔居民
        removes 3: *uint32              # 删除投奔居民
    }

    .ComKichenFood { # 厨房食物
        cfgId 1: uint32        # 配置表id
        curVal 2: double       # 当前值
        settleTs 3: uint32     # 上一次结算时间戳
        produceRate 4: double  # 生产速度 N/h
    }

    .ComSyncKichenFood { # 厨房食物
        news 1: *ComKichenFood(cfgId)    # 新增食物
        changes 2: *ComKichenFood(cfgId) # 更新食物
    }

    .ComResidentDecree { # 政令
        decreeId 1: uint32  # 配置表id
        startTs 2: uint32 # 政令发布时间
        duration 3: uint32 # 政令持续时间 
    }

    .ComSyncResidentDecree {
        news 1: *ComResidentDecree(decreeId)
        changes 2: *ComResidentDecree(decreeId)
        removes 3: *integer
    }

    .ComInnerCityResident {
        isUnlock 0: boolean # 系统是否解锁
        cityTime 1: uint32 # 内城时间 0~1440
        startTime 2: uint32 # 现实时间戳
        waitings 3: *ComWaitResident(id) # 等待接收的居民列表
        residents 4: *ComResident(id) # 内城居民列表
        foodCfgId 5: uint32 # 选择厨房生产的食物
        foods 6: *ComKichenFood(cfgId) # 厨房食物
        decreeSt 7: uint32 # 政令状态
        isOpen 8: boolean # 照明是否开启
        isMax 9: boolean # 照明功率是否最大
    }

    .ComSyncDataInnerCityResident {
        isUnlock 0: boolean # 系统是否解锁
        cityTime 1: uint32 # 内城时间 0~1440
        startTime 2: uint32 # 现实时间戳
        waitings 3: ComSyncWaitResident # 等待接收的居民列表更新
        residents 4: ComSyncResident # 居民更新
        foodCfgId 5: uint32 # 选择厨房生产的食物
        foods 6: ComSyncKichenFood # 厨房食物更新
        decreeSt 7: uint32 # 政令状态
        isOpen 8: boolean # 照明是否开启
        isMax 9: boolean # 照明功率是否最大
    }

    .ComSatisfactionPoint {
        cfgId 0: uint32               # 资源配置id
        curVal 1: double              # 当前值
        settleTs 2: uint32            # 上一次结算时间戳
        speed 3: double               # 增长速度 达到上限时为0
    }
    
]]

cityResidentProto.c2s = cityResidentProto.struct .. [[
cityResidentDispatch 8001 { # 派遣居民到家具
    request {
        id 1: uint32 # 居民id
        buildId 2: uint32 # 建筑唯一id
        fId 3: uint32 # 家具唯一id
    }
    response {

    }
}

cityResidentRemove 8002 { # 从家具中移除居民
    request {
        id 1: uint32 # 居民id
    }
    response {

    }
}

cityResidentActiveSkill 8003 { # 激活居民技能
    request {
        id 1: uint32 # 居民id
        skillId 2: uint32 # 技能配置表Id
    }
    response {

    }
}

cityResidentUpdateStatus 8004 { # 更新居民状态 生病或者罢工
    request {
        id2Status 1: *ComUint32Uint32() # 居民id->状态值
    }
    response {

    }
}

cityResidentDead 8005 { # 居民死亡,体力值降为0
    request {
        ids 1: *uint32 # 居民id
    }
    response {

    }
}

cityResidentLeave 8006 { # 居民离开,心情值降为0
    request {
        ids 1: *uint32 # 居民id
    }
    response {

    }
}

cityResidentReceive 8007 { # 接收居民
    request {

    }
    response {

    }
}

cityResidentGetStoryReward 8008 { # 居民故事领奖
    request {
        id 1: uint32 # 居民id
        index 2: uint32 # 选项id
    }
    response {
        ress 1: *ComRes # 奖励
    }
}

cityResidentKichenMenu 8009 { # 选择厨房菜单
    request {
        cfgId 1: uint32 # 选择的生产的食物
    }
    response {
        cfgId 1: uint32 # 选择的生产的食物
    }
}

cityResidentEat 8010 { # 居民进餐
    request {
        num 1: uint32  # 消耗的食物数量
    }
    response {
        
    }
}

cityResidentPromulgateDecree 8011 { # 颁布政令
    request {
        decreeId 1: uint32 # 政令id
    }
    response {
        ress 1: *ComRes # 奖励
    }
}

guardTowerLightSwitch 8012 { #守护塔照明开关
    request {
        isOpen 1: boolean #true:开, false:关
    }
    response {
    }
}

guardTowerLightPower 8013 { #守护塔照明功率
    request {
        isMax 1: boolean #true:最大, false:基础
    }
    response {
    }
}

cityResidentReceiveGift 8014 { # 接收居民礼物
    request {
        id 1: uint32 # 居民id
    }
    response {
        ress 1: *ComRes # 奖励
    }
}
]]

cityResidentProto.s2c = cityResidentProto.struct .. [[


]]

return cityResidentProto