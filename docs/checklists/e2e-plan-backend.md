# E2E 測試計畫 (Scenario List) - Kai Backend

本文件基於 `SRS.md` 與 `SFS.md` 規劃後端 API 的 E2E（黑箱）測試場景。

---

## 1. 容器管理 (Container Management)

### 1.1 容器列表

- **場景 1.1.1: 取得空的容器列表**
  - **追溯**: `SFS-F-013`
  - **前置條件**: 系統中沒有任何 Flexy 容器。
  - **步驟 (When)**: 向 `GET /api/flexy` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `200 OK`，且回應內容為一個空陣列 `[]`。

- **場景 1.1.2: 取得包含一個或多個容器的列表**
  - **追溯**: `SFS-F-013`
  - **前置條件**: 系統中已存在至少一個 Flexy 容器。
  - **步驟 (When)**: 向 `GET /api/flexy` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `200 OK`，回應內容為一個包含所有容器 metadata 的陣列。

### 1.2 建立容器

- **場景 1.2.1: 成功建立新容器**
  - **追溯**: `SFS-F-014`
  - **前置條件**: 提供一個有效的容器名稱（例如 `my-test-flexy`）及可選的路徑掛載規則。
  - **步驟 (When)**: 向 `POST /api/flexy` 發送帶有容器參數的請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `201 Created`，回應內容包含新建立容器的 metadata。
  - **資料影響**: 成功建立一個 Docker 容器，並在資料庫中新增一筆記錄。

- **場景 1.2.2: 建立同名容器導致衝突**
  - **追溯**: `SFS-F-014`
  - **前置條件**: 名稱為 `my-test-flexy` 的容器已存在。
  - **步驟 (When)**: 再次向 `POST /api/flexy` 發送建立同名容器的請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `409 Conflict`。

### 1.3 容器生命週期操作

- **場景 1.3.1: 停止一個正在運行的容器**
  - **追溯**: `SFS-F-017`
  - **前置條件**: 一個 Flexy 容器正在運行中。
  - **步驟 (When)**: 向 `POST /api/flexy/{id}/stop` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `200 OK` 或 `204 No Content`，且容器狀態變為 `stopped`。

- **場景 1.3.2: 啟動一個已停止的容器**
  - **追溯**: `SFS-F-016`
  - **前置條件**: 一個 Flexy 容器處於 `stopped` 狀態。
  - **步驟 (When)**: 向 `POST /api/flexy/{id}/start` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `200 OK` 或 `204 No Content`，且容器狀態變為 `running`。

- **場景 1.3.3: 刪除一個已存在的容器**
  - **追溯**: `SFS-F-015`
  - **前置條件**: 一個 Flexy 容器已存在（無論運行或停止）。
  - **步驟 (When)**: 向 `DELETE /api/flexy/{id}` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `200 OK` 或 `204 No Content`。
  - **資料影響**: 該 Docker 容器被移除，資料庫中的對應記錄也被刪除。

- **場景 1.3.4: 操作不存在的容器**
  - **追溯**: `SFS-F-015`, `SFS-F-016`, `SFS-F-017`
  - **前置條件**: 提供一個不存在的容器 ID。
  - **步驟 (When)**: 向 `POST /api/flexy/{id}/start`, `POST /api/flexy/{id}/stop`, 或 `DELETE /api/flexy/{id}` 發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `404 Not Found`。

## 2. 安全性 (Security)

- **場景 2.1: 未經授權存取 API**
  - **追溯**: `SFS-NF-002`
  - **前置條件**: 未提供有效的身份驗證 Token。
  - **步驟 (When)**: 向任何 `/api/flexy` 相關端點發送請求。
  - **期望回應 (Then)**: HTTP 狀態碼為 `401 Unauthorized`。
