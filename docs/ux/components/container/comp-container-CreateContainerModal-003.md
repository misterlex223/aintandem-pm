---
id: comp-container-CreateContainerModal-003
title: Create Container Modal
module: container
level: organism
parent: null
children: []
related-personas: [persona-container-Dev]
related-scenarios: [scenario-container-Dev-01]
related-stories: [story-container-Dev-002]
related-requirements: [CONTAINER-02]
related-patterns: [pattern-container-001]
states: [default, loading, error]
variants: []
a11y: Modal should trap focus. All fields should have labels.
responsiveness: Modal should be centered and responsive to screen size.
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-10
---

## Purpose
提供一個讓使用者可以快速建立新 Flexy 容器的介面。

## Composition
- 一個 Modal/Dialog 元件。
- 一個標題「新增 Flexy」。
- 一個包含「容器名稱」（Input）和「Folder mapping」（Textarea）的表單。
- 「建立」和「取消」兩個操作按鈕。

## Interaction Model
- 使用者填寫表單，點擊「建立」提交。
- 提交時，「建立」按鈕顯示 loading 狀態。
- 成功後，Modal 自動關閉。
- 失敗時，在表單下方顯示錯誤訊息。

## States & Feedback
- **loading**: 「建立」按鈕被禁用並顯示 loading 指示器。
- **error**: 在表單下方或欄位旁顯示具體的錯誤訊息（例如「名稱已存在」）。
- **default**: 顯示空白表單供使用者填寫。

## Figma Make Prompt
設計一個彈出視窗 (Modal)。標題是「新增 Flexy」。內容包含兩個輸入欄位，分別標示為「容器名稱」和「Folder mapping」。底部有「取消」和「建立」兩個按鈕。
