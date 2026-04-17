---
id: flow-container-002
title: 建立新容器流程
module: container
related-requirements: [CONTAINER-02]
actors: [使用者, 系統]
status: final
---

## Flow 步驟
1. 使用者在容器列表頁面點擊「新增 Flexy」按鈕。
2. 系統彈出一個包含「容器名稱」和「Folder mapping」欄位的表單 Modal。
3. 使用者填寫表單內容。
4. 使用者點擊「建立」按鈕。
5. 系統驗證表單欄位。
6. (異常) 若驗證失敗（例如名稱重複、路徑格式錯誤），系統在 Modal 內顯示錯誤提示，流程終止。
7. 系統向後端 API (`POST /api/flexy`) 發送建立請求，並在「建立」按鈕上顯示 loading 狀態。
8. 系統接收到成功回應後，關閉 Modal。
9. 系統刷新容器列表，顯示新建立的容器。
10. (異常) 若後端 API 回傳錯誤，系統在 Modal 內顯示錯誤訊息，loading 狀態解除。
