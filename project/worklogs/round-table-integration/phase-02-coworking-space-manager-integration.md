# Phase 2: CoworkingSpaceManager 整合 Round Table

## 完成日期
2025-04-17

## 實作內容

### 1. CoworkingSpaceManager 擴展

**新增屬性**:
- `roundTableClients`: Map<string, RoundTableClient> - Round Table 客戶端映射
- `spaceAgents`: Map<string, SpaceAgent[]> - Space 中的 Agents

**新增方法**:

**通信管理**:
- `enableCommunication(spaceId, config)`: 啟用 Space 的 Round Table 通信
- `isCommunicationEnabled(spaceId)`: 檢查通信是否啟用
- `getCommunicationConfig(spaceId)`: 獲取通信配置

**Agent 管理**:
- `registerAgent(spaceId, agent)`: 註冊 Agent 到 Space
- `unregisterAgent(spaceId, agentId)`: 從 Space 移除 Agent
- `getAgents(spaceId)`: 獲取 Space 中的所有 Agents
- `getOnlineAgents(spaceId)`: 獲取在線 Agents
- `findAgentsByCapability(spaceId, capability)`: 根據能力查找 Agents

**消息功能**:
- `broadcastToSpace(spaceId, fromAgent, content)`: 廣播消息到 Space
- `sendToAgent(spaceId, fromAgent, toAgent, content)`: 直接發送給 Agent

**客戶端管理**:
- `getRoundTableClient(spaceId)`: 獲取 Space 的 Round Table 客戶端
- `getAgentClient(spaceId, agentId)`: 獲取 Agent 的 Round Table 客戶端

### 2. 型別定義擴展

**CoworkingSpace 介面擴展**:
```typescript
export interface CoworkingSpace {
  // ... 原有欄位
  communicationConfig?: SpaceCommunicationConfig;
  agents?: SpaceAgent[];
}
```

**新增型別**:
- `SpaceCommunicationConfig`: 通信配置
- `SpaceAgent`: Space 中的 Agent
- `SpaceMessage`: 空間消息
- `CollaborationSession`: 協作會話
- `CreateSpaceWithCommunicationRequest`: 帶通信配置的創建請求
- `UpdateSpaceWithCommunicationRequest`: 帶通信配置的更新請求

### 3. Round Table 基礎型別

**核心型別** (src/types/round-table.ts):
- `RoundTableMessage`: 消息結構
- `RoundTableClientConfig`: 客戶端配置
- `RoundTableConnectionState`: 連接狀態
- `RoundTableConnectionEvent`: 連接事件
- `RoundTableMessageHandler`: 消息處理器類型
- `RoundTableConnectionHandler`: 連接事件處理器類型
- `AgentCapability`: Agent 能力聲明

### 4. Round Table 客戶端 (簡化版)

**src/services/round-table-client.ts** - 簡化實作:
- 連接管理: `connect()`, `disconnect()`
- 消息功能: `sendDirect()`, `broadcast()`
- 訂閱管理: `subscribe()`, `getSubscriptions()`
- 事件處理: `onMessage()`, `onConnection()`
- 狀態查詢: `getConnectionState()`, `isConnected()`

### 5. 單元測試

**tests/unit/coworking-space-manager-roundtable.test.ts**:
- 通信配置測試 (3 個測試)
- Agent 管理測試 (7 個測試)
- 消息功能測試 (4 個測試)
- 客戶端管理測試 (2 個測試)

**總計**: 15 個測試，全部通過 ✅

## 技術細節

### Space 級別的 Round Table 整合

```typescript
// Space 作為系統 Agent
const spaceClientConfig: RoundTableClientConfig = {
  baseUrl: commConfig.roundTableUrl,
  workspaceId: commConfig.workspaceId,
  agentId: `space-${spaceId}`,  // Space 本身也是一個 Agent
  seatToken: process.env.ROUND_TABLE_SEAT_TOKEN,
};
```

### Agent 註冊流程

1. 驗證 Space 存在且通信已啟用
2. 檢查匿名 Agent 政策
3. 添加 Agent 到 Space 的 agents 列表
4. 如果 Agent 有 seatToken，創建專屬客戶端
5. 訂閱 Agent 的 topics

### 消息路由

```typescript
// Space 級別消息路由
client.onMessage(async (message: RoundTableMessage) => {
  await this.handleSpaceMessage(spaceId, message);
});
```

## 測試結果

```bash
✓ tests/unit/coworking-space-manager-roundtable.test.ts  (15 tests) 96ms
```

所有測試通過！

## 已知限制

1. **簡化的 Round Table 客戶端**: 當前是簡化實作，不包含實際的 WebSocket/HTTP 通信
2. **沒有實際的 Round Table 服務**: 測試中使用的是模擬實作
3. **消息路由簡化**: `handleSpaceMessage` 只是打印日誌

## 下一步

Phase 3: Agent 協作框架

- 實作 AgentCollaborationService
- 協作會話管理
- 能力發現與匹配
- 跨空間協作支援
- 相關單元測試

## 提交資訊

**Commit**: `4fb9a61`
**Message**: feat: implement Phase 2 - CoworkingSpaceManager Round Table integration

## 檔案清單

### 修改檔案
- `src/services/coworking-space-manager.ts` (+220 lines)
- `src/types/coworking-space.ts` (+140 lines)

### 新建檔案
- `src/types/round-table.ts` (106 lines)
- `src/services/round-table-client.ts` (155 lines)
- `tests/unit/coworking-space-manager-roundtable.test.ts` (400+ lines)

**總計**: 約 1021 行新代碼
