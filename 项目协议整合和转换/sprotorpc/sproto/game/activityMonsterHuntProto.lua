local activityMonsterHuntProto = {}

activityMonsterHuntProto.struct = [[
    .MonsterHuntInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        isOver 3 : boolean # 是否结束
        groupId 4 : integer # 组 id
        challengeLevel 5 : integer # 挑战难度
        aliveNpcObjIds 6 : *integer # 存活的异兽场景对象 id 列表
        killedNpcCfgIds 7 : *integer # 已击杀的异兽配置 id 列表
        beHelpedNpcObjId 8 : integer # 被帮助的异兽场景对象 id
        numBehelped 9 : integer # 帮助异兽的次数
        joinAid 10 : integer # 参与的联盟 id
    }

    .compNpcData {
        uid 0 : integer # 成员 uid
        maxKilledNpcLv 1 : integer # 该成员击杀的最高怪物等级
        helpNpcObjId 2 : integer # 该成员请求帮助的 npcObjId
        challengeLevel 3: integer # 该成员选择的挑战难度
    }

    .compTaskFlags {
        taskId 0 : integer # 任务 id
        flags 1 : *integer # 任务完成标记列表
    }

    .AllianceMonsterHuntInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        isOver 3 : boolean # 是否结束
        groupId 4 : integer # 组 id
        joinMemberUids 5 : *integer # 参与的成员UID列表
        taskId2rewardFlags 6 : *compTaskFlags(taskId) # 任务 id 到 任务完成标记 列表的映射
        joinMemberUid2npcData 7 : *compNpcData(uid) # 参与成员对应的异兽数据
    }
]]

activityMonsterHuntProto.c2s = activityMonsterHuntProto.struct .. [[
    reqMHSelectChallengeLevel 8331 {  # 玩家选择挑战难度
        request {
            actId 0 : uint32 # 活动 id
            challengeLevel 1 : uint32 # 挑战难度
        }
        response {
        }
    }

    reqMHAddMonster 8332 {  # 玩家请求添加异兽到场景
        request {
            actId 0 : uint32 # 活动 id
        }
        response {
        }
    }

    reqMHClaimTaskReward 8333 {  # 玩家请求领取个人任务奖励
        request {
            actId 0 : uint32 # 活动 id
            taskId 1 : uint32 # 任务 id
        }
        response {
        }
    }

    reqMHClaimAllianceTaskReward 8334 {  # 玩家请求领取联盟任务奖励
        request {
            actId 0 : uint32 # 活动 id
            taskId 1 : uint32 # 任务 id
        }
        response {
        }
    }

    reqMHHelpOfMonsterHunt 8335 {  # 玩家请求帮助异兽
        request {
            actId 0 : uint32 # 活动 id
            npcObjId 1 : uint64 # 异兽场景对象 id
        }
        response {
        }
    }
]]

activityMonsterHuntProto.s2c = activityMonsterHuntProto.struct .. [[

]]

return activityMonsterHuntProto