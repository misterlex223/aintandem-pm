---
id: comp-common-ConfirmationDialog-004
title: Confirmation Dialog
module: common
level: molecule
parent: null
children: []
related-personas: [persona-container-Dev]
related-scenarios: [scenario-container-Dev-02]
related-stories: [story-container-Dev-004]
related-requirements: [CONTAINER-04]
related-patterns: [pattern-container-001]
states: [default, loading]
variants: [destructive, normal]
a11y: Dialog should trap focus and be properly announced by screen readers.
responsiveness: Centered and responsive.
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-10
---

## Purpose
用於在執行破壞性或不可逆操作前，向使用者進行二次確認，以防止誤操作。

## Composition
- 一個對話框 (Alert Dialog) 元件。
- 一個標題（例如「確認刪除」）。
- 一段描述文字（例如「您確定要刪除此容器嗎？此操作無法復原。」）。
- 「取消」和「確認」兩個按鈕。

## Interaction Model
- 使用者點擊「確認」以繼續操作，或點擊「取消」關閉對話框。

## Variants & Rules
- **destructive**: 當用於刪除等危險操作時，「確認」按鈕應使用紅色等警示色。

## Figma Make Prompt
設計一個確認對話框。包含一個標題、一段說明文字，以及「取消」和紅色的「確認刪除」兩個按鈕。
