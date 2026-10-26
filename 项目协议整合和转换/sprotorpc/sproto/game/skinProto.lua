-- 皮肤（装饰） 6301 ~ 6400
local skinProto = {}

skinProto.struct = [[
    .ComSkinCulture {
        collectLv 0: integer                    # 收藏等级
        collectExp 1: integer                   # 收藏经验
    }

    .ComSkin {
        skinCfgId 0: integer                    # 配置id
        lv 1: integer                           # 当前等级

        # 现在皮肤的激活状态（是否可以使用）要根据以下几个状态综合判断
        own 2: integer                          # =1 已永久拥有皮肤
        expaireTime 3: integer                  # 过期时间, 0 也是已过期
        condActive 4: integer                   # =1 条件激活了皮肤 

        bApply 5: boolean                       # 是否应用中
        conditionRecord 6: *ComIntInt()         # 达成过的条件对应配置下标
        collectExpRecord 7: *ComIntInt()        # 收藏获得的经验下标
    }

    .ComSkinData {
        cellList 1: *ComIntInt()                            # 槽位使用情况
        skinCulture 2: ComSkinCulture                       # 养成功能
        skinList 3: *ComSkin(skinCfgId)                     # 皮肤列表
        cliamLvReward 4: *ComIntInt()                       # 奖励领取情况
        splicingReward 5: *ComIntInt()                      # 拼装奖励领取情况
        haloRecord 6: *ComIntInt()                          # 光环记录
        applyHalo 7: integer                                # 生效光环id（套装id）
    }

    .ComSyncSkin {
        news 1: *ComSkin(skinCfgId)             # 新增皮肤
        changes 2: *ComSkin(skinCfgId)          # 皮肤变动
        removes 3: integer                      # 移除皮肤
    }
    
    .ComSyncSkinPack {
        skinList 0: ComSyncSkin
    }    

    .ComAttrBySource {
        skinAttrSourceType 1: integer
        attrs 2: *ComIntInt()
    }
    
    .ComAttrBySkinType {
        skinType 1: integer
        attrs 2: *ComIntInt()
    }
]]

skinProto.c2s = skinProto.struct..[[
    reqSkinCollectLvReward 6301 { # 领取收藏等级奖励
        request {
            level 0: uint32
        }
        response {
            dropRes 1: *ComRes          # 本次奖励
        }
    }

    reqSkinUp 6302 { # 应用皮肤（装饰）
        request {
            skinCfgId 0: uint32
        }
        response {
        }
    }

    reqSkinSplicingReward 6303 { # 请求拼装奖励(皮肤模块作为入口，调用到兑换模块)
        request {
            id 0: uint32                   # id(合成配置ID)
            count 1: uint32                # 合成数量
        }
        response {
            dropRes 1: *ComRes          # 本次奖励
        }
    }

    reqSkinUpgrade 6304 { # 请求升级皮肤
        request {
            skinCfgId 0: uint32 # 要升级的皮肤
            secondType 1: boolean # 是否选择第二种升级消耗
        }
        response {
        }
    }

    reqUpSetOneKey 6305 { # 请求一键穿戴套装
        request {
            skinSetCfgId 0: uint32 # 要穿戴的套装id
        }
        response {
        }
    }

    reqAttrBySource 6306 { # 从来源请求属性
        request {
            skinAttrSourceTypeList 0: *uint32 # ref:SkinAttrSourceType
        }
        response {
            attrBySource 0: *ComAttrBySource()
        }
    }

    reqAttrBySkinType 6307 { # 从装扮类型请求属性
        request {
            skinAttrSkinTypeList 0: *uint32 # ref:SkinType
        }
        response {
            baseAttrBySkinType 0: *ComAttrBySkinType()
            upgradeAttrBySkinType 1: *ComAttrBySkinType()
        }
    }
    
    reqAttrDetail 6308 {
        request {
            skinAttrSourceTypeList 0: *uint32 # ref:SkinAttrSourceType
            skinAttrSkinTypeList 1: *uint32 # ref:SkinType
        }
        response {
            attrBySource 0: *ComAttrBySource()

            baseAttrBySkinType 1: *ComAttrBySkinType()
            upgradeAttrBySkinType 2: *ComAttrBySkinType()
        }
    }
]]

skinProto.s2c = skinProto.struct..[[
    #syncSkinData 6311 { # 皮肤修改同步 --弃用， 改为从 syncPlayerInfo 中同步
    #    request {
    #        skinList 0: ComSyncSkin # 皮肤信息同步
    #    }
    #    response {
    #    }
    #}

    syncSkinCulture 6312 { # 养成数据同步
        request {
            skinCulture 0: ComSkinCulture # 养成功能
        }
        response {
        }
    }

    syncSkinCliamLvReward 6313 { # 奖励领取同步
        request {
            cliamLvReward 0: *ComIntInt() # 奖励领取情况
        }
        response {
        }
    }

    syncSkinSplicingReward 6314 { # 拼装奖励领取同步
        request {
            splicingReward 0: *ComIntInt() # 奖励领取情况
        }
        response {
        }
    }

    syncSkinSetHaloRecord 6315 { # 光环记录同步
        request {
            skinSetHaloRecord 0: *ComIntInt() # 光环记录同步
        }
        response {
        }
    }
    syncSkinApplyHalo 6316 { # 同步当前生效中的光环
        request {
            applyHalo 0: integer # 光环id（套装id）
        }
        response {
        }
    }
]]

return skinProto