# AliyunProvider E2E 測試

## 目錄結構

```
aliyun-provider/
├── setup/                      # 環境初始化
│   ├── init-ecs.sh             # ECS 初始化腳本
│   └── providers.yaml.example  # Provider 配置範本
│
├── bash/                       # Bash 測試腳本 (快速驗證)
│   ├── test-basic-ops.sh       # 基本操作測試 (15 項)
│   └── test-file-transfer.sh   # 檔案傳輸測試 (8 項)
│
├── api/                        # API 測試腳本 (完整驗證)
│   ├── test-aliyun.ts          # 簡單連接測試
│   └── test-aliyun-api.ts      # 完整 API 測試 (10 項)
│
└── README.md                   # 本文件
```

## 測試環境

- **ECS 實例**: aliyun-gz (8.134.76.139)
- **OS**: Ubuntu 22.04.5 LTS
- **Docker**: 29.3.0
- **網路**: kai-net (172.18.0.0/16)
- **認證**: SSH 私鑰 (~/.ssh/Aliyun-GZ.pem)

## 使用方式

### 1. 首次設置 ECS

```bash
# 初始化 ECS 實例（安裝 Docker、創建網路）
cd project/tests/e2e/aliyun-provider/setup
./init-ecs.sh
```

### 2. Bash 測試 (快速驗證，無需編譯)

```bash
# 基本操作測試 (15 項)
cd project/tests/e2e/aliyun-provider/bash
./test-basic-ops.sh

# 檔案傳輸測試 (8 項)
./test-file-transfer.sh
```

### 3. API 測試 (完整驗證)

```bash
# 切換到 ce-orchestrator 目錄
cd repos/ce-orchestrator

# 簡單連接測試 (使用配置文件)
# 需先創建配置: ~/.config/ce-orchestrator/providers.yaml
npx ts-node project/tests/e2e/aliyun-provider/api/test-aliyun.ts

# 完整 API 測試 (無需配置文件)
npx ts-node project/tests/e2e/aliyun-provider/api/test-aliyun-api.ts
```

## 測試覆蓋範圍

### Bash 測試 (23 項)

**test-basic-ops.sh** (15 項)
- ✅ SSH 連線
- ✅ Docker 可用性
- ✅ Docker 網路檢查
- ✅ 創建測試容器
- ✅ 列出容器
- ✅ 獲取容器狀態
- ✅ 獲取容器 IP
- ✅ 執行容器命令
- ✅ 獲取容器日誌
- ✅ 停止容器
- ✅ 重啟容器
- ✅ 刪除容器

**test-file-transfer.sh** (8 項)
- ✅ uploadFile() - 文字檔
- ✅ downloadFile() - 文字檔
- ✅ uploadFile() - 二進位檔 (MD5 驗證)
- ✅ uploadFile() - 嵌套路徑
- ✅ uploadFile() - 錯誤偵測
- ✅ downloadFile() - 嵌套路徑
- ✅ 大檔案傳輸 (100KB)
- ✅ 錯誤處理

### API 測試 (10 項)

**test-aliyun-api.ts** (10 項)
- ✅ `testConnection()` - SSH + Docker 可用
- ✅ `listSandboxes()` - 容器列表
- ✅ `getSandboxStatus()` - 狀態、IP、運行時間
- ✅ `execCommand()` - 命令執行
- ✅ `getLogs()` - 日誌獲取
- ✅ `stopSandbox()` - 停止容器
- ✅ `restartSandbox()` - 重啟容器
- ✅ `uploadFile()` - 檔案上傳
- ✅ `downloadFile()` - 檔案下載
- ✅ `deleteSandbox()` - 刪除容器

## 已知問題

### 嵌套路徑問題

`docker cp` 不會自動創建目標目錄。當嘗試上傳到 `/opt/new/path/file.txt` 時，如果目錄不存在會失敗。

**建議修復**: 在 AliyunProvider.uploadFile() 中添加：
```typescript
const remoteDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
await this.sshClient.executeCommand(
  `docker exec ${id} mkdir -p "${remoteDir}"`
);
```

## 快速命令

```bash
# 一鍵運行所有測試
cd project/tests/e2e/aliyun-provider
./bash/test-basic-ops.sh && ./bash/test-file-transfer.sh

# 檢查 ECS 容器狀態
ssh aliyun-gz "docker ps -a"

# 查看測試日誌
ssh aliyun-gz "docker logs <container-id>"
```

## 下一步測試項目

- [ ] ProviderManager 整合測試
- [ ] 多 Provider 同時操作測試
- [ ] 容器創建功能測試
- [ ] 錯誤恢復測試
- [ ] 效能測試
