---
id: UXpersona-kai-Dashboard
title: Container Dashboard Page
module: kai
related-flows: ["flow-kai-001"]
related-requirements: ["KAI-01", "KAI-02", "KAI-03"]
related-layout: "UXL-main-app"
---

# Page: Container Dashboard

## 1. Page Purpose
此頁面是應用的主入口，提供一個集中檢視和管理所有 Flexy 容器的儀表板。

## 2. Layout
- **採用 Layout**: `UXL-main-app`
- **Layout 結構**: Header + Main Content Area

## 3. Page Structure
- **Header**: 顯示應用程式標題「Kai」。
- **Main Content Area**: 承載 `ContainerList` 元件，填滿主要內容區域。

## 4. Components Used
- `comp-kai-ContainerList-001`: 作為此頁面的核心元件，負責顯示和管理容器列表。
- `comp-kai-CreateContainerModal-003`: 由 `ContainerList` 中的「新增 Flexy」按鈕觸發顯示。

## 5. Interaction Flow
- 頁面載入時，`ContainerList` 顯示 loading 狀態並獲取資料。
- 使用者可以透過列表中的搜尋框篩選容器。
- 使用者可以點擊「新增 Flexy」按鈕來觸發 `CreateContainerModal`。
- 使用者可以對列表中的每個項目執行啟動、停止、刪除或進入 Shell 的操作。

## 6. Variants / States
- **Loading**: 頁面主要內容區顯示 `ContainerList` 的骨架屏。
- **Empty**: 當沒有容器時，`ContainerList` 顯示空狀態提示。
- **Error**: 如果後端 API 無法連線，在頁面頂部顯示一個全局的錯誤橫幅。
