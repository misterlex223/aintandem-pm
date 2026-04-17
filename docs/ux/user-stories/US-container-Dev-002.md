---
id: story-container-Dev-002
type: user-story
module: container
persona: Dev
status: todo
---

## User Story

作為一個開發者，我希望能透過一個簡單的表單建立一個新的 Flexy 容器，並指定名稱與資料夾掛載，以便我能快速啟動一個新的隔離開發環境。

## Acceptance Criteria

### Functional
- [ ] UI 上必須有一個「新增 Flexy」的按鈕。
- [ ] 點擊按鈕後，會出現一個表單，包含「容器名稱」和「Folder mapping」輸入欄位。
- [ ] 「容器名稱」為必填。
- [ ] 「Folder mapping」為選填，格式為 `/host/path:/container/path`。
- [ ] 提交表單後，新的容器會出現在列表中，狀態為 running。

### Non-Functional
- [ ] 建立容器的過程不應超過 1 分鐘。
- [ ] 若建立失敗，應在 UI 上顯示明確的錯誤訊息。
