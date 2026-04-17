---
id: scenario-kai-Dev-01
type: scenario
module: kai
persona: persona-kai-Dev
---

## Scenario: 快速啟動新專案的開發環境

- **使用環境**: Alex 在他的開發機上，準備開始一個新的功能開發，程式碼位於 `~/projects/new-feature`。

- **行為動機**: 他需要一個隔離的、包含 Gemini CLI 的 shell 環境來進行開發和測試，並且不希望手動編寫 `docker run` 指令來設定 volume mounts 和網路。

- **操作流程**:
  1. 打開 Kai 的 Web UI。
  2. 點擊「新增 Flexy」。
  3. 在 Modal 中，輸入名稱「new-feature」，並使用目錄瀏覽器選擇本機的 `~/projects/new-feature` 路徑掛載到容器的 `/workspace`。
  4. 點擊「建立」，等待容器啟動。
  5. 在儀表板上找到「new-feature」容器，點擊「進入 Shell」。

- **預期成果**: 在 1 分鐘內，Alex 就能在瀏覽器中得到一個功能齊全、程式碼已掛載的 shell 終端，並可以開始工作。
