# Onboarding 功能發布說明

## 概述

此版本新增了初始設置精靈功能，讓管理者首次啟動系統時能夠通過直觀的精靈介面完成系統配置。

## 功能特性

### 後端 (ce-orchestrator)

- **Onboarding API 端點**
  - `GET /api/onboarding/status` - 檢查當前 onboarding 狀態
  - `POST /api/onboarding/step1` - 建立管理者帳號
  - `POST /api/onboarding/step2` - 生成 JWT 金鑰
  - `POST /api/onboarding/step3` - 設定系統名稱
  - `POST /api/onboarding/complete` - 完成 onboarding 流程

- **配置管理**
  - `config/app.config.json` - 主應用配置（系統名稱、JWT 金鑰、管理員認證資訊）
  - `config/onboarding.json` - Onboarding 狀態追蹤
  - 支援熱重載，無需重啟服務

- **安全特性**
  - JWT 金鑰使用 `crypto.randomBytes` 生成（256 位元）
  - 管理員密碼使用 bcrypt 雜湊
  - 配置檔案使用受限權限（0o600）

### 前端 (ce-console)

- **Onboarding 精靈頁面** (`/onboarding`)
  - 4 步驟流程，帶有進度指示器
  - 直觀的使用者介面
  - 即時驗證和錯誤提示

- **步驟組件**
  - **Step 1**: 建立管理員帳號（使用者名稱 + 密碼）
  - **Step 2**: JWT 金鑰生成資訊展示（自動生成）
  - **Step 3**: 設定系統名稱（支援返回上一頁）
  - **Step 4**: 確認並完成設定

- **驗證規則**
  - **使用者名稱**: 3-50 字元，僅限字母數字
  - **密碼**: 8+ 字元，必須包含大小寫字母、數字、特殊字元
  - **系統名稱**: 1-100 字元

- **API 客戶端**
  - 位於 `src/lib/api/onboarding.ts`
  - 完整的類型定義
  - 支援電子和桌面應用（使用 electronApiProxy）

## 使用說明

### 首次設置流程

1. 訪問應用程式（會自動重導向到 onboarding）
2. 完成所有 4 個步驟
3. 設定完成後，重導向到登入頁面
4. 使用建立的管理員帳號登入

### 配置檔案位置

- `config/app.config.json` - 主配置檔案
- `config/onboarding.json` - Onboarding 狀態標記

配置檔案會自動儲存在 `KAI_BASE_ROOT` 目錄中（預設為 `./config`）。

## 開發相關

### 後端開發

```bash
# 切換到後端目錄
cd repos/ce-orchestrator

# 安裝依賴並構建 API 路由
pnpm install
pnpm build:api

# 啟動開發伺服器
pnpm dev
```

### 前端開發

```bash
# 切換到前端目錄
cd repos/ce-console

# 安裝依賴
pnpm install

# 啟動開發伺服器（連接到後端）
VITE_USE_MOCK_API=false pnpm dev
```

## 測試

### 後端測試

- **單元測試**: `pnpm test:unit`
- **E2E 測試**: `pnpm test:e2e`（包含 onboarding 完整流程測試）

### 前端測試

測試流程：
1. 確保後端服務正在運行
2. 停用 mock API：`VITE_USE_MOCK_API=false pnpm dev`
3. 訪問 `http://localhost:5173`
4. 應該自動重導向到 `/onboarding`
5. 完成所有 4 個步驟
6. 確認重導向到 `/login`
7. 使用建立的帳號登入

## 已知問題

無

## 未來改進

- [ ] 支援重新初始化 onboarding（開發環境）
- [ ] 匯入/匯出配置
- [ ] 更詳細的錯誤訊息和建議
