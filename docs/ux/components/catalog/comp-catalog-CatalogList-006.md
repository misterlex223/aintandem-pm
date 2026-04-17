---
id: comp-catalog-CatalogList-006
title: Catalog List (Kai)
module: catalog
level: organism
parent: null
children: []
related-personas: [persona-container-Dev]
related-scenarios: [scenario-container-Dev-01]
related-stories: [story-kai-catalog-001]
related-requirements: [SFS-F-023]
related-patterns: [pattern-container-001]
states: [default, loading, empty, error]
variants: [card-grid, table]
a11y: List/table 可鍵盤導覽，操作按鈕具可見焦點。
responsiveness: 手機以單欄卡片呈現，桌面可表格模式。
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
顯示 Kai 持久化的 Flexy 專案 Catalog 清單，提供快捷操作（建立容器、開啟 Shell/Docs、刪除）。

## Composition
- 標題列與工具列（搜尋/篩選可選）。
- 清單列（卡片或表格）：name、hostPath、container 快捷操作。
- 空清單佈景：指引使用者建立第一個專案。

## Interaction Model
- 初始載入呼叫 `GET /api/catalog/flexy`。
- 快捷操作：
  - 建立容器 → 開啟 `CreateContainerModal`，預置 `folderMapping = hostPath:/workspace`。
  - 開啟 Shell/Docs → 導向 `/flexy/:id/shell` 或 `/flexy/:id/docs`（需容器存在）。
  - 刪除項目 → 二次確認 → `DELETE /api/catalog/flexy/{id}`。

## States & Feedback
- loading：骨架屏/Spinner。
- empty：引導文案與「新增專案」按鈕。
- error：錯誤訊息與重試。
- default：正常列表。

## Figma Make Prompt
設計一個 Catalog 清單（卡片/表格切換）。卡片上提供 name、hostPath、與三個操作：Create Container、Open Shell、Open Docs、Delete（視情況顯示/禁用）。
