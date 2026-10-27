import fs from "node:fs/promises";
import { SpreadsheetFile, Workbook } from "file:///C:/Users/DELL/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs";

const rows = [
  ["Đối tượng", "Đọc sản phẩm", "Sửa sản phẩm", "Xóa sản phẩm", "Đọc đơn hàng", "Tạo đơn", "Báo cáo", "Nhập kho"],
  ["role_store_admin", "GRANT", "GRANT", "Không cấp", "GRANT qua view", "GRANT", "GRANT", "GRANT"],
  ["role_store_staff", "GRANT qua view", "Không cấp trực tiếp", "DENY", "GRANT qua view", "Không cấp trực tiếp", "GRANT qua view", "GRANT procedure"],
  ["role_report_viewer", "GRANT qua view", "DENY", "DENY", "GRANT qua view", "DENY", "GRANT", "DENY"],
  ["phone_app", "GRANT qua view", "Không cấp trực tiếp", "DENY", "GRANT qua view", "GRANT procedure", "Không cấp trực tiếp", "Không cấp trực tiếp"],
];
const wb = Workbook.create();
const sheet = wb.worksheets.add("Permission Matrix");
sheet.getRange("A1:H5").values = rows;
sheet.getRange("A1:H1").format = { fill: "#5969E8", font: { bold: true, color: "#FFFFFF" }, horizontalAlignment: "Center", wrapText: true };
sheet.getRange("A2:A5").format = { font: { bold: true, color: "#17213A" } };
sheet.getRange("B2:H5").format = { horizontalAlignment: "Center", wrapText: true };
sheet.getRange("A1:H5").format.borders = { style: "continuous", color: "#DCE3F5" };
sheet.getRange("A1:H5").format.autofitColumns();
sheet.getRange("A1:H5").format.autofitRows();
sheet.freezePanes.freezeRows(1);
sheet.showGridLines = false;
wb.recalculate();
const out = await SpreadsheetFile.exportXlsx(wb);
await out.save("C:/Users/DELL/Dropbox/PC/Downloads/HQT/permission_matrix.xlsx");
