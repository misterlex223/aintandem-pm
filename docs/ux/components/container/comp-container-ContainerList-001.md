---
id: comp-container-ContainerList-001
title: Container List
module: container
level: organism
parent: null
children: [comp-container-ContainerCard-002]
related-personas: [persona-container-Dev]
related-scenarios: [scenario-container-Dev-01, scenario-container-Dev-02, scenario-container-Dev-03]
related-stories: [story-container-Dev-001]
related-requirements: [CONTAINER-01]
related-patterns: [pattern-container-001]
states: [default, loading, empty, error]
variants: [card-grid]
a11y: List should be navigable via keyboard.
responsiveness: Switches to a single-column layout on smaller screens.
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-10
---

## Purpose
此元件用於顯示所有由 Kai 管理的 Flexy 容器，讓使用者能快速概覽所有開發環境的狀態。

## Context
作為主儀表板的核心，位於 `UXL-main-content` 佈局的主要內容區域。

## Composition
- 一個頁面標題，顯示「Flexy 管理」。
- 一個「新增 Flexy」按鈕。
- 一個由多個 `ContainerCard` (comp-container-ContainerCard-002) 組成的網格或列表。

## Interaction Model
- **頁面載入**: 元件向後端請求容器列表數據。
- **數據刷新**: 提供手動刷新功能，以獲取最新的容器狀態。

## States & Feedback
- **loading**: 載入數據時，顯示骨架屏 (Skeleton) 或加載指示器。
- **empty**: 若無任何容器，顯示「尚未建立任何容器，點擊『新增 Flexy』開始」的提示訊息。
- **error**: 若後端 API 請求失敗，顯示錯誤訊息及重試按鈕。
- **default**: 正常顯示容器卡片列表。

## Figma Make Prompt
設計一個容器管理儀表板。頂部是標題「Flexy 管理」和一個「新增 Flexy」按鈕。下方是一個卡片網格，用於展示多個容器的資訊。
