---
id: pattern-container-001
title: 列表資源管理模式 (List-based Resource Management)
category: Container Management
related-flows: [flow-container-001, flow-container-002, flow-container-003, flow-container-004, flow-container-005]
description: |
  此模式定義了管理一組資源（例如容器）的標準互動流程。它包括從一個統一的列表視圖中進行查看、建立、狀態更新和刪除資源。
components:
  - Resource Table/List (資源列表)
  - 'Add New' Button (新增按鈕)
  - Creation Modal (建立資源的彈出式表單)
  - In-line Action Buttons (列表項內的行內操作按鈕，如啟動、停止、刪除)
  - Confirmation Dialog (用於破壞性操作的確認對話框)
  - Status Indicator (用於顯示資源狀態的指示器)
usage: |
  適用於任何需要讓使用者管理一組相似物件（如容器、專案、使用者）的場景，提供一致且高效的使用者體驗。
acceptance: |
  - 列表必須清晰地顯示每個資源的當前狀態。
  - 所有操作都應提供即時反饋（例如 loading 狀態、成功或失敗的提示訊息）。
  - 破壞性操作（如刪除）必須有使用者二次確認的步驟。
---
