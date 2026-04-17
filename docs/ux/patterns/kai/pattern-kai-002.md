---
id: pattern-kai-002
title: 彈窗建立表單模式
category: Forms & Input
related-flows: [flow-kai-001]
description: |
  當使用者需要建立新資源時，在當前頁面以彈出式視窗（Modal）提供一個表單，避免頁面跳轉打斷使用者心流。
components:
  - Modal (彈窗容器)
  - Form (表單)
  - TextInput (文字輸入框)
  - FilePicker / DirectoryBrowser (目錄選擇器)
  - SubmitButton (提交按鈕)
  - CancelButton (取消按鈕)
usage: |
  適用於建立新物件的流程，特別是當表單欄位不多（2-5個）時，能提供流暢的體驗。
acceptance: |
  - Modal 必須能被輕易關閉（例如點擊外部或按 ESC）。
  - 表單提交時應有明確的處理中狀態。
  - 提交成功後 Modal 應自動關閉，並觸發父頁面的資料刷新。
  - 提交失敗時，應在 Modal 內顯示錯誤訊息。
---
