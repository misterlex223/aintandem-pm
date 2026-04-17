---
id: comp-common-StatusBadge-005
title: Status Badge
module: common
level: atom
parent: comp-container-ContainerCard-002
children: []
related-personas: [persona-container-Dev]
related-stories: [story-container-Dev-001]
related-requirements: [CONTAINER-01]
related-patterns: [pattern-container-001]
states: []
variants: [running, stopped, error]
a11y: The badge text should be readable.
responsiveness: Font size may scale down slightly on very small screens.
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-10
---

## Purpose
以視覺化的方式，清晰地標示出資源（如容器）的當前狀態。

## Composition
- 一個帶有圓角的背景色塊。
- 一段簡短的狀態文字。

## Variants & Rules
- **running**: 綠色背景，文字為「Running」。
- **stopped**: 灰色背景，文字為「Stopped」。
- **error**: 紅色背景，文字為「Error」。

## Figma Make Prompt
設計一個狀態徽章。它是一個帶圓角的標籤，根據不同狀態（Running, Stopped, Error）顯示不同的顏色（綠、灰、紅）和文字。
