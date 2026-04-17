# Round Table 整合到 AInTandem CoworkingSpace

## Context

AInTandem 的願景是成為一個「人與 AI 的 Coworking Space」，而 Round Table 提供了完整的 AI Agent 協作基礎設施。本計劃將兩者整合，建立一個完整的協作平台。

## 架構設計

### 整合架構

```
┌─────────────────────────────────────────────────────────────────┐
│                    AInTandem Coworking Platform                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 CoworkingSpaceManager                     │  │
│  │  • createSpace() / removeSpace()                         │  │
│  │  • getSpaceStatus() / monitorAllSpaces()                │  │
│  │  • enableCrossSpaceRouting()                             │  │
│  │  • checkQuota() / allocateResource()                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│           ┌───────────────┼───────────────┐                    │
│           ▼               ▼               ▼                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐          │
│  │ LocalSpace   │ │AliyunGZSpace │ │  FutureSpace │          │
│  │              │ │              │ │              │          │
│  │ ┌──────────┐ │ │ ┌──────────┐ │ │              │          │
│  │ │ Round    │ │ │ │ Round    │ │ │              │          │
│  │ │ Table    │ │ │ │ Table    │ │ │              │          │
│  │ │ Message  │ │ │ │ Message  │ │ │              │          │
│  │ │ Bus      │ │ │ │ Bus      │ │ │              │          │
│  │ └──────────┘ │ │ └──────────┘ │ │              │          │
│  │              │ │              │ │              │          │
│  │ Agents:      │ │ Agents:      │ │              │          │
│  │ • Claude     │ │ • Claude     │ │              │          │
│  │ • Qwen       │ │ • Qwen       │ │              │          │
│  │ • User       │ │ • User       │ │              │          │
│  └──────────────┘ └──────────────┘ └──────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │   Round Table Service        │
              │   (Redis + FastAPI)          │
              │                               │
              │  ┌────────────────────────┐  │
              │  │ Message Router         │  │
              │  │ • Pub/Sub (Real-time)  │  │
              │  │ • Queue (Reliable)     │  │
              │  └────────────────────────┘  │
              │                               │
              │  ┌────────────────────────┐  │
              │  │ Auth Service           │  │
              │  │ • User JWT Tokens      │  │
              │  │ • Agent Seat Tokens    │  │
              │  └────────────────────────┘  │
              │                               │
              │  ┌────────────────────────┐  │
              │  │ Service Registry       │  │
              │  │ • Agent Discovery      │  │
              │  │ • Health Check         │  │
              │  └────────────────────────┘  │
              └───────────────────────────────┘
```

## 核心型別定義

### Space 擴展：加入通信能力

```typescript
// src/types/coworking-space.ts (擴展)

export interface SpaceCommunicationConfig {
  enabled: boolean;
  roundTableUrl?: string;           // Round Table 服務 URL
  workspaceId?: string;             // Round Table workspace ID
  allowAnonymousAgents: boolean;    // 允許匿名 Agent
}

export interface SpaceAgent {
  agentId: string;
  agentName: string;
  agentType: 'claude' | 'qwen' | 'custom';
  seatToken?: string;               // Round Table seat token
  status: 'online' | 'offline' | 'busy';
  capabilities: string[];
  subscribedTopics: string[];
}

export interface CoworkingSpace {
  // ... 原有欄位

  // 通信配置
  communicationConfig: SpaceCommunicationConfig;

  // 空間中的 Agents
  agents: SpaceAgent[];
}
```

### Round Table Client

```typescript
// src/services/round-table-client.ts

export interface RoundTableMessage {
  message_id: string;
  from_agent: string;
  to_agent?: string;
  workspace_id: string;
  content: Record<string, unknown>;
  message_type: 'request' | 'response' | 'notification' | 'command';
  timestamp: number;
}

export interface RoundTableClientConfig {
  baseUrl: string;
  seatToken?: string;
  workspaceId: string;
  agentId: string;
}

export class RoundTableClient {
  private config: RoundTableClientConfig;
  private wsConnection?: WebSocket;

  async connect(): Promise<void>;
  async subscribe(topics: string[]): Promise<void>;
  async publish(topic: string, message: RoundTableMessage): Promise<void>;
  async sendDirect(toAgent: string, content: Record<string, unknown>): Promise<void>;
  async getPending(limit?: number): Promise<RoundTableMessage[]>;
  onMessage(callback: (msg: RoundTableMessage) => void): void;
  disconnect(): void;
}
```

## 實作階段

### Phase 1: 型別定義與 Client (1-2 天)

**目標**：建立基礎型別和 Round Table 客戶端

**任務**：
- [ ] 創建 `src/types/round-table.ts` - Round Table 相關型別
- [ ] 創建 `src/services/round-table-client.ts` - Round Table 客戶端
- [ ] 擴展 `src/types/coworking-space.ts` - 加入通信欄位
- [ ] 單元測試

**檔案**：
1. `src/types/round-table.ts`
   ```typescript
   export interface RoundTableMessage { ... }
   export interface RoundTableClientConfig { ... }
   export interface SeatTokenInfo { ... }
   ```

2. `src/services/round-table-client.ts`
   ```typescript
   export class RoundTableClient {
     async connect(): Promise<void>
     async subscribe(topics: string[]): Promise<void>
     async publish(topic: string, message: RoundTableMessage): Promise<void>
     async sendDirect(toAgent: string, content: Record<string, unknown>): Promise<void>
     async getPending(limit?: number): Promise<RoundTableMessage[]>
     onMessage(callback: (msg: RoundTableMessage) => void): void
     disconnect(): void
   }
   ```

### Phase 2: CoworkingSpaceManager 整合 (2-3 天)

**目標**：將 Round Table 整合到 CoworkingSpaceManager

**任務**：
- [ ] 擴展 CoworkingSpaceManager - 加入通信管理
- [ ] 實作 Space 級別的 Agent 管理
- [ ] 實作跨空間消息路由
- [ ] 單元測試

**擴展功能**：
```typescript
// src/services/coworking-space-manager.ts

export class CoworkingSpaceManager {
  // ... 原有方法

  /**
   * 為 Space 啟用 Round Table 通信
   */
  async enableCommunication(spaceId: string, config: SpaceCommunicationConfig): Promise<void>;

  /**
   * 註冊 Agent 到 Space
   */
  async registerAgent(spaceId: string, agent: SpaceAgent): Promise<void>;

  /**
   * 從 Space 移除 Agent
   */
  async unregisterAgent(spaceId: string, agentId: string): Promise<void>;

  /**
   * 廣播消息到 Space 中的所有 Agents
   */
  async broadcastToSpace(
    spaceId: string,
    fromAgent: string,
    content: Record<string, unknown>
  ): Promise<void>;

  /**
   * 直接發送消息給特定 Agent
   */
  async sendToAgent(
    spaceId: string,
    fromAgent: string,
    toAgent: string,
    content: Record<string, unknown>
  ): Promise<void>;

  /**
   * 獲取 Space 中所有在線 Agents
   */
  getOnlineAgents(spaceId: string): SpaceAgent[];
}
```

### Phase 3: Agent 協作框架 (2-3 天)

**目標**：建立 Agent 協作的抽象層

**任務**：
- [ ] 創建 `src/services/agent-collaboration.ts` - Agent 協作服務
- [ ] 實作協作會話管理
- [ ] 實作能力發現與匹配
- [ ] 單元測試

**核心服務**：
```typescript
// src/services/agent-collaboration.ts

export interface CollaborationSession {
  sessionId: string;
  spaceId: string;
  topic: string;
  participants: string[];  // Agent IDs
  status: 'active' | 'paused' | 'completed';
  startedAt: number;
  endedAt?: number;
}

export class AgentCollaborationService {
  /**
   * 開始協作會話
   */
  async startCollaboration(params: {
    spaceId: string;
    topic: string;
    participants: string[];
    initialMessage: Record<string, unknown>;
  }): Promise<CollaborationSession>;

  /**
   * 廣播能力請求
   */
  async broadcastCapabilityRequest(
    spaceId: string,
    capability: string,
    query: Record<string, unknown>
  ): Promise<RoundTableMessage[]>;

  /**
   * 查找具備特定能力的 Agents
   */
  findAgentsByCapability(spaceId: string, capability: string): SpaceAgent[];

  /**
   * 結束協作會話
   */
  async endCollaboration(sessionId: string): Promise<void>;
}
```

### Phase 4: REST API (2 天)

**目標**：暴露通信功能的 REST API

**任務**：
- [ ] 擴展 `CoworkingSpaceController.ts` - 加入通信端點
- [ ] 創建 `CollaborationController.ts` - 協作會話端點
- [ ] TSOA 路由生成
- [ ] API 文檔

**API 端點**：
```typescript
// src/controllers/CoworkingSpaceController.ts (擴展)

@Post('{spaceId}/communication/enable')
async enableCommunication(
  @Path() spaceId: string,
  @Body() config: SpaceCommunicationConfig
): Promise<void>;

@Post('{spaceId}/agents')
async registerAgent(
  @Path() spaceId: string,
  @Body() agent: SpaceAgent
): Promise<void>;

@Get('{spaceId}/agents')
async listAgents(@Path() spaceId: string): Promise<SpaceAgent[]>;

@Post('{spaceId}/broadcast')
async broadcast(
  @Path() spaceId: string,
  @Body() message: { from: string; content: Record<string, unknown> }
): Promise<void>;

// src/controllers/CollaborationController.ts (新建)

@Post()
async startCollaboration(
  @Body() params: CollaborationStartParams
): Promise<CollaborationSession>;

@Get('{sessionId}')
async getCollaboration(@Path() sessionId: string): Promise<CollaborationSession>;

@Post('{sessionId}/end')
async endCollaboration(@Path() sessionId: string): Promise<void>;
```

### Phase 5: 整合測試 (2-3 天)

**任務**：
- [ ] E2E 測試
- [ ] 多 Agent 協作測試
- [ ] 跨空間通信測試
- [ ] 效能測試

### Phase 6: 文檔與部署 (1-2 天)

**任務**：
- [ ] API 文檔
- [ ] 使用指南
- [ ] 部署配置
- [ ] Round Table 服務部署指南

## 關鍵檔案清單

### 新建檔案
1. `src/types/round-table.ts` - Round Table 型別定義
2. `src/services/round-table-client.ts` - Round Table 客戶端
3. `src/services/agent-collaboration.ts` - Agent 協作服務
4. `src/controllers/CollaborationController.ts` - 協作 API 控制器
5. `tests/unit/round-table-client.test.ts` - 客戶端單元測試
6. `tests/e2e/collaboration.e2e.test.ts` - 協作 E2E 測試

### 修改檔案
1. `src/types/coworking-space.ts` - 加入通信相關型別
2. `src/services/coworking-space-manager.ts` - 整合通信功能
3. `src/controllers/CoworkingSpaceController.ts` - 加入通信端點

## 使用範例

### 場景 1：建立具備通信能力的 Coworking Space

```typescript
// 1. 創建 Space
const space = await manager.createSpace({
  name: 'Development Team',
  type: SpaceType.LOCAL,
  quota: { maxContainers: 10, maxCpu: 8, maxMemory: 16384, maxStorage: 100 },
});

// 2. 啟用通信
await manager.enableCommunication(space.id, {
  enabled: true,
  roundTableUrl: 'http://localhost:8000',
  allowAnonymousAgents: false,
});

// 3. 註冊 Claude Agent
await manager.registerAgent(space.id, {
  agentId: 'claude-dev',
  agentName: 'Claude Developer',
  agentType: 'claude',
  status: 'online',
  capabilities: ['api-design', 'code-review', 'typescript'],
  subscribedTopics: ['development', 'api'],
});

// 4. 註冊 Qwen Agent
await manager.registerAgent(space.id, {
  agentId: 'qwen-tester',
  agentName: 'Qwen Tester',
  agentType: 'qwen',
  status: 'online',
  capabilities: ['testing', 'quality-assurance', 'python'],
  subscribedTopics: ['testing', 'quality'],
});
```

### 場景 2：協作開發流程

```typescript
// 用戶發起任務
await manager.broadcastToSpace(space.id, 'user-1', {
  type: 'task',
  title: '建立用戶認證 API',
  description: '需要 CRUD 操作和 JWT 認證',
});

// Claude Agent 自動回應
claudeAgent.onMessage(async (msg) => {
  if (msg.content.type === 'task') {
    // 廣播能力宣稱
    await manager.broadcastToSpace(space.id, 'claude-dev', {
      type: 'capability-offer',
      task: msg.content,
      capabilities: ['api-design', 'typescript'],
    });
  }
});

// Qwen Agent 加入協作
qwenAgent.onMessage(async (msg) => {
  if (msg.content.type === 'capability-offer') {
    // 提供測試能力
    await manager.sendToAgent(space.id, 'qwen-tester', 'claude-dev', {
      type: 'collaboration-offer',
      role: 'qa-testing',
      capabilities: ['testing', 'test-automation'],
    });
  }
});
```

### 場景 3：協作會話

```typescript
const collabService = new AgentCollaborationService();

// 開始協作會話
const session = await collabService.startCollaboration({
  spaceId: space.id,
  topic: 'user-auth-api',
  participants: ['claude-dev', 'qwen-tester'],
  initialMessage: {
    type: 'project-kickoff',
    requirements: '建立 RESTful API with JWT auth',
  }
});

// Claude 設計 API
await collabService.sendToSession(session.sessionId, 'claude-dev', {
  type: 'api-design',
  endpoints: [ /* ... */ ],
});

// Qwen 提供測試計劃
await collabService.sendToSession(session.sessionId, 'qwen-tester', {
  type: 'test-plan',
  tests: [ /* ... */ ],
});

// 完成後結束會話
await collabService.endCollaboration(session.sessionId);
```

## 驗證測試

### 單元測試
```bash
pnpm test:unit -- --testNamePattern="RoundTable"
pnpm test:unit -- --testNamePattern="Collaboration"
```

### E2E 測試
```bash
pnpm test:e2e -- --testNamePattern="AgentCollaboration"
```

### API 測試
```bash
# 啟用通信
curl -X POST http://localhost:9900/coworking-spaces/{spaceId}/communication/enable \
  -H "Content-Type: application/json" \
  -d '{"enabled": true, "roundTableUrl": "http://localhost:8000"}'

# 註冊 Agent
curl -X POST http://localhost:9900/coworking-spaces/{spaceId}/agents \
  -H "Content-Type: application/json" \
  -d '{"agentId": "claude-dev", "agentName": "Claude Developer", ...}'

# 廣播消息
curl -X POST http://localhost:9900/coworking-spaces/{spaceId}/broadcast \
  -H "Content-Type: application/json" \
  -d '{"from": "user-1", "content": {"type": "task", ...}}'
```

## 依賴服務部署

### Round Table 服務

```bash
# 啟動 Round Table
cd /home/flexy/workspace/aintandem/default/repos/round-table
docker-compose -f docker/docker-compose.yml up -d

# 確認服務狀態
curl http://localhost:8000/health
```

## 注意事項

1. **Round Table 服務依賴**：需要先部署 Round Table 服務
2. **Redis 連接**：確保 Redis 可訪問
3. **Seat Token 管理**：安全地存儲和輪換 seat tokens
4. **網路隔離**：不同 Coworking Space 的通信應該隔離
5. **錯誤處理**：處理 Round Table 服務不可用的情況

---

**計劃狀態**：待審核
**預估工時**：10-13 天
**優先級**：高
