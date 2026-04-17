---
id: comp-kai-ContainerListItem-002
title: Container List Item
module: kai
level: molecule
parent: "comp-kai-ContainerList-001"
children: []
related-personas: ["persona-kai-Dev"]
related-scenarios: ["scenario-kai-Dev-01"]
related-stories: ["story-kai-Dev-001"]
related-requirements: ["KAI-01", "KAI-02"]
related-patterns: ["pattern-kai-001"]
states: ["default", "hover"]
variants: []
status: final
---

## Purpose／目的
在容器列表中代表單一一個 Flexy 容器，顯示其核心資訊並提供操作入口。

## Composition／組成
- `ContainerName` (文字)
- `StatusBadge` (狀態標籤，例如 running/stopped)
- `InfoText` (顯示 ID 和掛載路徑)
- `ActionButtons` (一組按鈕：啟動/停止、Shell、刪除)

## Interaction Model／互動模型
- 滑鼠懸停 (`hover`) 時，整個項目應有視覺反饋（如背景色變化）。
- 點擊「啟動/停止」、「刪除」按鈕會觸發對應的後端 API 請求。
- 點擊「進入 Shell」按鈕會觸發頁面導航。

## States & Feedback／狀態與回饋
- **default**: 正常顯示資訊。
- **hover**: 顯示背景色或邊框，提示為可互動區域。

## Figma Make Prompt／雛型提示詞
Create a list item card. It includes a main title, a small status badge (e.g., 'Running' in green), some secondary info text below the title, and a row of three action buttons ('Start/Stop', 'Shell', 'Delete') on the right.
