# Round Table 整合 - 架構文檔化

**日期**: 2025-01-17
**階段**: Documentation
**狀態**: Completed

## 背景

在討論 ce-orchestrator 與 Round Table 的整合架構時，我們確認了一個重要的設計哲學：

> **Round Table 是通訊層，ce-orchestrator 是資源協調層**

這個分層架構之前沒有被正式記錄在文檔中。

## 完成的工作

### 1. 創建 ADR (Architecture Decision Records)

**文件**: `repos/ce-orchestrator/docs/ADR/001-round-table-integration.md`

內容包括：
- **Context**: 為什麼需要整合 Round Table
- **Decision**: 採用兩層架構分離
- **Rationale**:
  - 關注點分離
  - 語境整合是關鍵差異
  - 可測試性與可維護性
  - 可替換性與可重用
- **Consequences**: 正面和負面影響分析
- **Alternatives**: 其他方案的評估

### 2. 創建架構層次說明

**文件**: `repos/ce-orchestrator/docs/architecture/layers.md`

詳細說明：
- 層次職責定義
- 數據流向圖（Agent 註冊、協作會話）
- 接口邊界
- 為什麼這樣分層
- 實際案例展示

### 3. 創建目錄 README

**文件**:
- `repos/ce-orchestrator/docs/ADR/README.md`
- `repos/ce-orchestrator/docs/architecture/README.md`

提供：
- 文檔索引
- 架構原則
- 快速導航

## 架構總結

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                          │
│                  External AI Agents                          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│              Resource Coordination Layer                     │
│                   ce-orchestrator                            │
│  • 資源註冊 (Agent Registry)                                 │
│  • 能力匹配 (Capability Discovery)                           │
│  • 配額管理 (Quota Management)                               │
│  • 語境關聯 (Workspace/Project Integration)                  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                   Communication Layer                        │
│                    Round Table                               │
│  • 消息路由 (Message Routing)                                │
│  • Pub/Sub 訂閱                                              │
│  • WebSocket 連接管理                                        │
└─────────────────────────────────────────────────────────────┘
```

## 關鍵洞察

1. **Round Table 不「住」agents**
   - Agents 是外部運行的獨立程序
   - Space 內的 agents 只是註冊記錄

2. **ce-orchestrator 是協調者，不是宿主**
   - 提供資源管理和協調服務
   - 不運行 agents 本身

3. **兩層架構的優勢**
   - 清晰的職責邊界
   - 可獨立演進
   - 可測試、可替換

## 文件結構

```
repos/ce-orchestrator/docs/
├── ADR/
│   ├── README.md
│   └── 001-round-table-integration.md
└── architecture/
    ├── README.md
    └── layers.md
```

## 後續工作

建議創建更多 ADR 記錄：
- [ ] ADR 002: CoworkingSpace 抽象設計
- [ ] ADR 003: Provider 抽象層設計
- [ ] ADR 004: Agent 認證與授權機制

## 參考

- [ADR 001](../../../repos/ce-orchestrator/docs/ADR/001-round-table-integration.md)
- [架構層次說明](../../../repos/ce-orchestrator/docs/architecture/layers.md)
- [MCP 整合計劃](./mcp-integration-plan.md)
