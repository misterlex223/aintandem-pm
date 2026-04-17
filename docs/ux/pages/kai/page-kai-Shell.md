---
id: UXpersona-kai-Shell
title: Shell Page
module: kai
related-flows: ["flow-kai-001"]
related-requirements: ["KAI-02"]
related-layout: "UXL-main-app"
---

# Page: Shell Page

## 1. Page Purpose
此頁面為使用者提供一個嵌入式的、功能完整的 Web Shell 介面，以便直接在瀏覽器中與指定的 Flexy 容器進行互動。

## 2. Layout
- **採用 Layout**: `UXL-main-app`
- **Layout 結構**: Header + Main Content Area。在 Shell 頁面，Header 可以最小化，Content Area 應佔據絕大部分可視空間以提供沉浸式體驗。

## 3. Page Structure
- **Header**: 顯示應用程式標題，並提供一個「返回儀表板」的導航連結。
- **Main Content Area**: 承載一個 `<iframe>` 元件，該元件填滿整個內容區域。

## 4. Components Used
- `IFrame`: 用於嵌入由 Kai 後端代理的 ttyd 終端機介面。

## 5. Interaction Flow
1.  使用者從儀表板點擊容器的「進入 Shell」按鈕後，導航至此頁面 (`/flexy/:id/shell`)。
2.  頁面載入時，顯示一個 Loading 指示器。
3.  `<iframe>` 的 `src` 指向後端代理路徑，開始載入 ttyd 介面。
4.  連線成功後，Loading 指示器消失，使用者可以在 `<iframe>` 中看到並操作終端機。
5.  如果連線失敗，則顯示錯誤訊息和「重試」按鈕。

## 6. Variants / States
- **Loading**: 頁面主要內容區顯示一個 Loading 動畫，提示「正在連接到終端機...」。
- **Default**: 成功載入 `<iframe>`，顯示終端機介面。
- **Error**: 若容器不存在或代理失敗，顯示錯誤訊息（例如「無法連接到容器」）和一個「返回儀表板」的按鈕。

## 7. References
- **Layouts**: UXL-main-app
- **Patterns**: pattern-kai-003
- **Flows**: flow-kai-001
- **Requirements**: requirements-kai