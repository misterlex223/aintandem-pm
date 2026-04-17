# 產品需求文檔 (PRD)

## Kai–Flexy Container Management Platform

---

**當前版本**: v0.6.0-alpha
**狀態**: 開發中
**預計發布**: 2026-Q1

---

## 版本摘要

### v0.6.0-alpha (當前開發版本)

#### 新增功能 🆕

| ID | 標題 | 狀態 | 描述 |
|----|------|------|------|
| FE-001 | 容器儀表板 | ✅ | 統一的 Flexy 容器管理介面 |
| FE-002 | 新增容器介面 | ✅ | 彈出式表單建立新容器 |
| FE-003 | Shell 介面 | ✅ | iframe 嵌入 ttyd shell |
| FE-004 | Docs 介面 | ⏳ | Markdown 文檔瀏覽 |

#### API 端點

| ID | 端點 | 狀態 |
|----|------|------|
| API-001 | POST /api/containers | ✅ |
| API-002 | GET /api/containers | ✅ |
| API-003 | DELETE /api/containers/:id | ✅ |
| API-004 | POST /api/containers/:id/start | ⏳ |
| API-005 | POST /api/containers/:id/stop | ⏳ |

---

## 1. 產品概述

### 1.1 目的

Kai–Flexy 系統提供一個基於 Web 的容器管理平台，讓使用者能夠透過 **Kai** 管理多個 **Flexy** 容器，並透過 Web 介面存取每個 Flexy 內建的 ttyd shell。

### 1.2 核心價值

- **簡化容器管理**: 不需記憶 docker CLI 指令
- **安全訪問**: 容器端口不直接映射到主機
- **統一介面**: 單一 Dashboard 管理所有容器
- **快速開發**: 內建 AI Agent 開發環境

---

## 2. 功能需求

### 2.1 容器管理

| ID | 功能描述 | 優先級 | 狀態 |
|----|----------|--------|------|
| FE-001 | 容器列表顯示（ID、名稱、狀態、folder mapping） | P0 | ✅ |
| FE-002 | 新增容器表單（名稱、資料夾掛載） | P0 | ✅ |
| FE-003 | Shell 介面（iframe 嵌入 ttyd） | P0 | ✅ |
| FE-004 | Docs 介面（iframe 嵌入） | P1 | ⏳ |
| FE-005 | 批次操作（啟動/停止多個容器） | P2 | ⏳ |

### 2.2 API 端點

**容器 CRUD**:
- `POST /api/containers` - 建立新容器
- `GET /api/containers` - 列出所有容器
- `GET /api/containers/:id` - 獲取容器詳情
- `DELETE /api/containers/:id` - 刪除容器

**容器操作**:
- `POST /api/containers/:id/start` - 啟動容器
- `POST /api/containers/:id/stop` - 停止容器
- `POST /api/containers/:id/restart` - 重啟容器

**路由代理**:
- `/flexy/:id/shell/*` → `http://<container>:9681/*` (WebSocket)
- `/flexy/:id/docs/*` → `http://<container>:8080/*` (HTTP)

### 2.3 用戶流程

```
1. 用戶登入 Kai Dashboard
2. 查看所有 Flexy 容器狀態
3. 點擊「新增容器」建立新容器
   └─ 輸入名稱、選擇資料夾掛載
4. 點擊「進入 Shell」連接到容器 ttyd
5. 在 Shell 中與 AI Agent 交互
6. （可選）點擊「進入 Docs」查看文檔
```

---

## 3. 非功能需求

| ID | 需求描述 | 優先級 | 狀態 |
|----|----------|--------|------|
| NFR-001 | API 回應時間 < 500ms | P0 | 🔄 |
| NFR-002 | 容器端口不映射到主機 | P0 | 🔄 |
| NFR-003 | WebSocket 穩定連接 | P0 | ✅ |
| NFR-004 | 路徑遍歷防護 | P0 | ✅ |

---

## 4. 技術架構

### 4.1 前端

- **框架**: React + Vite + TailwindCSS + Shadcn UI
- **路由**: React Router
- **狀態管理**: React Query / Zustand
- **型別**: TypeScript

### 4.2 後端

- **框架**: Node.js + Express + TSOA
- **容器管理**: Docker Engine API
- **路由代理**: http-proxy-middleware
- **認證**: JWT

### 4.3 容器

- **Flexy**: 工程 AI Agent 容器
- **ttyd**: 終端機服務 (port 9681)
- **Docs App**: Markdown 文檔服務 (port 8080, 可選)

---

## 5. 需求追溯

詳細追溯矩陣請參考: [requirements/traceability.md](requirements/traceability.md)

需求 ID 註冊表: [requirements/id-registry.json](requirements/id-registry.json)

---

## 6. 發布計劃

### v0.6.0-alpha (當前)
- ✅ 基礎容器 CRUD
- ✅ Shell 介面
- ⏳ Docs 介面
- ⏳ 容器啟停 API

### v0.7.0 (計劃中)
- 批次操作
- 容器日誌查看
- 資源使用監控

---

## 7. 相關文檔

- [API 規格](api/openapi.yaml)
- [技術架構](../architecture/backend.md)
- [前端架構](../architecture/frontend.md)
- [測試指南](../guides/testing-guide.md)
