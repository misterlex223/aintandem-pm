# AliyunProvider E2E 測試環境整理

## 完成時間
2026-04-17

## 工作目標

建立完整的 AliyunProvider E2E 測試環境，包括環境初始化、測試腳本和文檔。

## 完成工作

### 1. 測試目錄結構

```
project/tests/e2e/aliyun-provider/
├── setup/                      # 環境初始化
│   ├── init-ecs.sh             # ECS 初始化腳本
│   └── providers.yaml.example  # Provider 配置範本
│
├── bash/                       # Bash 測試腳本 (快速驗證)
│   ├── test-basic-ops.sh       # 基本操作測試 (15 項 ✅)
│   └── test-file-transfer.sh   # 檔案傳輸測試 (8 項 ✅)
│
├── api/                        # API 測試腳本 (完整驗證)
│   ├── test-aliyun.ts          # 簡單連接測試
│   └── test-aliyun-api.ts      # 完整 API 測試 (10 項 ✅)
│
└── README.md                   # 測試說明文檔
```

### 2. 測試腳本說明

| 腳本 | 類型 | 測試項目 | 狀態 |
|------|------|----------|------|
| `init-ecs.sh` | 初始化 | 安裝 Docker、創建網路 | ✅ |
| `test-basic-ops.sh` | Bash | 15 項基本操作 | ✅ 15/15 |
| `test-file-transfer.sh` | Bash | 8 項檔案傳輸 | ✅ 8/8 |
| `test-aliyun.ts` | API | 連接測試 | ✅ |
| `test-aliyun-api.ts` | API | 10 項完整 API | ✅ 10/10 |

### 3. 測試覆蓋的方法

| AliyunProvider 方法 | Bash 測試 | API 測試 |
|---------------------|-----------|----------|
| `testConnection()` | ✅ | ✅ |
| `listSandboxes()` | ✅ | ✅ |
| `getSandboxStatus()` | ✅ | ✅ |
| `execCommand()` | ✅ | ✅ |
| `getLogs()` | ✅ | ✅ |
| `startSandbox()` | ✅ (透過 restart) | - |
| `stopSandbox()` | ✅ | ✅ |
| `restartSandbox()` | ✅ | ✅ |
| `deleteSandbox()` | ✅ | ✅ |
| `uploadFile()` | ✅ | ✅ |
| `downloadFile()` | ✅ | ✅ |

### 4. 測試環境資訊

- **主機**: aliyun-gz (8.134.76.139)
- **OS**: Ubuntu 22.04.5 LTS
- **Docker**: 29.3.0
- **網路**: kai-net (172.18.0.0/16)
- **認證**: SSH 私鑰 (~/.ssh/Aliyun-GZ.pem)

## 使用方式

### 快速驗證 (Bash 測試)

```bash
# 基本操作測試
cd project/tests/e2e/aliyun-provider/bash
./test-basic-ops.sh

# 檔案傳輸測試
./test-file-transfer.sh
```

### 完整驗證 (API 測試)

```bash
cd repos/ce-orchestrator

# 完整 API 測試
npx ts-node project/tests/e2e/aliyun-provider/api/test-aliyun-api.ts
```

### 一鍵運行所有測試

```bash
cd project/tests/e2e/aliyun-provider
./bash/test-basic-ops.sh && ./bash/test-file-transfer.sh
```

## 已知問題

### 嵌套路徑問題

**問題**: `docker cp` 不會自動創建目標目錄

**影響**: 當上傳到不存在的嵌套路徑時會失敗

**建議修復**:
```typescript
// 在 AliyunProvider.uploadFile() 中添加
const remoteDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
await this.sshClient.executeCommand(
  `docker exec ${id} mkdir -p "${remoteDir}"`
);
```

## 測試結果摘要

| 測試類型 | 通過項目 | 總項目 | 通過率 |
|---------|---------|--------|--------|
| Bash 基本操作 | 15 | 15 | 100% |
| Bash 檔案傳輸 | 8 | 8 | 100% |
| API 完整測試 | 10 | 10 | 100% |
| **合計** | **33** | **33** | **100%** |

## 下一步測試項目

1. **ProviderManager 整合測試**
   - 測試多 Provider 管理
   - 測試 Sandbox 路由
   - 測試配置文件載入

2. **容器創建功能**
   - 目前 AliyunProvider 沒有 createSandbox 方法
   - 需要實現或測試容器創建邏輯

3. **錯誤恢復測試**
   - 網路中斷恢復
   - SSH 連接失敗重試
   - 容器異常處理

4. **效能測試**
   - 大檔案傳輸 (>10MB)
   - 並發操作
   - 長時間運行穩定性
