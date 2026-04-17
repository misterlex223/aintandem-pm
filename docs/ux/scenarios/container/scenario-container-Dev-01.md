---
id: scenario-container-Dev-01
type: scenario
module: container
persona: Dev
---

## Scenario: 建立新的開發環境

- **使用環境**: 開發者在自己的本地端電腦上，透過 Web 瀏覽器使用 Kai 平台。

- **行為動機**: 需要為一個新專案或新任務建立一個乾淨、隔離的 AI Agent (Flexy) 開發環境，並將本地的專案程式碼目錄掛載進去。

- **操作流程**: 
  1. 開啟 Kai Web UI。
  2. 點擊「新增 Flexy」按鈕。
  3. 在表單中為新環境輸入一個好記的名稱（例如：`project-alpha-dev`）。
  4. 輸入本地專案目錄與容器內目標路徑的對應關係（例如：`/Users/lex/projects/alpha:/app`）。
  5. 點擊「建立」按鈕。

- **預期成果**: 新的 Flexy 容器在一分鐘內成功建立並啟動，並立即出現在容器列表上，狀態為「running」。
