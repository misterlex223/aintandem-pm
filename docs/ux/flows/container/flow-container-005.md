---
id: flow-container-005
title: 存取容器 Shell 流程
module: container
related-requirements: [CONTAINER-05]
actors: [使用者, 系統]
status: final
---

## Flow 步驟
1. 使用者在容器列表中找到一個狀態為 `running` 的容器。
2. 使用者點擊該容器的「進入 Shell」按鈕。
3. 系統導航至該容器的 Shell 頁面 (URL: `/flexy/{id}/shell`)。
4. 頁面載入後，前端透過後端反向代理與目標容器的 ttyd 服務建立 WebSocket 連線。
5. 系統在頁面中渲染出一個功能完整的終端機介面。
6. (異常) 若 WebSocket 連線失敗，系統在頁面中顯示「無法連接到容器 Shell」的錯誤訊息。
