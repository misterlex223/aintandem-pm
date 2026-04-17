# 軟體需求規格書（SRS-Integrated）— Kai × Flexy（Human Co-work with AI）

## 0. 摘要
- 本文件整合兩份先前規格：
  - `docs/specs/srs.md`（Kai：容器管理與 ttyd 代理）
  - `flexy/docs/specs/srs.md`（Flexy：Markdown 瀏覽/編輯器，以 Docker 部署）
- 目標：以 Kai 作為「多 Flexy 容器」的中台編排，避免直接暴露容器埠；使用者經由 Kai 的 Web UI/Proxy 進入每個 Flexy 的 ttyd 與（可選）Docs App，實現人機協作（Human × AI）。

---

## 1. 簡介
### 1.1 目的
- 建立一個安全、易用、可擴展的本機/團隊級平台：
  - 透過 Kai 管理多個 Flexy 容器（建立、啟停、刪除、狀態）。
  - 無需暴露容器埠，經 Kai Reverse Proxy 安全進入 Flexy 的 ttyd（Web 終端）。
  - Flexy 內建 Gemini CLI，讓人類能與 AI 共同完成開發/維運任務。
  - Flexy 可選啟動 Markdown Docs App（8080），由 Kai 代理呈現，方便知識與規格文件管理。

### 1.2 範疇
- Kai（前端 React/Vite、後端 Node/Express）
- Flexy 容器映像（ttyd + tmux + Gemini CLI + 可選 Docs App）
- Docker Engine API 與單一自訂網路 `kai-net`

### 1.3 使用者
- 開發者、架構師、AI 工程團隊、人機協作使用者

---

## 2. 系統總覽
### 2.1 架構圖
```
[ Browser ]
    |
    v
[Kai Web (React)] <--> [Kai API (Node/Express + Proxy)]
                                 |
                                 v
                        [Docker Engine / API]
                                 |
              ---------------------------------------
              |                 |                   |
       [Flexy A]           [Flexy B]            [Flexy ...]
       (ttyd:9681)         (ttyd:9681)          (ttyd:9681)
       (docs:8080 可選)    (docs:8080 可選)     (docs:8080 可選)
              ^                 ^                     ^
              |                 |                     |
              --------------- Kai Proxy ---------------
```

### 2.2 執行環境
- 前端：React + Vite + TailwindCSS + shadcn/ui（`frontend/`）
- 後端：Node.js（Express）`backend/`，存取 Docker Engine API
- 容器：Docker，單一網路 `kai-net`
- Flexy：ttyd（9681）+ tmux、Gemini CLI、（可選）Docs App（8080）

### 2.3 假設與限制
- 需可存取 Docker Engine（以 `/var/run/docker.sock` 掛載）
- Flexy 映像已可建置（包含 ttyd、Gemini CLI；Docs App 可選）
- Kai 與 Flexy 皆連到同一 Docker Network（`kai-net`）

---

## 3. 功能需求
### 3.1 Kai Web UI（`frontend/`）
- F-UI-1：Flexy 列表（id、名稱、狀態、folder mapping、建立時間）；提供篩選/搜尋。
- F-UI-2：新增 Flexy（輸入名稱、folder mapping；提供主機目錄瀏覽器）。
- F-UI-3：容器操作（啟動/停止/刪除）。
- F-UI-4：進入 Shell（`/flexy/:id/shell` 以 iframe 顯示 ttyd）。
- F-UI-5（可選）：進入 Docs（`/flexy/:id/docs` 以 iframe 顯示 Docs App）。

### 3.2 Kai 後端 API（`backend/`）
- F-API-1：`GET /api/flexy` → 列出 Flexy 容器
- F-API-2：`POST /api/flexy` → 建立 Flexy（`{ name, folderMapping? }`）
- F-API-3：`POST /api/flexy/:id/start` → 啟動
- F-API-4：`POST /api/flexy/:id/stop` → 停止
- F-API-5：`DELETE /api/flexy/:id` → 刪除
- F-API-6：`POST /api/host/directories` → 主機目錄瀏覽（僅 home 目錄之下）
- F-API-7（新）：Reverse Proxy（需支援 WS）
  - `GET /flexy/:id/shell/*` → 代理至 `http://<flexy-name>:9681/*`
  - `GET /flexy/:id/docs/*`（可選）→ 代理至 `http://<flexy-name>:8080/*`

### 3.3 Flexy 容器（`flexy/flexy-docker/Dockerfile`）
- F-CTX-1：內建 ttyd（9681）+ tmux，共用會話
- F-CTX-2：安裝 Gemini CLI（`@google/gemini-cli`）
- F-CTX-3（可選）：Docs App（8080）
- F-CTX-4：支援主機資料夾掛載到 `/workspace`（或使用者指定路徑）

### 3.4 Markdown Docs App（Flexy 內可選服務）
- F-DOC-1：多專案目錄（Root Path）管理
- F-DOC-2：掃描 `.md`，建立樹狀索引，手動 Refresh
- F-DOC-3：檔案檢視/編輯/儲存，基本衝突檢查
- F-DOC-4：健康檢查 `/health` 與索引狀態查詢

---

## 4. 非功能性需求（NFR）
- NFR-1 性能：
  - Kai 列表/操作 API 200ms–500ms；Flexy 建立依映像體積而定
  - Docs 索引：<1k 檔 1s 內；1k–10k 檔 5s 內（參考原 Flexy SRS）
- NFR-2 可用性：UI 簡潔、深淺色可選；錯誤提示清楚
- NFR-3 安全性：
  - 不暴露 Flexy 埠；所有流量經 Kai Proxy
  - Kai API 可切換 JWT/Session 保護（默認本機無認證）
  - 目錄瀏覽與檔案存取需路徑正規化、白名單
- NFR-4 可維護性：契約與程式結構清晰；結構化日誌

---

## 5. 資料模型（示意）
- FlexyContainer（Kai 派生）
  - `id: string`（Docker Id 短碼）
  - `name: string`（容器名稱，如 `flexy-<shortId>-<sanitized>`）
  - `status: string`
  - `folderMapping: string`（`/host:/container`）
  - `createdAt: ISO string`
- 可選：Kai 持久化（SQLite/Firestore/Postgres）以儲存顯示用名稱、標籤、最近開啟頁等

---

## 6. 介面規格（REST）
- 如 3.2 所述。回應格式統一 `application/json`；成功 `{ ... }`，錯誤 `{ message, error? }`。
- Flexy Docs（若啟用）遵循 `flexy/docs/specs/srs.md` 中 10.1–10.5。

---

## 7. 安全設計
- Kai Proxy 僅在本機或內網提供；可選 TLS 與 JWT/Session。
- 不將使用者認證資訊轉發進 Flexy。
- 目錄瀏覽 API 僅限 home 目錄之下，阻擋 `..`、符號連結逃逸。

---

## 8. 部署與設定
### 8.1 Docker Compose（`docker-compose.yml`）
- 服務：
  - `frontend`（靜態或 preview），環境：`VITE_API_BASE_URL=http://localhost:3000`
  - `backend`（Node/Express），掛載 Docker Socket；網路 `kai-net`
- 不為任何 Flexy 做 Port Mapping；僅 Kai 對外暴露 3000/80（視部署而定）。

### 8.2 Flexy Image
- 建置：`docker build -t flexy-dev-sandbox:latest flexy/flexy-docker`
- Kai 後端環境變數：
  - `IMAGE_NAME=flexy-dev-sandbox:latest`
  - `DOCKER_NETWORK=kai-net`

---

## 9. UI/UX 規格（概要）
- 首頁（容器儀表板）：列表 + 新增/啟停/刪除 + [Open Shell]、[Open Docs]（可選）
- 新增 Flexy Modal：`name`、`folderMapping`，主機目錄挑選器（利用 `/api/host/directories`）
- Shell 頁：`/flexy/:id/shell` 以 iframe 顯示 ttyd（標題顯示專案名稱）
- Docs 頁（可選）：`/flexy/:id/docs` 以 iframe 顯示 Docs App

---

## 10. 驗收標準（UAT）
- UAT-1：`/api/health` 回應 `{ status: 'ok' }`
- UAT-2：能建立 Flexy（指定 `name` 與 `folderMapping`），列表顯示正確
- UAT-3：可啟動/停止/刪除 Flexy，錯誤情境可得合理訊息
- UAT-4：點擊 [Open Shell] 能透過 Kai Proxy 進入 ttyd，未在 host 直接開埠
- UAT-5（可選）：[Open Docs] 透過 Kai 代理載入，掃描/預覽/編輯/儲存 `.md`
- UAT-6：安全檢查：路徑越權被阻擋；Flexy 埠未暴露

---

## 11. 里程碑（建議）
- M1：Kai Backend 完成 Docker 控制與 Proxy（WS + HTTP）
- M2：Kai Frontend 儀表板與 Shell 頁
- M3：Flexy Image（ttyd+Gemini）與可選 Docs App 接入
- M4：認證/硬化與記錄監控
- M5：體驗與穩定性優化、版本釋出

---

## 12. 風險與限制
- 初次建置映像耗時較長；需本機 Docker 權限
- ttyd 需 WS 代理正確設定；網路名稱需一致
- 大量 `.md` 專案需要索引進度與效能優化（依 Flexy SRS）

---

## 13. 追溯鏈（Traceability）
- Kai SRS：`docs/specs/srs.md`
- Flexy SRS：`flexy/docs/specs/srs.md`
- Kai 架構：`docs/ARCHITECTURE-Backend.md`, `docs/ARCHITECTURE-Frontend.md`
- Flexy 架構：`flexy/docs/ARCHITECTURE-Backend.md`, `flexy/docs/ARCHITECTURE-Frontend.md`
- 實作參考：
  - Kai 後端：`backend/src/app.ts`, `backend/src/routes/containers.ts`, `backend/src/services/docker.ts`
  - Kai 前端：`frontend/src/pages/shell-page.tsx`, `frontend/src/components/*`
  - Flexy 映像：`flexy/flexy-docker/Dockerfile`
