---
id: UXpersona-kai-Docs
title: Kai - Docs Page (Proxied Markdown App)
module: docs
related-requirements: [SFS-F-020]
related-apis: [GET /flexy/:id/docs/*]
related-personas: [persona-container-Dev, persona-kai-Operator]
related-stories: []
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
在 Kai 介面中透過反向代理存取 Flexy 容器內的 Docs/Markdown 應用（8080），以瀏覽與編輯專案的 `.md` 文件。

## Layout & Placement
- 置於 `UXL-main-content` 的內容區。
- 主要使用 `<iframe src="/flexy/:id/docs">`（或帶 path）。

## Interaction Model
1. 進入 `/flexy/:id/docs`。
2. 以 `<iframe>` 指向 `/flexy/:id/docs`；Kai 代理移除前綴並轉發到容器 `:8080` 根路徑。
3. 顯示 Docs UI；若目標不存在（容器無 Docs），顯示 404 頁面並提供返回。

## States
- loading：等待內容載入。
- empty：可選，顯示說明。
- error：404 / 500 顯示對應訊息與重試/返回。

## Traceability
- 對應 Kai SRS §3.2.2 與 SFS-F-020（可選）。
- 依 OpenAPI：`GET /flexy/{id}/docs/{path}`（HTTP 代理）。

## Figma Make Prompt
設計「Docs」頁面：標題列顯示專案/容器名稱，主要內容是一個全寬全高的 `<iframe>` 指向 `/flexy/:id/docs`。提供 loading skeleton 與 404/500 狀態畫面（404 含返回按鈕、500 含重試）。
