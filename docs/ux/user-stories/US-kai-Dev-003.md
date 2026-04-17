---
id: story-kai-Dev-003
type: user-story
module: kai
persona: persona-kai-Dev
status: todo
---

## User Story

作為一名開發者 (Alex)，
我希望能一鍵從儀表板進入任何 Flexy 容器的 Web Shell，
以便我能立即開始執行指令和編碼。

## Acceptance Criteria

### Functional
- [ ] 點擊「進入 Shell」按鈕後，應在 `/flexy/:id/shell` 路徑開啟一個內嵌的終端機介面。
- [ ] 終端機必須功能完整，能正確處理 WebSocket 連線。
- [ ] 終端機中的工作目錄應預設為掛載的 `/workspace`。

### Non-Functional
- [ ] Shell 介面的載入和連線時間應在 3 秒內完成。
