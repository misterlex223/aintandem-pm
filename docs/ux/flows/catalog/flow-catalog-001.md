---
id: flow-catalog-001
title: Catalog Management Flow (Kai)
module: catalog
related-requirements: [SFS-F-023, SFS-F-024, SFS-F-025, SFS-F-022]
related-apis: [GET /api/catalog/flexy, POST /api/catalog/flexy, DELETE /api/catalog/flexy/{id}, POST /api/host/directories, POST /api/flexy]
actors: [使用者, 系統]
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Flow 步驟
1. 使用者開啟「Flexy Catalog」頁面（`UXpersona-kai-Catalog`）。
2. 系統呼叫 `GET /api/catalog/flexy` 載入 Catalog 清單，呈現 loading 狀態。
3. 若成功，渲染 `CatalogList`（卡片/表格）。若為空，顯示空清單提示。
4. 使用者點擊「新增專案」→ 開啟 `CreateCatalogItemModal`。
5. 使用者輸入 `name` 與 `hostPath`，或使用 `DirectoryPicker`（走 `POST /api/host/directories` 瀏覽 home-scoped 目錄）。
6. 送出後呼叫 `POST /api/catalog/flexy`，成功則關閉 Modal 並刷新清單。
7. 使用者可在清單項目上點擊「刪除」→ 二次確認 → 呼叫 `DELETE /api/catalog/flexy/{id}` → 成功則移除該列。
8. 使用者可在清單項目上點擊「建立容器」→ 開啟 `CreateContainerModal`（預置 `folderMapping = <hostPath>:/workspace`）→ 呼叫 `POST /api/flexy` 建立容器 → 成功後提供「開啟 Shell/Docs」捷徑。

## 例外情境
- `GET /api/catalog/flexy` 失敗 → 顯示錯誤與重試按鈕。
- `POST /api/catalog/flexy` 400/409 → 在 Modal 顯示欄位錯誤或衝突提示。
- `DELETE /api/catalog/flexy/{id}` 404 → 顯示項目已不存在並刷新。
- 目錄挑選器上捲/越權嘗試 → 由後端拒絕，UI 顯示提示（home-scoped）。

## Traceability
- 對應 Kai SRS 3.3 Flexy Catalog 與 Kai SFS 1.7。
- API 參考 `docs/specs/api/openapi.yaml`。
