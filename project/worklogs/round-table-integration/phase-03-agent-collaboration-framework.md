# Phase 3: Agent 協作框架

## 完成日期
2025-04-17

## 實作內容

### 1. AgentCollaborationService 服務

**檔案**: `src/services/agent-collaboration.ts`

**核心功能**:

**協作會話管理**:
- `startCollaboration()`: 啟動新的協作會話
- `endCollaboration()`: 結束協作會話
- `getSession()`: 獲取會話資訊
- `listActiveSessions()`: 列出活躍會話
- `pauseSession()`: 暫停會話
- `resumeSession()`: 恢復會話

**參與者管理**:
- `addParticipant()`: 新增參與者到進行中的會話
- `removeParticipant()`: 從會話移除參與者
  - 當最後一位參與者移除時，自動結束會話

**能力請求**:
- `broadcastCapabilityRequest()`: 廣播能力請求到 Space
- `handleCapabilityResponse()`: 處理 Agent 的能力回應
- `findAgentsByCapability()`: 根據能力查找 Agents
- `getAgentSessions()`: 獲取 Agent 參與的會話

**消息功能**:
- `sendToSession()`: 發送消息到會話所有參與者
- `notifySession()`: 會話通知（不檢查狀態）

### 2. 輔助型別定義

**StartCollaborationRequest**: 啟動協作請求
```typescript
{
  spaceId: string;
  topic: string;
  participants: string[];
  initialMessage: Record<string, unknown>;
  initiator: string;
}
```

**CapabilityRequest**: 能力請求
```typescript
{
  spaceId: string;
  capability: string;
  query: Record<string, unknown>;
  requester: string;
  timeout?: number;
}
```

**CapabilityResponse**: 能力回應
```typescript
{
  agentId: string;
  agentName: string;
  capable: boolean;
  confidence?: number;
  reason?: string;
  metadata?: Record<string, unknown>;
}
```

**CollaborationMessage**: 協作消息
```typescript
{
  sessionId: string;
  fromAgent: string;
  content: Record<string, unknown>;
  timestamp: number;
}
```

### 3. CoworkingSpaceManager Phase 2 擴展

**檔案**: `src/services/coworking-space-manager.ts`

**新增屬性**:
- `roundTableClients`: Map<string, RoundTableClient>
- `spaceAgents`: Map<string, SpaceAgent[]>

**新增方法**:
- `enableCommunication()`: 啟用 Space 的 Round Table 通信
- `isCommunicationEnabled()`: 檢查通信是否啟用
- `getCommunicationConfig()`: 獲取通信配置
- `registerAgent()`: 註冊 Agent 到 Space
- `unregisterAgent()`: 從 Space 移除 Agent
- `getAgents()`: 獲取 Space 中的所有 Agents
- `getOnlineAgents()`: 獲取在線 Agents
- `findAgentsByCapability()`: 根據能力查找 Agents
- `broadcastToSpace()`: 廣播消息到 Space
- `sendToAgent()`: 直接發送給 Agent
- `getRoundTableClient()`: 獲取 Space 的 Round Table 客戶端
- `getAgentClient()`: 獲取 Agent 的 Round Table 客戶端

### 4. Round Table 基礎實作

**src/types/round-table.ts**:
- `RoundTableMessageType`: DIRECT, BROADCAST, TOPIC, SYSTEM
- `RoundTableConnectionState`: DISCONNECTED, CONNECTING, CONNECTED, ERROR
- `RoundTableMessage`: 消息結構
- `RoundTableClientConfig`: 客戶端配置
- `RoundTableConnectionEvent`: 連接事件
- `RoundTableMessageHandler`: 消息處理器
- `RoundTableConnectionHandler`: 連接事件處理器

**src/services/round-table-client.ts**:
- `connect()`: 連接到 Round Table 服務
- `disconnect()`: 斷開連接
- `sendDirect()`: 發送直接消息
- `broadcast()`: 廣播消息
- `subscribe()`: 訂閱主題
- `getSubscriptions()`: 獲取訂閱列表
- `onMessage()`: 註冊消息處理器
- `onConnection()`: 註冊連接事件處理器
- `getConnectionState()`: 獲取連接狀態
- `isConnected()`: 檢查是否已連接

## 技術細節

### 會話狀態管理

會話有三種狀態：
- `active`: 活躍中，可以接收和發送消息
- `paused`: 暫停中，保留會話但不活躍
- `completed`: 已結束，從快取中移除

### 參與者自動加入

啟動協作時，initiator 會自動加入 participants 列表（如果尚未在列表中）：

```typescript
const finalParticipants = request.participants.includes(request.initiator)
  ? request.participants
  : [...request.participants, request.initiator];
```

### 通知邏輯

對於會話結束狀態的通知，使用 `notifySession()` 方法而不是 `sendToSession()`，因為後者要求會話必須是 active 狀態。

## 測試結果

```bash
✓ tests/unit/agent-collaboration.test.ts  (20 tests) 3218ms
✓ tests/unit/coworking-space-manager.test.ts  (21 tests) 27ms
```

**測試覆蓋**:
- 協作會話管理 (6 個測試)
- 參與者管理 (5 個測試)
- 會話生命週期 (3 個測試)
- 能力請求 (4 個測試)
- 清理 (1 個測試)

## 檔案清單

### 新建檔案
- `src/types/round-table.ts` (72 lines)
- `src/services/round-table-client.ts` (192 lines)
- `src/services/agent-collaboration.ts` (465 lines)
- `tests/unit/agent-collaboration.test.ts` (434 lines)

### 修改檔案
- `src/services/coworking-space-manager.ts` (+230 lines for Phase 2 integration)
- `src/types/coworking-space.ts` (already had Phase 2 types)

**總計**: 約 1393 行新代碼

## 已知限制

1. **簡化的 Round Table 客戶端**: 目前是記憶體內實作，不包含實際的 WebSocket/HTTP 通信
2. **沒有實際的 Round Table 服務**: 測試中使用的是模擬實作
3. **能力回應等待**: 使用簡單的 setTimeout 等待回應，生產環境應使用 Promise/Future 機制

## 下一步

Phase 4: REST API
- 實作 CoworkingSpaceController
- 實作 AgentCollaborationController
- TSOA 路由生成
- API 文檔生成
- 契約測試

## 提交資訊

**Commit**: 待提交

**變更摘要**:
- Phase 2: CoworkingSpaceManager Round Table integration
- Phase 3: Agent collaboration framework implementation
