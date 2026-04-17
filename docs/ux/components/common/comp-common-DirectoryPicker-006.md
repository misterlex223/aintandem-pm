---
id: comp-common-DirectoryPicker-006
title: Directory Picker (Kai)
module: common
level: molecule
parent: null
children: []
related-requirements: [SFS-F-022]
related-apis: [POST /api/host/directories]
states: [default, loading, error]
a11y: Breadcrumb 與清單可鍵盤操作；focus 明顯。
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
安全地在使用者 home 目錄下瀏覽並選擇資料夾，配合 `POST /api/host/directories`（後端限制 home-scoped 與路徑正規化）。

## Composition
- 目前路徑 Breadcrumb（不可超出 home root）。
- 子目錄清單。
- 選擇按鈕（回傳選中的絕對路徑）。

## Interaction
- 點擊子目錄 → 呼叫 `POST /api/host/directories` 取得下一層。
- 點擊 Breadcrumb 節點 → 回到指定層級。
- 點擊「選擇」→ 將目前路徑回傳給父層表單。

## Error Handling
- 超出 home 的請求或路徑 traversal → 後端回 403/400，UI 顯示禁止訊息。

## Figma Make Prompt
設計「Directory Picker」對話框：上方為 Breadcrumb（home 起點，無法向上超出），下方為當前路徑之子目錄清單（附資料夾圖示）。每列可點擊切換路徑。右下角提供 Cancel 與 Select 按鈕。顯示 loading skeleton 與錯誤提示區塊。
