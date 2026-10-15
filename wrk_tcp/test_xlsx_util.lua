-- 独立测试 xlsx_util 读写能力
package.path = "lualib/?.lua;game_bw/?.lua;" .. package.path
local cjson = require "cjson"
local xlsx_util = require "protocol.xlsx_util"

print("=== 测试1: 读取模板 xlsx ===")
local wb, err = xlsx_util.read_xlsx("protocol/protocol_model-lhs.xlsx")
if not wb then
    print("读取失败:", err)
    os.exit(1)
end
print("读取成功, sheet 数量:", #wb.sheets and #wb.sheets or "n/a")
for name, sheet in pairs(wb.sheets) do
    print("  sheet:", name, "单元格数:", #sheet.cells)
end

print("\n=== 测试2: 检查控制页 ===")
local ctrl = wb.sheets["运行"]
if ctrl then
    print("找到控制页, 单元格数:", #ctrl.cells)
    -- 打印前几个单元格
    local count = 0
    for ref, val in pairs(ctrl.cells) do
        if count < 10 then
            print(string.format("  %s = %s", ref, tostring(val)))
            count = count + 1
        end
    end
else
    print("未找到控制页 '运行'")
end

print("\n=== 测试3: 写回测试 ===")
-- 在第一个 sheet 找一个空单元格写入测试值
local first_sheet = nil
for name, _ in pairs(wb.sheets) do
    first_sheet = name
    break
end
if first_sheet then
    local test_ref = "Z1"
    xlsx_util.set_cell(wb, first_sheet, test_ref, "test_ok")
    local out_path = "protocol/test_output.xlsx"
    local ok, e = xlsx_util.save_xlsx(wb, out_path)
    if ok then
        print("写入成功:", out_path)
        -- 重新读取验证
        local wb2, e2 = xlsx_util.read_xlsx(out_path)
        if wb2 then
            local val = wb2.sheets[first_sheet].cells[test_ref]
            print("回读验证:", test_ref, "=", tostring(val), val == "test_ok" and "✓" or "✗")
        else
            print("回读失败:", e2)
        end
    else
        print("写入失败:", e)
    end
end

print("\n=== 测试完成 ===")