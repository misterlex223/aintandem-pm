# Round Table MCP Integration - 外部 Agent 整合方案

## 架構概述

```
┌─────────────────────────────────────────────────────────────────┐
│                    CE Orchestrator                               │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   REST API                                  │   │
│  │  /coworking-spaces/{id}/communication                     │   │
│  │  /coworking-spaces/{id}/agents                            │   │
│  │  /agent-collaboration/sessions                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                          ▲                                      │
│                          │ HTTP                                 │
└──────────────────────────┼──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│              Round Table MCP Server                              │
│        (src/mcp-server/index.ts)                                │
│                                                                 │
│  暴露 12 個 MCP Tools:                                          │
│  • rt_check_messages     - 檢查訊息                             │
│  • rt_send_message       - 發送訊息                             │
│  • rt_find_agents        - 尋找 agents                          │
│  • rt_broadcast_request  - 廣播請求                             │
│  • rt_start_collaboration - 啟動協作                           │
│  • rt_get_session        - 獲取會話狀態                         │
│  • rt_add_participant    - 新增參與者                           │
│  • rt_end_collaboration  - 結束會話                             │
│  • rt_list_my_sessions   - 列出我的會話                         │
│  • rt_pause_session      - 暫停會話                             │
│  • rt_resume_session     - 恢復會話                             │
│  • rt_get_my_info        - 獲取我的資訊                         │
└─────────────────────────────────────────────────────────────────┘
                           │
                           │ MCP (stdio)
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                      AI Agents (MCP Client)                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │Claude    │   │OpenClaw   │   │Cline     │   │Continue  │  │
│  │Code      │   │           │   │          │   │          │  │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘  │
│      │               │                │               │          │
│      │               │                │               │          │
│      ▼               ▼                ▼               ▼          │
│  讀取 SKILL.md 來學習何時/如何使用 MCP tools                      │
└─────────────────────────────────────────────────────────────────┘
```

## 文件結構

```
ce-orchestrator/
├── SKILL.md                           # Agent 使用指南
├── src/mcp-server/
│   ├── package.json                    # MCP Server 配置
│   ├── tsconfig.json                   # TypeScript 配置
│   ├── index.ts                        # MCP Server 主程式 (12 tools)
│   └── README.md                       # 安裝說明
└── docs/
    ├── DEPLOYMENT.md                   # 部署指南
    ├── ROUND_TABLE_GUIDE.md           # Round Table 使用指南
    └── API_REFERENCE.md                # API 參考
```

## 配置步驟

### 1. 構建 MCP Server

```bash
cd ce-orchestrator/src/mcp-server
pnpm install
pnpm build
```

### 2. 配置 Agent 的 MCP Settings

**Claude Code** (`~/.config/claude-code/config.json`):
```json
{
  "mcpServers": {
    "round-table": {
      "command": "node",
      "args": ["/path/to/ce-orchestrator/src/mcp-server/dist/index.js"],
      "env": {
        "ROUND_TABLE_URL": "http://localhost:9900/api",
        "AGENT_ID": "claude-code-prod",
        "SPACE_ID": "dev-team-space"
      }
    }
  }
}
```

**Cline** (VS Code settings.json):
```json
{
  "cline.mcpServers": {
    "round-table": {
      "command": "node",
      "args": ["/path/to/mcp-server/dist/index.js"],
      "env": {
        "ROUND_TABLE_URL": "http://localhost:9900/api",
        "AGENT_ID": "cline-agent",
        "SPACE_ID": "dev-team-space"
      }
    }
  }
}
```

### 3. 啟動 Orchestrator

```bash
# 確保 CE Orchestrator 運行
pnpm start

# 或用 Docker
docker-compose up -d
```

### 4. Agent 自動使用

Agent 會讀取 SKILL.md，學習：
- 何時檢查訊息 (`rt_check_messages`)
- 何時尋求協作 (`rt_find_agents`, `rt_start_collaboration`)
- 如何管理工作流程 (`rt_pause_session`, `rt_end_collaboration`)

## 使用範例

### Agent 自主協作流程

```
┌─────────────────────────────────────────────────────────────┐
│ User: "幫我實作用戶認證 API，需要設計、實作、測試"        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ Agent (Claude Code)                                          │
│                                                             │
│ 1. 分析任務需求                                               │
│    - API 設計能力                                             │
│    - 後端實作能力                                             │
│    - 測試能力                                               │
│                                                             │
│ 2. 尋找專家 Agents                                            │
│    rt_find_agents({ capability: "api-design" })             │
│    rt_find_agents({ capability: "frontend" })              │
│    rt_find_agents({ capability: "testing" })              │
│                                                             │
│ 3. 啟動協作會話                                             │
│    rt_start_collaboration({                                │
│      topic: "User Auth API Full Stack",                     │
│      participants: ["api-expert", "react-dev", "qa-guru"]  │
│    })                                                        │
│                                                             │
│ 4. 協調工作                                                  │
│    - 分配任務                                                │
│    - 監控進度                                                │
│    - 整合結果                                                │
│                                                             │
│ 5. 完成並結束                                                │
│    rt_end_collaboration({ reason: "功能完成" })              │
└─────────────────────────────────────────────────────────────┘
```

## 核心優勢

### 1. 零代碼改動
外部 agent **不需要**：
- ❌ 安裝 Round Table SDK
- ❌ 重寫消息處理邏輯
- ❌ 修改核心代碼

外部 agent **只需要**：
- ✅ 配置 MCP Server
- ✅ 讀取 SKILL.md
- ✅ 自然使用 MCP tools

### 2. 自然整合

Agent 會像使用其他 tools 一樣自然：

```
User: 幫我審查這段代碼的安全性
Agent: [自動調用 rt_find_agents({ capability: "security" })]
Agent: 找到了 2 個安全專家，我正在邀請他們協助...
```

### 3. 標準化協議

所有 agent 使用統一的：
- **Tool 定義** (MCP standard)
- **消息格式** (JSON over HTTP)
- **協作模式** (定義在 SKILL.md)

## 實際部署範例

### 多 Agent 協作環境

```yaml
# docker-compose.yml
version: "3.9"

services:
  orchestrator:
    image: ce-orchestrator:latest
    ports:
      - "9900:9900"
    environment:
      - ROUND_TABLE_URL=http://localhost:8000
    networks:
      - agent-net

  # Claude Code (本地)
  claude-code:
    image: claude-code:latest
    volumes:
      - ./mcp-server:/mcp-server:ro
    environment:
      - MCP_SERVER_PATH=/mcp-server/dist/index.js
    networks:
      - agent-net

  # Cline (VS Code extension)
  # 通過 MCP 連接

  # OpenClaw (獨立 agent)
  openclaw:
    image: openclaw:latest
    volumes:
      - ./mcp-server:/mcp-server:ro
    environment:
      - AGENT_ID=openclaw-1
    networks:
      - agent-net

networks:
  agent-net:
    driver: bridge
```

## 故障排除

### MCP Server 無法啟動

```bash
# 檢查構建
cd src/mcp-server
pnpm install
pnpm build

# 檢查 node 版本
node --version  # 需要 v18+

# 測試執行
node dist/index.js
```

### Agent 看不到 MCP Tools

1. 確認 MCP Server 已配置
2. 重啟 Agent 應用
3. 檢查日誌: `cat ~/.config/claude-code/logs/mcp.log`

### API 呼叫失敗

```bash
# 測試 API 連接
curl http://localhost:9900/api/health

# 檢查 agent 權限
curl http://localhost:9900/api/coworking-spaces/{spaceId}/agents
```

## 下一步

1. **測試 MCP Server**
   ```bash
   cd src/mcp-server
   pnpm install
   pnpm build
   node dist/index.js
   ```

2. **配置 Claude Code**
   - 編輯 `~/.config/claude-code/config.json`
   - 重啟 Claude Code

3. **驗證整合**
   - 在 Claude Code 中測試 tools
   - 檢查是否能找到其他 agents
   - 啟動第一個協作會話

這個方案讓任何支援 MCP 的 AI 工具都能無縫參與 Round Table 協作！
