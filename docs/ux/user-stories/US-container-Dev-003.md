---
id: story-container-Dev-003
type: user-story
module: container
persona: Dev
status: todo
---

## User Story

作為一個開發者，我希望能直接在容器列表中啟動或停止一個 Flexy 容器，以便我能有效管理本地系統資源。

## Acceptance Criteria

### Functional
- [ ] 列表中的每個容器項都應有「啟動」或「停止」按鈕，根據容器當前狀態顯示。
- [ ] 點擊「啟動」後，容器狀態應變為 running。
- [ ] 點擊「停止」後，容器狀態應變為 stopped。

### Non-Functional
- [ ] 狀態變更應在 5 秒內反映在 UI 上。
