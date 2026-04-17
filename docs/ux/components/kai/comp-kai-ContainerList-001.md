---
id: comp-kai-ContainerList-001
title: Container List
module: kai
level: organism
parent: null
children: ["comp-kai-ContainerListItem-002"]
related-personas: ["persona-kai-Dev"]
related-scenarios: ["scenario-kai-Dev-01"]
related-stories: ["story-kai-Dev-001"]
related-requirements: ["KAI-01"]
related-patterns: ["pattern-kai-001"]
states: ["loading", "default", "empty"]
variants: ["table", "card"]
status: final
---

## Purpose／目的
此元件用於顯示所有 Flexy 容器的列表，讓使用者可以快速概覽所有環境的狀態並執行基本操作。

## Context／使用脈絡
出現在容器儀表板頁面的主要內容區域，是使用者進入應用的第一個互動核心。

## Composition／組成
- 一個 `SearchInput` 元件用於篩選。
- 一個 `CreateButton` (新增 Flexy) 元件。
- 一個列表區域，由多個 `ContainerListItem` 元件組成。

## Interaction Model／互動模型
- 頁面載入時，此元件顯示 `loading` 狀態，並向後端請求資料。
- 資料載入後，渲染 `ContainerListItem` 列表。
- 在 `SearchInput` 中輸入文字，列表會即時篩選出名稱符合的項目。

## States & Feedback／狀態與回饋
- **loading**: 顯示骨架屏 (Skeleton Screen)。
- **default**: 顯示容器列表。
- **empty**: 當沒有任何容器時，顯示「目前沒有任何 Flexy 容器，請點擊『新增 Flexy』來建立一個。」的提示訊息。

## Figma Make Prompt／雛型提示詞
Create a dashboard component. At the top, place a search bar on the left and a 'New Flexy' button on the right. Below, create a list of items. Each item should have a title, a status badge, and a group of action buttons.
