-- test_xlsx_entry.lua
-- 临时测试入口:在 init 阶段验证 xlsx_util 读写能力

local xlsx_util = require "protocol.xlsx_util"

local M = {}

function M.init(id, connections)
    print("=== xlsx_util 验证开始 ===")

    -- 测试1: 读取模板
    local wb, err = xlsx_util.read_xlsx("game_bw/protocol/protocol_model-lhs.xlsx")
    if not wb then
        print("FAIL: 读取失败:", err)
        return
    end
    local sheet_count = 0
    for _ in pairs(wb.sheets) do sheet_count = sheet_count + 1 end
    print("PASS: 读取成功, sheet 数量:", sheet_count)
    for name, sheet in pairs(wb.sheets) do
        local cell_count = 0
        for _ in pairs(sheet.cells) do cell_count = cell_count + 1 end
        print(string.format("  sheet: %s, 单元格数: %d", name, cell_count))
    end

    -- 测试2: 控制页
    local ctrl = wb.sheets["运行"]
    if ctrl then
        print("PASS: 找到控制页 '运行'")
        local count = 0
        for ref, val in pairs(ctrl.cells) do
            if count < 8 then
                print(string.format("  %s = %s", ref, tostring(val)))
                count = count + 1
            end
        end
    else
        print("FAIL: 未找到控制页 '运行'")
    end

    -- 测试3: 写入并回读
    local test_sheet = nil
    for name, _ in pairs(wb.sheets) do
        test_sheet = name
        break
    end
    if test_sheet then
        local test_ref = "Z1"
        local test_val = "test_ok_" .. os.time()
        xlsx_util.set_cell(wb, test_sheet, test_ref, test_val)
        local out_path = "game_bw/protocol/test_output.xlsx"
        local ok, e = xlsx_util.save_xlsx(wb, out_path)
        if ok then
            print("PASS: 写入成功:", out_path)
            local wb2, e2 = xlsx_util.read_xlsx(out_path)
            if wb2 then
                local val = wb2.sheets[test_sheet].cells[test_ref]
                if val == test_val then
                    print("PASS: 回读验证成功", test_ref, "=", val)
                else
                    print("FAIL: 回读值不匹配, 期望:", test_val, "实际:", tostring(val))
                end
            else
                print("FAIL: 回读失败:", e2)
            end
        else
            print("FAIL: 写入失败:", e)
        end
    end

    print("=== xlsx_util 验证结束 ===")
end

-- 空实现,避免 wrk 调用时报错
function M.connected(fd) end
function M.writeable(fd) return "", -1, false end
function M.readable(fd, buffer, sz) return -2, 0 end
function M.delay(fd) return 100 end
function M.heartbeat(fd) end

return M