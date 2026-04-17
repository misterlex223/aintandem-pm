---
description: 前端架構說明與參數（含可被流程引用的資訊）
---

# ARCHITECTURE-Frontend

## 技術棧
- Vite + React + TypeScript
- Tailwind CSS v4 + shadcn/ui
- 測試：Vitest（單元）、Playwright 或 MCP Puppeteer（驗收）

## Architecture Info Block（供流程引用）
```yaml
# Architecture Info Block（multi-app + default env）
default_env: docker        # dev | preview | docker | firebase（預設 Docker 模式）

# 多前端 App 設定：每個 app 可使用不同框架與埠口
apps:
  - name: web
    framework: vite-react   # vite-react | nextjs | nuxt | astro ...
    package_manager: pnpm   # pnpm | npm | yarn
    dev_server_port: 5173
    preview_port: 4173
    base_url: http://localhost:4173
    probe_path: /
    probe_expect_text: "<title>"
    dev_command: pnpm dev
    build_command: pnpm build
    preview_command: pnpm preview -- --port 4173 --strictPort
    public_dir: dist
    env:
      api_base_url_key: VITE_API_BASE_URL
      app_env_key: VITE_APP_ENV

firebase:
  use_emulator: false
  project_id: kai-project
  hosting_site: kai-web
  emulator_ui_port: 4000
  base_url: http://127.0.0.1:5000

Docker:
  compose_file: docker-compose.yml
  app_service: web
  image: kai/web:local

probe:
  success_status_codes: [200, 304]
  max_wait_seconds: 30
  poll_interval_ms: 1000
```

## 參考與配置
- **路由與頁面**：基於 `docs/ux/flows/`，主要包含：
  - 容器儀表板 (`/`)
  - 內嵌終端機 (`/flexy/:id/shell`)
  - （可選）Docs 頁（Flexy 內 Docs App 代理）`/flexy/:id/docs`
- **API 基礎設施**：`frontend/src/lib/api/` 應封裝對後端服務的呼叫，但考量到專案規模，目前直接在元件內使用 `fetch`。
- **環境檔**：`.env.*` 檔案應定義 `VITE_API_BASE_URL`，指向後端 API 服務 (例如 `http://localhost:3000`)。

## 驗收與報告
- **前端驗收流程**：`/check-the-frontend-app.md`
- **報告輸出**：`.reports/check-frontend/{DATETIME}/`

## 對齊要求
- **API 契約**：與 `docs/specs/api/openapi.yaml` 對齊所有容器管理的端點（CRUD）與錯誤碼。
- **UX 規格**：與 `docs/ux/*` 對齊 Flow/Component/Page 追溯鏈，特別是 `comp-container-ContainerList-001` 和 `comp-container-ContainerCard-002` 的規格。
- **功能規格**：滿足 `docs/specs/sfs.md` 中定義的所有 Web UI 功能需求（SFS-F-001 至 SFS-F-012）。

## 部署階段規格（Deployment Phase Specs）
- **埠與 URL**：`apps[].dev_server_port` (5173), `apps[].preview_port` (4173)。
- **指令**：`apps[].dev_command` (`pnpm dev`), `apps[].build_command` (`pnpm build`), `apps[].preview_command` (`pnpm preview`)。
- **環境變數鍵**：`apps[].env.api_base_url_key` (`VITE_API_BASE_URL`)。

## 測試與報告（Tests & Reports）
- **部署與啟動報告**：`.reports/deploy-frontend/{DATETIME}/`
- **靜態檢查**：在工作流程中應執行 `pnpm install`, `tsc --noEmit`, `eslint .`, `pnpm build`。 
