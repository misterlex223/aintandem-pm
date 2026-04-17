---
id: UXpersona-kai-CreateContainer
title: Kai - Create Container Page (Wizard)
module: container
related-requirements: [SFS-F-014, SFS-F-022]
related-apis: [POST /api/flexy, POST /api/host/directories]
related-personas: [persona-container-Dev, persona-kai-Operator]
related-stories: []
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
以頁面導向的表單（或一步驟精簡流程）建立新的 Flexy 容器。預設將 `folderMapping` 設為 `<hostPath>:/workspace`，以符合 Kai × Flexy 整合規則。

## Layout & Placement
- 置於主佈局 `UXL-main-content` 的內容區，路由建議：`/flexy/new`。
- 主要內容：
  - 欄位區：`name`、`hostPath`（附 DirectoryPicker）、摘要顯示即將使用的 `folderMapping`。
  - 操作區：建立、取消。

## Interaction Model
1. 使用者進入 `/flexy/new`。
2. 填入 `name`。
3. 透過文字輸入或 `DirectoryPicker` 選擇 `hostPath`（使用 `POST /api/host/directories`）。
4. 預覽 `folderMapping = <hostPath>:/workspace`（唯讀，說明規則可在 Flexy 設定中調整）。
5. 送出 → `POST /api/flexy` 建立容器。
6. 成功後提供按鈕：開啟 Shell（`/flexy/:id/shell`）、開啟 Docs（`/flexy/:id/docs`，如有）。

## Validation & Errors
- `name` 1–64 字。
- `hostPath` 必須為絕對路徑。
- API 失敗（400/409/500）顯示對應錯誤訊息。

## Traceability
- SFS: `SFS-F-014` 建立容器、`SFS-F-022` 目錄挑選。
- SRS: §3.2.1 Containers；OpenAPI: `POST /api/flexy`、`POST /api/host/directories`。

## Figma Make Prompt
設計「建立容器」頁：左側為兩個欄位 name 與 hostPath（hostPath 欄位右側有「瀏覽」按鈕，打開一個目錄選擇對話框）；下方顯示一行唯讀文字「folderMapping: <hostPath>:/workspace」。頁面底部有取消與建立兩個按鈕。建立成功後顯示連結前往 Shell 與 Docs。
