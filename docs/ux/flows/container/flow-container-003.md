---
id: flow-container-003
title: 啟動與停止容器流程
module: container
related-requirements: [CONTAINER-03]
actors: [使用者, 系統]
status: final
---

## Flow 步驟
1. 使用者在容器列表中找到目標容器。
2. 使用者點擊該容器的「啟動」或「停止」按鈕。
3. 系統在按鈕上顯示 loading 狀態，並向後端 API (`POST /api/flexy/:id/start` 或 `stop`) 發送請求。
4. 系統接收到成功回應。
5. 系統更新該容器在列表中的狀態顯示（例如，從 `stopped` 變為 `running`），並更新按鈕文字。
6. (異常) 若 API 操作失敗，系統彈出錯誤提示，且 UI 狀態恢復原狀。
