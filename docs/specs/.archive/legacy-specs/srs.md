# 軟體需求規格書 (SRS)

## 系統名稱

**Kai–Flexy Container Management Platform**

---

## 1. 簡介

### 1.1 目的

Kai–Flexy 系統旨在提供一個 **基於 Web 的容器管理平台**，讓使用者能夠透過 **Kai** 管理多個 **Flexy** 容器，並透過 Web 介面存取每個 Flexy 內建的 ttyd shell，而不需直接暴露 container port。

### 1.2 範疇

- **Kai**

    - 提供 Web UI（React/Vite/Tailwind/Shadcn）

    - 管理多個 Flexy container

    - 充當反向代理 (routing)，將使用者的 Web 請求導向各 Flexy 的 ttyd (9681)

    - 提供 container 操作介面（新增、刪除、啟停、查看狀態）

- **Flexy**

    - 工程 AI Agent 容器

    - 提供 ttyd shell (9681)

    - 不做 port mapping，僅供 Kai routing 存取

    - 支援 folder mapping，允許掛載 host 資料夾到 container


---

## 2. 整體描述

### 2.1 使用者特性

- **主要使用者**：開發者、AI 工程團隊成員

- **需求**：快速建立、管理、操作 AI Agent 容器，不需記憶 docker CLI 指令


### 2.2 系統環境

- **前端**：React + Vite + TailwindCSS + Shadcn UI

- **後端**：Node.js (Express 或 Fastify)

- **容器管理**：Docker Engine API

- **路由代理**：Node.js + http-proxy-middleware (或 Nginx 作反向代理)

- **存儲**：SQLite / Firestore / Postgres（用於紀錄 Flexy metadata，如 container name, mapping, status）

- **環境變數**：

  - `IMAGE_NAME`（Flexy 映像名稱，預設建議 `flexy-dev-sandbox:latest`）

  - `DOCKER_NETWORK`（Kai 與 Flexy 所在的 Docker network 名稱，預設 `kai-net`）


### 2.3 假設與限制

- 系統運行環境具備 **Docker Engine API 存取權限**

- Flexy 映像檔已預先建立（含 ttyd）

- Kai 與 Flexy 在同一 Docker Network


---

## 3. 功能需求

### 3.1 Kai Web UI

#### 3.1.1 Flexy 容器列表

- 顯示所有 Flexy（ID、名稱、狀態、folder mapping、創建時間）

- 操作按鈕：

    - [進入 Shell] → Kai routing → ttyd

    - [啟動] / [停止]

    - [刪除]


#### 3.1.2 新增 Flexy

- 表單輸入：

    - Flexy 名稱

    - Folder mapping (host path → container path)

- Kai 透過 Docker API 建立新容器：

    `docker run -d --name flexy_<id> -v /host/path:/container/path flexy-dev-sandbox:latest`


#### 3.1.3 Shell 介面

- 使用 iframe / WebSocket Proxy

- 進入 `https://kai.local/flexy/{id}/shell` → 轉發至 `http://flexy_{id}:9681`


---

### 3.2 Kai 後端 API

#### 3.2.1 Container API

- `GET /api/flexy` → 取得 Flexy 列表

- `POST /api/flexy` → 建立 Flexy（帶 mapping）

- `DELETE /api/flexy/:id` → 刪除容器

- `POST /api/flexy/:id/start` → 啟動

- `POST /api/flexy/:id/stop` → 停止


#### 3.2.2 Routing

- `GET /flexy/:id/shell/*` → 代理請求 → `http://flexy_{id}:9681/*`

- `GET /flexy/:id/docs/*` → 代理請求 → `http://flexy_{id}:8080/*`（可選，當 Flexy 內啟動 Docs App 時）

#### 3.2.3 Host 目錄瀏覽

- `POST /api/host/directories` → 列出主機目錄（限定於使用者 home 目錄之下），Body 可含 `currentPath`；需進行路徑正規化與越權防護

#### 3.3 Flexy Catalog（持久化管理）

- 目的：Kai 需長期管理多個 Flexy 專案（名稱與本機對應路徑），不依賴記憶體。
- 資料模型：
  - `FlexyCatalogItem { id: string, name: string, hostPath: string, containerId?: string, createdAt: ISO }`
- 儲存：
  - Local 優先：JSON 檔或 SQLite（依部署策略選一）。
  - 团队/雲端：可換成外部 DB（未來擴充）。
- API（見 `docs/specs/api/openapi.yaml`）：
  - `GET /api/catalog/flexy` → 列出 catalog
  - `POST /api/catalog/flexy` → 新增 `{ name, hostPath }`
  - `DELETE /api/catalog/flexy/{id}` → 移除 catalog 項目（不一定刪除容器）


---

## 4. 非功能需求

### 4.1 安全性

- Flexy 不直接暴露 port

- Kai API 須驗證（JWT / Session）

- Shell routing 需帶登入 token


### 4.2 可擴展性

- Kai 支援多個 Flexy

- 可替換 routing 層（Node.js proxy 或 Nginx/Traefik）


### 4.3 使用性

- UI 遵循 Shadcn UI 樣式 → 統一設計風格

- 列表支援篩選、搜尋


---

## 5. 前端設計草圖

### 5.1 Flexy 列表頁
```
--------------------------------------
| [Kai Header]                       |
--------------------------------------
| Flexy 管理                         |
|                                     |
| + [新增 Flexy]                      |
|                                     |
| FlexyA   [進入 Shell] [啟動/停止] [刪除] |
| FlexyB   [進入 Shell] [啟動/停止] [刪除] |
--------------------------------------
```

### 5.2 新增 Flexy Modal

- Flexy 名稱 (input)

- Folder mapping (多行輸入，格式 `/host/path:/container/path`)

- [建立]


### 5.3 Shell 頁面

- iframe / proxy → 直接顯示 ttyd


---

## 6. 系統架構圖
```
[ Browser ]
     |
     v
[ Kai Web UI (React) ]  <--> [ Kai API (Node.js) ]
                                   |
                                   v
                     [ Docker Engine / API ]
                                   |
        ------------------------------------------------
        |                       |                      |
   [ Flexy A (ttyd:9681) ]  [ Flexy B (ttyd:9681) ]  ...
        ^                       ^
        |                       |
        -------- Kai Routing ----
```