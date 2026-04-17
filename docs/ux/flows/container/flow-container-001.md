---
id: flow-container-001
title: 查看容器列表流程
module: container
related-requirements: [CONTAINER-01]
actors: [使用者, 系統]
status: final
---

## Flow 步驟
1. 使用者開啟 Kai 平台 Web UI。
2. 系統向後端 API (`GET /api/flexy`) 發起請求以獲取容器列表。
3. 系統顯示一個 loading 狀態。
4. 後端 API 回傳容器列表資料。
5. 系統在主介面渲染容器列表，顯示每個容器的名稱、狀態等資訊。
6. (異常) 若 API 請求失敗，系統在列表區域顯示錯誤訊息。
