---
id: UXL-main-app
title: Main Application Layout
module: kai
related-patterns: [pattern-kai-001, pattern-kai-003]
related-flows: [flow-kai-001]
status: final
---

# Layout: Main Application Layout

## 1. Purpose

此 Layout 為 Kai 應用的主要骨架，提供一個一致性的頂部導航區和一個彈性的主內容區，適用於應用內所有頁面。

## 2. Structure

- **Header**: 位於頁面頂部，固定高度。包含應用程式 Logo/標題，以及可能的全局操作或使用者資訊。
- **Content Area**: 位於 Header 下方，佔據剩餘的頁面空間。用於承載不同頁面的主要內容，例如儀表板表格、嵌入的 Shell 介面等。

## 3. Variants

- **Default**: 標準的 Header + Content 結構。
- **Full-Screen Content**: 在特定頁面（如 Shell 介面），Content Area 可以擴展至全螢幕，Header 可以最小化或隱藏，以提供沉浸式體驗。

## 4. Components Mapping

- **Header**: 
  - `ApplicationLogo`
  - `NavigationMenu` (可選)
- **Content Area**:
  - 可承載 `ResourceDashboard` (由 `pattern-kai-001` 衍生)
  - 可承載 `EmbeddedTerminal` (由 `pattern-kai-003` 衍生)

## 5. Example Pages

- 容器儀表板頁面
- Shell 頁面
- Docs 頁面
