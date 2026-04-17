---
id: pattern-kai-001
title: 資源儀表板模式
category: Data Display & Management
related-flows: [flow-kai-001]
description: |
  用於展示一組資源（如容器、使用者、文章）的列表，並提供搜尋、篩選以及對單一項目執行操作（如建立、讀取、更新、刪除）的標準介面模式。
components:
  - DataTable / CardList (資源列表)
  - SearchInput (搜尋框)
  - FilterDropdown (篩選器)
  - ActionButtons (操作按鈕組)
  - CreateButton (新增按鈕)
usage: |
  適用於任何需要管理一組同質資源的場景，例如容器管理、使用者管理等。
acceptance: |
  - 必須能清晰地展示資源的關鍵狀態。
  - 必須提供快速找到特定資源的方法（搜尋/篩選）。
  - 對單一資源的操作入口必須直觀可見。
---
