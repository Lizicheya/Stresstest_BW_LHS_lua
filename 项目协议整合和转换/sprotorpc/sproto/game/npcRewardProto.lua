-- 打野奖励展示 8051 ~ 8060
local npcRewardProto = {}

npcRewardProto.struct = [[

    #怪物奖励展示
    .ComNpcReward {
        id 0: integer            # 奖励id
        npcCfgId 1: integer      # npc配置id
        rewardList 2 : *ComRes   # 奖励列表
        costPs 3: integer        # 消耗体力
        firstKill 4: boolean     # 是否首杀
        isTeam 5: boolean        # 是否组队
        isTeamLeader 6: boolean  # 是否是队长
    }

    #怪物奖励同步
    .ComSyncNpcReward {
        news 1: *ComNpcReward(id)                 # 新增npc奖励列表
        #changes 2: *ComNpcReward                 # 更新npc奖励列表
        removes 3: *integer                       # 删除npc奖励id
    }

 ]]

npcRewardProto.c2s = npcRewardProto.struct .. [[
    getAllNpcReward 8051 {    #一键领取所有怪物奖励
        request {
        }
        response {
            ress 0: *ComRes    #奖励列表
        }
    }
]]

npcRewardProto.s2c = npcRewardProto.struct .. [[

]]

return npcRewardProto
