--
-- author: TQING<tqing1128@gmail.com>
-- date: 2023-09-20 11:38:40
--

local activityStrongestLord = {}

activityStrongestLord.struct = [[
    .StrongesLordStageData {
        selectScoreId 0 : integer # 选择的积分 id, 可选的才有
        score 1 : integer # 积分
        rank 2 : integer # 排名
    }

    .StrongesLordStageDataHash {
        stage 0 : integer
        data 1 : StrongesLordStageData
    }

    .StrongesLordData {
        curStage 0 : integer # 当前阶段
        scoreTotal 1 : integer # 总积分
        rankTotal 2 : integer # 总排名
        stageData 3 : *StrongesLordStageDataHash() # 阶段数据
        scoreClaimData 4 : ComActivityScoreClaimData # 积分数据
    }

    .StrongesLordParam {
        configGroupId 0 : integer # 活动配置组 Id
    }

    .StrongesLordInfo {
        actId 0 : integer # 活动 id
        round 1 : integer # 轮次
        state 2 : integer # 状态
        param 3 : StrongesLordParam # 参数
        data 4 : StrongesLordData
    }
]]

activityStrongestLord.c2s = activityStrongestLord.struct .. [[
    # 选择积分 id
    strongestLordSelectScoreWay 6401 {
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            scoreWayId 2 : uint32 # 积分 id
        }
        response {
        }
    }

    # 领取积分奖励
    strongestLordGetScoreReward 6402 {
        request {
            actId 0 : uint32 # 活动 id
            stage 1 : uint32 # 阶段
            index 2 : uint32 # 奖励索引
        }
        response {
            dropRes 0: *ComRes              # 获得的奖励
            newClaimList 1: *ComIntInt()    # 领取情况增量更新
        }
    }
]]

activityStrongestLord.s2c = activityStrongestLord.struct .. [[

]]

return activityStrongestLord