# 規格審查與調整紀錄 (Spec Review & Adjustments)

- **日期**: 2025-09-16
- **目標**: 根據 `SRS-Integrated.md`、`docs/specs/srs.md` 與 `Flexy/docs/specs/srs.md` 更新 `docs/specs/sfs.md`。

## 分析與決策

1.  **結構調整**: 原 `SFS.md` 主要關注 Kai。為反映整合後的需求，新的 SFS 將明確區分 **Kai (平台)** 與 **Flexy (容器)** 的功能規格。
2.  **新增 Flexy 內部規格**: 從 `Flexy/docs/specs/srs.md` 提取 Markdown Docs App 的詳細功能需求 (專案管理、索引、檔案 API 等)，並將其納入 SFS 的 Flexy 章節。
3.  **新增 Flexy 容器規格**: 從 `SRS-Integrated.md` (F-CTX-1 至 4) 提取對 Flexy 容器本身的要求 (ttyd, Gemini CLI, Docs App)，明確寫入 SFS。
4.  **更新非功能需求 (NFR)**: 整合所有 SRS 文件中的 NFR，特別是 Flexy Docs App 的性能指標 (如索引時間)。
5.  **更新追溯矩陣**: 擴展追溯矩陣，使其能對應到 `SRS-Integrated.md`、Kai `SRS.md` 和 Flexy `SRS.md` 中的具體章節，確保所有需求的可追溯性。
6.  **釐清模糊點**: 
    - **目錄瀏覽安全**: 明確 `POST /api/host/directories` 端點必須嚴格限制在使用者 home 目錄下，並進行路徑正規化以防止越權存取。
    - **持久化策略**: 確認 Kai 的 Flexy Catalog 持久化機制，並在 SFS 中定義其 API (`/api/catalog/flexy`)。

## 下一步

- 根據以上分析，使用 `replace_file_content` 工具全面更新 `docs/specs/sfs.md` 的內容。
