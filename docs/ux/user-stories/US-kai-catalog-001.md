---
id: story-kai-catalog-001
title: 登錄專案到 Catalog（name + hostPath）
actor: persona-kai-Operator
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## As a
Kai Operator

## I want
將本機專案（絕對路徑）與名稱登錄到 Kai 的 Catalog 中

## So that
後續可直接從 Catalog 建立 Flexy 容器（主機路徑自動映射到 `/workspace`）

## Acceptance Criteria
- 表單欄位：name 必填、hostPath 必填且為絕對路徑。
- 送出後呼叫 `POST /api/catalog/flexy` 成功回 201 並在 UI 顯示該項目。
- 重複名稱或相同路徑（依策略）回傳 409 並提示。
- 支援使用 `POST /api/host/directories` 安全挑選路徑。
