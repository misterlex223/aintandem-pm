---
id: story-kai-catalog-002
title: 由 Catalog 項目一鍵建立容器並開啟 Shell/Docs
actor: persona-container-Dev
status: final
owner: ux@team
version: 0.1
last_reviewed: 2025-09-15
---

## As a
Developer

## I want
在 Catalog 清單上直接建立容器並開啟 Shell 或 Docs

## So that
我能快速進入工作環境與文件編輯

## Acceptance Criteria
- 於 Catalog 列上提供「建立容器」動作：預置 `folderMapping = <hostPath>:/workspace`，呼叫 `POST /api/flexy`。
- 建立成功後可直接點擊「Open Shell」→ `/flexy/:id/shell`；如有 Docs → `/flexy/:id/docs`。
- 錯誤回應以 toast 顯示，並可重試。
