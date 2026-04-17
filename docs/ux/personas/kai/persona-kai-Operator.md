---
id: persona-kai-Operator
title: Kai Operator (Catalog & Lifecycle)
role: DevOps / Senior Developer
experience: Intermediate–Advanced
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## Goals
- 管理團隊用的 Flexy Catalog（登錄專案 name + hostPath）。
- 建立/啟動/停止/刪除 Flexy 容器，確保環境一致。
- 透過 Kai 代理提供 Shell 與 Docs 的安全存取。

## Pain Points
- 專案目錄多且位置不一，易選錯路徑。
- 需避免對外暴露容器埠與錯誤的網路設定。

## Environment
- Linux/macOS 開發機，Docker 已安裝。
- 使用 Kai Web UI 與後端 API 進行日常管理。
