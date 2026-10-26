-- 联盟活动日历 8701 ～ 8720
local allianceActivityCalendarProto = {}

allianceActivityCalendarProto.struct = [[
    .ComActivityCalendar {
        actId 1: integer      # 活动id
        state 2: integer      # 活动状态 AllianceActivityCalendarEnum 1预约 2进行中 3结束
        updateTs 3: integer   # 时间戳
    }
]]

allianceActivityCalendarProto.c2s = allianceActivityCalendarProto.struct .. [[
    
]]

allianceActivityCalendarProto.s2c = allianceActivityCalendarProto.struct .. [[
    
]]

return allianceActivityCalendarProto