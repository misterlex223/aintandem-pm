# 軟體功能規格書 (SFS) — Kai × Flexy (Integrated)

本文件基於 `SRS-Integrated.md`、Kai 的 `docs/specs/srs.md` 及 Flexy 的 `flexy/docs/specs/srs.md` 產生，旨在將高階需求細化為具體的功能規格，作為後續開發、測試與驗收的依據。

---

## 1. Kai 平台功能需求 (Platform Functional Requirements)

### 1.1 Kai Web UI - 容器儀表板

- **SFS-KAI-F-001**: 系統應在主介面提供一個 Flexy 容器儀表板頁面。 (SRS-I: F-UI-1)
- **SFS-KAI-F-002**: 儀表板應以表格或卡片形式展示所有由 Kai 管理的 Flexy 容器。 (SRS-K: 3.1.1)
- **SFS-KAI-F-003**: 列表中的每一項應顯示以下資訊：容器 ID (短碼)、容器名稱、狀態（例如：`running`, `stopped`, `created`）、掛載的資料夾路徑 (folder mapping)、創建時間。 (SRS-K: 3.1.1)
- **SFS-KAI-F-004**: 儀表板應提供依容器名稱進行即時搜尋或篩選的功能。 (SRS-K: 4.3)
- **SFS-KAI-F-005**: 列表中的每一項應提供以下操作按鈕：
    - `進入 Shell`：點擊後導航至該容器的 Shell 介面 (`/flexy/:id/shell`)。
    - `進入 Docs`：若該 Flexy 啟用 Docs App，則顯示此按鈕，點擊後導航至 `/flexy/:id/docs`。 (SRS-I: F-UI-5)
    - `啟動/停止`：根據容器當前狀態顯示對應操作。
    - `刪除`：提供刪除容器的功能，執行前應有確認提示。 (SRS-K: 3.1.1)
- **SFS-KAI-F-006**: 頁面應提供一個 `新增 Flexy` 按鈕，用於開啟建立新容器的介面。 (SRS-K: 3.1.1)

### 1.2 Kai Web UI - 新增 Flexy 容器

- **SFS-KAI-F-007**: `新增 Flexy` 應以彈出式視窗 (Modal) 形式呈現。 (SRS-K: 5.2)
- **SFS-KAI-F-008**: 新增介面需包含以下輸入欄位：
    - `名稱 (Name)`：必填，用於識別容器。
    - `資料夾掛載 (Folder Mapping)`：可選，允許使用者輸入掛載規則，格式為 `/host/path:/container/path`。
    - 主機目錄瀏覽器：提供一個互動式介面，輔助使用者選擇主機端 (`host`) 的路徑。 (SRS-I: F-UI-2)
- **SFS-KAI-F-009**: 點擊 `建立` 按鈕後，前端應向後端 API (`POST /api/flexy`) 發送建立容器的請求。 (SRS-K: 3.1.2)

### 1.3 Kai Web UI - Shell & Docs 介面

- **SFS-KAI-F-010**: 系統應為每個容器提供一個獨立的 Shell 頁面，URL 格式為 `/flexy/{id}/shell`。 (SRS-K: 3.1.3)
- **SFS-KAI-F-011**: Shell 頁面應使用 `<iframe>` 內嵌一個終端機介面，該介面透過 Kai 後端的反向代理連接到對應 Flexy 容器的 ttyd 服務 (port 9681)。 (SRS-I: F-UI-4)
- **SFS-KAI-F-012**: 若 Flexy 容器啟用 Docs App，系統應提供一個獨立的 Docs 頁面，URL 格式為 `/flexy/{id}/docs`，並使用 `<iframe>` 內嵌其介面。 (SRS-I: F-UI-5)

### 1.4 Kai 後端 - 容器生命週期 API

- **SFS-KAI-F-013**: 提供 `GET /api/flexy` 端點，回傳所有 Flexy 容器的 metadata 列表（ID、名稱、狀態等）。 (SRS-I: F-API-1)
- **SFS-KAI-F-014**: 提供 `POST /api/flexy` 端點，接收 `{ name, folderMapping? }`，透過 Docker Engine API 建立一個新的 Flexy 容器。 (SRS-I: F-API-2)
- **SFS-KAI-F-015**: 提供 `DELETE /api/flexy/:id` 端點，用於停止並刪除指定的 Flexy 容器。 (SRS-I: F-API-5)
- **SFS-KAI-F-016**: 提供 `POST /api/flexy/:id/start` 端點，用於啟動一個已停止的 Flexy 容器。 (SRS-I: F-API-3)
- **SFS-KAI-F-017**: 提供 `POST /api/flexy/:id/stop` 端點，用於停止一個正在運行的 Flexy 容器。 (SRS-I: F-API-4)

### 1.5 Kai 後端 - 路由代理

- **SFS-KAI-F-018**: 系統需設定一個反向代理規則，將所有 `GET /flexy/:id/shell/*` 的請求（包括 WebSocket 升級請求）代理至對應的 `http://<flexy-container-name>:9681/*`。 (SRS-I: F-API-7)
- **SFS-KAI-F-019**: 代理過程需正確處理 HTTP `Upgrade` header 與 WebSocket 連線，確保 ttyd 功能正常。 (SRS-K: 3.2.2)
- **SFS-KAI-F-020**: 系統應提供 `GET /flexy/:id/docs/*` 之 HTTP 代理，將請求轉發至 Flexy 內的 Docs App（預設 `http://<flexy-container-name>:8080/*`），若目標服務不存在應回傳 404。 (SRS-I: F-API-7)

### 1.6 Kai 後端 - 輔助 API

- **SFS-KAI-F-021**: 提供 `GET /api/health` 健康檢查端點，回應 `{ status: 'ok', uptime: <seconds> }`。 (SRS-I: UAT-1)
- **SFS-KAI-F-022**: 提供 `POST /api/host/directories` 端點以瀏覽主機目錄，Body 可含 `currentPath`。此端點必須嚴格限制在使用者 home 目錄之下，並進行路徑正規化與安全檢查，防止路徑越權。 (SRS-I: F-API-6)

---

## 2. Flexy 規格 (Container & App Requirements)

### 2.1 Flexy 容器規格

- **SFS-FLX-F-001**: 容器內需安裝並啟動 ttyd 服務，監聽在 port `9681`。 (SRS-I: F-CTX-1)
- **SFS-FLX-F-002**: ttyd 應與 tmux 整合，以支援多人共享同一個 shell session。 (SRS-I: F-CTX-1)
- **SFS-FLX-F-003**: 容器內需預裝 `@google/gemini-cli`，以便在 shell 中直接與 AI 互動。 (SRS-I: F-CTX-2)
- **SFS-FLX-F-004**: 容器應支援透過 Docker Volume 將主機資料夾掛載至容器內的 `/workspace` 路徑。 (SRS-I: F-CTX-4)
- **SFS-FLX-F-005 (可選)**: 容器可選擇性地包含並啟動 Markdown Docs App，監聽在 port `8080`。 (SRS-I: F-CTX-3)

### 2.2 Flexy Docs App - API 規格

- **SFS-FLX-F-006**: 提供 `GET /health` 健康檢查端點。 (SRS-F: 10.1)
- **SFS-FLX-F-007**: 提供 `GET /api/projects` 端點，回傳已註冊的專案清單。預設情況下，應回傳一個以容器內 `/workspace` 為根目錄的專案。 (SRS-F: 10.2, 9.1)
- **SFS-FLX-F-008**: 提供 `POST /api/projects/:id/refresh` 端點，觸發對專案目錄的 `.md` 檔案進行重掃，並重建索引快取。 (SRS-F: 10.3)
- **SFS-FLX-F-009**: 提供 `GET /api/projects/:id/index` 端點，回傳掃描後的樹狀檔案結構。 (SRS-F: 10.3)
- **SFS-FLX-F-010**: 提供 `GET /api/projects/:id/file?path=<relativePath>` 端點，讀取並回傳指定 `.md` 檔案的內容。 (SRS-F: 10.4)
- **SFS-FLX-F-011**: 提供 `PUT /api/projects/:id/file` 端點，接收 `{ path, content, baseMtime? }`，將內容寫回指定的 `.md` 檔案。需支援基於 `baseMtime` 的衝突檢查。 (SRS-F: 10.4)

---

## 3. 非功能需求 (Non-Functional Requirements)

- **SFS-NF-001 (安全性)**: Flexy 容器不應將任何端口直接映射到主機，所有存取必須透過 Kai 的反向代理。 (SRS-I: NFR-3)
- **SFS-NF-002 (安全性)**: Kai 的 `POST /api/host/directories` 端點必須能有效防止目錄遍歷攻擊 (e.g., `../../..`)。 (SRS-I: 7)
- **SFS-NF-003 (安全性，可設定)**: Kai 後端 API 及代理介面可透過設定啟用身份驗證機制（如 JWT）。本地開發模式下預設關閉。 (SRS-I: NFR-3)
- **SFS-NF-004 (性能)**: Kai API 回應時間應在 200ms–500ms 之間。 (SRS-I: NFR-1)
- **SFS-NF-005 (性能)**: Flexy Docs App 的索引刷新時間應滿足：小型專案 (<1k 檔) 在 1s 內，中型專案 (1k-10k 檔) 在 5s 內。 (SRS-F: NFR-1)
- **SFS-NF-006 (使用性)**: Kai Web UI 的整體設計風格應遵循 Shadcn UI 的模式與元件，保持一致性。 (SRS-K: 4.3)
- **SFS-NF-007 (部署)**: Kai 前後端及 Flexy 應完全容器化，並透過 `docker-compose.yml` 進行編排。 (SRS-I: 8.1)

---

## 4. 需求追溯矩陣 (Requirement Traceability Matrix)

| SFS ID          | 需求描述                                     | 來源 SRS 文件 & 章節                                  |
|-----------------|----------------------------------------------|-------------------------------------------------------|
| **Kai Platform**|                                              |                                                       |
| SFS-KAI-F-001   | 提供容器儀表板頁面                           | SRS-I: F-UI-1; SRS-K: 3.1.1                           |
| SFS-KAI-F-003   | 儀表板顯示容器詳細資訊                       | SRS-K: 3.1.1                                          |
| SFS-KAI-F-005   | 提供操作按鈕（Shell, Docs, 啟停, 刪除）      | SRS-I: F-UI-3, F-UI-5; SRS-K: 3.1.1                   |
| SFS-KAI-F-008   | 新增介面含名稱、掛載、目錄瀏覽器             | SRS-I: F-UI-2; SRS-K: 3.1.2, 5.2                      |
| SFS-KAI-F-010   | 提供獨立的 Shell 頁面                        | SRS-K: 3.1.3                                          |
| SFS-KAI-F-011   | `<iframe>` 內嵌 ttyd 介面                    | SRS-I: F-UI-4                                         |
| SFS-KAI-F-013   | `GET /api/flexy` API                         | SRS-I: F-API-1                                        |
| SFS-KAI-F-014   | `POST /api/flexy` API                        | SRS-I: F-API-2                                        |
| SFS-KAI-F-018   | Shell (ttyd) 反向代理                        | SRS-I: F-API-7                                        |
| SFS-KAI-F-020   | Docs App 反向代理                            | SRS-I: F-API-7                                        |
| SFS-KAI-F-022   | `POST /api/host/directories` API             | SRS-I: F-API-6                                        |
| **Flexy**       |                                              |                                                       |
| SFS-FLX-F-001   | 容器內建 ttyd 服務 (9681)                    | SRS-I: F-CTX-1                                        |
| SFS-FLX-F-003   | 容器內建 Gemini CLI                          | SRS-I: F-CTX-2                                        |
| SFS-FLX-F-005   | 容器可選包含 Docs App (8080)                 | SRS-I: F-CTX-3; SRS-F: 4.1                            |
| SFS-FLX-F-006   | Docs App: `GET /health` API                  | SRS-F: 10.1                                           |
| SFS-FLX-F-008   | Docs App: `POST /api/projects/:id/refresh`   | SRS-F: 10.3                                           |
| SFS-FLX-F-010   | Docs App: `GET /api/projects/:id/file`       | SRS-F: 10.4                                           |
| SFS-FLX-F-011   | Docs App: `PUT /api/projects/:id/file`       | SRS-F: 10.4                                           |
| **NFRs**        |                                              |                                                       |
| SFS-NF-001      | Flexy 端口不直接暴露                         | SRS-I: NFR-3                                          |
| SFS-NF-002      | 目錄遍歷防護                                 | SRS-I: 7, NFR-3                                       |
| SFS-NF-005      | Docs App 索引性能                            | SRS-F: NFR-1                                          |
| SFS-NF-007      | 使用 Docker Compose 編排                     | SRS-I: 8.1                                            |

