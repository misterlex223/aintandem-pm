---
id: comp-container-ContainerCard-002
title: Container Card
module: container
level: molecule
parent: comp-container-ContainerList-001
children: [comp-common-StatusBadge-005]
related-personas: [persona-container-Dev]
related-scenarios: [scenario-container-Dev-02, scenario-container-Dev-03]
related-stories: [story-container-Dev-001, story-container-Dev-003, story-container-Dev-004, story-container-Dev-005]
related-requirements: [CONTAINER-01, CONTAINER-03, CONTAINER-04, CONTAINER-05]
related-patterns: [pattern-container-001]
states: [default, disabled]
variants: []
a11y: Card should be focusable.
responsiveness: Card width adjusts to grid layout.
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-10
---

## Purpose
在列表中代表一個獨立的 Flexy 容器，集中顯示其核心資訊與可執行的操作。

## Composition
- **頂部**: 容器名稱和一個 `StatusBadge` (comp-common-StatusBadge-005)。
- **中部**: 顯示創建時間和 Folder mapping 路徑。
- **底部**: 一組操作按鈕：「進入 Shell」、「啟動/停止」、「刪除」。

## Interaction Model
- 使用者點擊卡片上的操作按鈕，觸發對應功能（啟動、停止、刪除、進入 Shell）。

## States & Feedback
- **default**: 顯示所有資訊和可用的操作按鈕。
- **disabled**: 當容器正在執行某個長時間操作（如建立中）時，卡片上的操作按鈕可能呈現禁用狀態。

## Figma Make Prompt
設計一個資訊卡片。頂部左側是容器名稱，右側是一個狀態徽章。中間區域顯示「創建時間」和「掛載路徑」。底部是一排水平排列的按鈕：「進入 Shell」、「啟動/停止」、「刪除」。
