---
id: story-container-Dev-001
type: user-story
module: container
persona: Dev
status: todo
---

## User Story

作為一個開發者，我希望能看到一個所有 Flexy 容器的列表，以便我能快速掌握目前所有開發環境的狀態。

## Acceptance Criteria

### Functional
- [ ] 系統必須在主頁面顯示一個容器列表。
- [ ] 列表中的每個項目都必須顯示容器名稱、狀態（如 running, stopped）、創建時間、以及資料夾掛載路徑。
- [ ] 列表應提供一個按鈕或連結，用於新增容器。

### Non-Functional
- [ ] 列表頁面載入時間應少於 3 秒。
- [ ] 列表狀態應能透過手動刷新即時更新。
