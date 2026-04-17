---
id: flow-container-004
title: 刪除容器流程
module: container
related-requirements: [CONTAINER-04]
actors: [使用者, 系統]
status: final
---

## Flow 步驟
1. 使用者在容器列表中找到目標容器，並點擊「刪除」按鈕。
2. 系統彈出一個確認對話框，詢問「是否確定要刪除此容器？」。
3. 使用者點擊「確認刪除」。
4. 系統向後端 API (`DELETE /api/flexy/:id`) 發送刪除請求。
5. 系統接收到成功回應。
6. 系統將該容器從列表中移除。
7. (分支) 若使用者在步驟 3 點擊「取消」，則關閉對話框，流程結束。
