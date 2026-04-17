---
description: 後端架構說明與參數（含 Architecture Info Block，供共用流程引用）
---

# ARCHITECTURE-Backend

本文件為後端（Backend）之架構與執行參數說明。共用工作流程（common）以及各環境覆寫（Firebase / Docker / Local）皆以本文的「Architecture Info Block」為參數來源。

## Architecture Info Block（供流程引用）
```yaml
# Architecture Info Block (Kai-Flexy Backend)
# 根據 SFS.md，後端為單一服務，負責容器管理 API 與路由代理
stack: node
package_manager: pnpm
base_url: http://localhost:3000
port: 3000
health_path: /api/health # 建議 API 路徑加上 /api 前綴
ready_path: /api/ready
start_command: pnpm start
build_command: pnpm build

# API 契約相關設定
contract:
  openapi_spec_path: docs/specs/api/openapi.yaml
  run_spectral: true
  run_openapi_diff: true

# E2E 測試相關設定
e2e:
  test_command: pnpm test:e2e -- --coverage
  coverage_thresholds:
    lines: 80

# Docker 執行環境設定
Docker:
  compose_file: docker-compose.yml
  app_service: kai-backend

env:
  IMAGE_NAME: flexy-dev-sandbox:latest   # Flexy 映像標籤（透過 Kai 建立容器時使用）
  DOCKER_NETWORK: kai-net         # Kai 與 Flexy 所在的 docker network 名稱
```

> 說明：
> - `stack`: `node`，因後端需處理 API 與反向代理，Express.js/Fastify 為合適選項。
> - `package_manager`: `pnpm`，與前端及專案根目錄一致。
> - `port`: `3000`，為 Node.js 專案常用開發埠口。
> - `health_path`: `/api/health`，用於健康檢查，提供基本狀態。
> - `contract`: 用於 API 契約驗證，確保實作與 `openapi.yaml` 規格一致。
> - `Docker`: 描述如何透過 Docker Compose 啟動後端服務，服務名稱為 `kai-backend`。
> - `env.IMAGE_NAME` 與 `env.DOCKER_NETWORK` 用於 Kai 後端在建立/代理 Flexy 容器時的行為設定。

## 執行環境（Environment）
- 本地（Local）：直接以 Node/Python/Go 啟動。
- Docker：以 `docker compose` 管理 App 與相依服務。
- Firebase（如採用）：以 Emulator Suite 啟動 Functions/Firestore/Storage/Auth。

## 安全與授權（Security）
- 認證策略與 Token 注入（例如 Firebase Auth ID Token 或 JWT）。
- 錯誤碼與 UI 映射策略需與前端 `src/lib/api/errors.ts` 對齊。

## 可觀測性（Observability）
- 結構化日誌（request-id）、健康/就緒探針與（若有）metrics 暴露。

## 契約與模型（Contract & Model）
- OpenAPI 權威規格：`docs/specs/api/openapi.yaml`
- Runtime schema：`/openapi.json`（建議暴露以供差異檢查）。
- 資料模型與索引（若採 Firebase）：`firestore.rules`、`firestore.indexes.json`。

## 測試與報告（Tests & Reports）
- 測試輸出：`.reports/e2e/{DATETIME}/`、`.reports/integrate-api/{DATETIME}/`。
- 報告需包含：指令、覆蓋率、截圖/trace/日誌與差異檢查摘要。
