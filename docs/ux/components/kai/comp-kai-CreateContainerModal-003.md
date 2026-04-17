---
id: comp-kai-CreateContainerModal-003
title: Create Container Modal
module: kai
level: organism
parent: null
children: []
related-personas: ["persona-kai-Dev"]
related-scenarios: ["scenario-kai-Dev-01"]
related-stories: ["story-kai-Dev-002"]
related-requirements: ["KAI-03"]
related-patterns: ["pattern-kai-002"]
states: ["default", "loading"]
variants: []
status: final
---

## Purpose／目的
提供一個不中斷使用者當前頁面心流的介面，來建立一個新的 Flexy 容器。

## Composition／組成
- `Modal` 容器
- `Form` 包含：
  - `TextInput` for '名稱'
  - `TextInput` with a `BrowseButton` for '資料夾掛載'
- `SubmitButton` ('建立')
- `CancelButton` ('取消')

## Interaction Model／互動模型
- 使用者填寫表單欄位。
- 點擊「建立」按鈕後，表單進入 `loading` 狀態，按鈕變為不可用。
- 建立成功後，Modal 關閉，並觸發儀表板刷新。
- 建立失敗後，在 Modal 內顯示錯誤訊息，`loading` 狀態結束。

## States & Feedback／狀態與回饋
- **default**: 顯示表單供使用者輸入。
- **loading**: 提交按鈕顯示載入中動畫，表單欄位不可編輯。

## Figma Make Prompt／雛型提示詞
Create a modal dialog titled 'Create New Flexy'. Inside, include a text input for 'Name', another text input for 'Folder Mapping' with a 'Browse' button next to it. At the bottom, add a 'Cancel' button and a primary 'Create' button.
