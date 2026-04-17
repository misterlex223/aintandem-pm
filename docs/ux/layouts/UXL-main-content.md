# Layout: Main Content Layout
ID: UXL-main-content
Related Patterns: [pattern-container-001]
Related Flows: [flow-container-001, flow-container-002, flow-container-003, flow-container-004]

## 1. Purpose
- 此 Layout 提供一個標準的單頁應用程式骨架，適用於以內容為中心的頁面，例如儀表板或管理列表。
- 解決的問題是提供一個一致的頂部導航區域和一個彈性的主內容區域。

## 2. Structure
- **Header**: 位於頁面頂部，固定高度。用於放置 Logo、系統名稱或主要導航連結。
- **Main Content**: 佔據頁面剩餘的主要空間。用於承載核心功能，例如資源列表、表單或詳細資訊。

## 3. Variants
- **Standard**: 預設變體，包含 Header 和 Main Content。
- **Contained**: Main Content 區域有一個最大寬度，並在頁面中水平置中，適用於需要限制內容寬度的頁面。

## 4. Components Mapping
- **Header**: 可承載 `SiteLogo`, `PrimaryNavigation` 等元件。
- **Main Content**: 可承載 `ResourceTable`, `CreationModal`, `PageTitle` 等元件。

## 5. Example Pages
- **Container Dashboard**: 整個 Kai 應用程式的主要頁面。

## 6. References
- Patterns: pattern-container-001
- Flows: flow-container-001, flow-container-002, flow-container-003, flow-container-004
- Components: (待定)
