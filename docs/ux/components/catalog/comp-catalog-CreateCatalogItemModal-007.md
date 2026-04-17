---
id: comp-catalog-CreateCatalogItemModal-007
title: Create Catalog Item Modal (Kai)
module: catalog
level: molecule
parent: UXpersona-kai-Catalog
children: [comp-common-DirectoryPicker-006]
related-personas: [persona-container-Dev]
related-stories: [story-kai-catalog-002]
related-requirements: [SFS-F-024, SFS-F-022]
states: [default, submitting, error]
a11y: 表單欄位具 aria-label，錯誤訊息與對應欄位關聯。
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
建立新的 Catalog 項目，輸入 `name` 與 `hostPath`，支援使用目錄挑選器安全選擇路徑。

## Fields
- name: text, required, 1–64。
- hostPath: text, required, 絕對路徑；附帶 DirectoryPicker 呼叫（使用 `POST /api/host/directories`）。

## Interaction
- 提交 → 呼叫 `POST /api/catalog/flexy`。
- 成功 → 關閉並刷新清單，顯示成功 Toast。
- 失敗 → 顯示欄位錯誤（400）、衝突（409）、或一般錯誤（500）。

## Validation
- name 非空白且長度限制。
- hostPath 為絕對路徑；可以即時檢核。

## Error Handling
- 顯示 API 回覆的錯誤訊息；提供重試或取消。

## Figma Make Prompt
設計「Create Catalog Item」Modal：標題、兩個欄位（name、hostPath），hostPath 欄右側有「瀏覽」按鈕（開啟 DirectoryPicker）。底部為 Cancel 與 Create 兩個按鈕。提供表單驗證錯誤顯示、提交中狀態，以及 API 錯誤的提示區塊。
