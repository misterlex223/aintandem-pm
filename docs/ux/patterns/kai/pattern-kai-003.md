---
id: pattern-kai-003
title: 嵌入式終端介面模式
category: Content Display
related-flows: [flow-kai-001]
description: |
  將一個功能完整的終端機（如 ttyd）透過 `<iframe>` 或類似技術嵌入到網頁中，讓使用者可以在不離開當前應用的情況下執行命令列操作。
components:
  - IFrame (嵌入容器)
  - LoadingIndicator (載入指示器)
usage: |
  適用於需要提供 Shell 存取權限的開發者工具或管理平台。
acceptance: |
  - 嵌入的終端機必須功能完整，能正確處理鍵盤輸入與 WebSocket 連線。
  - 介面應在載入完成前顯示 Loading 狀態。
  - 應能正確處理代理路徑，確保 `<iframe>` 的 `src` 指向正確的後端服務。
---
