---
id: UXpersona-kai-Catalog
title: Kai - Catalog Management Page
module: catalog
related-requirements: [SFS-F-023, SFS-F-024, SFS-F-025, SFS-F-022]
related-apis: [GET /api/catalog/flexy, POST /api/catalog/flexy, DELETE /api/catalog/flexy/{id}, POST /api/host/directories]
related-personas: [persona-container-Dev]
related-stories: [story-kai-catalog-001, story-kai-catalog-002]
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
集中管理 Kai 持久化的 Flexy 專案清單（Catalog）。支援：瀏覽、建立（輸入 name 與 hostPath，含目錄挑選器）、刪除 Catalog 項目，並可從 Catalog 快速建立對應的容器或導覽至 Shell/Docs。

## Layout & Placement
- 置於主佈局 `UXL-main-content` 之主內容區。
- 頁面結構：
  - 頁首：標題「Flexy Catalog」與「新增專案」按鈕。
  - 內容：`CatalogList`（卡片或表格），顯示 name、hostPath、container 快捷動作。

## Primary Actions
- 新增專案（Open `CreateCatalogItemModal`）
- 刪除專案（確認對話框）
- 從專案建立容器（重用 `CreateContainerModal`；預設將 hostPath 映射至容器 `/workspace`）
- 開啟 Shell（若容器存在）
- 開啟 Docs（若容器存在且啟用 Docs App）

## Interaction Model
1. 首次載入：呼叫 `GET /api/catalog/flexy` 取得清單；顯示 loading → 渲染列表。
2. 新增：點擊「新增專案」→ Modal 填寫 `name`、`hostPath`（可使用目錄挑選器，走 `POST /api/host/directories`）→ 呼叫 `POST /api/catalog/flexy` → 成功後刷新列表。
3. 刪除：在某卡片上點擊刪除 → 二次確認 → 呼叫 `DELETE /api/catalog/flexy/{id}` → 成功後移除該列並顯示 toast。
4. 建立容器：在卡片上點擊「建立容器」→ 開啟 `CreateContainerModal`（預置 `folderMapping: <hostPath>:/workspace`）→ 建立完成後提供「開啟 Shell」捷徑。

## States
- loading：骨架屏或 spinner。
- empty：顯示文案「尚未建立任何專案，點擊『新增專案』開始」。
- error：顯示錯誤與重試。
- default：列表顯示。

## Validation & Errors
- `name` 必填，長度 1–64。
- `hostPath` 必填，必須為絕對路徑。
- API 錯誤碼對應顯示（400/409/500），並提供重試或返回。

## Traceability
- 對齊 Kai SRS 3.3 與 Kai SFS 1.7。
- 對應 OpenAPI `GET/POST/DELETE /api/catalog/flexy` 與 `POST /api/host/directories`。

## Figma Make Prompt
設計一個「Flexy Catalog」頁面：頁首為標題與「新增專案」主動作按鈕；內容區可切換卡片/表格兩種視圖。每個項目顯示 name、hostPath 與四個動作：Create Container、Open Shell、Open Docs、Delete。空清單時顯示引導文案與大型「新增專案」按鈕。提供 loading skeleton 與錯誤狀態（含重試）。
