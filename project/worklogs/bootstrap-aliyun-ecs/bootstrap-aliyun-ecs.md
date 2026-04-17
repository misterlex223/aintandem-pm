# AliyunProvider 測試環境初始化

## 完成時間
2026-04-17

## 任務概述
為 AliyunProvider 建立實際測試環境，包括 ECS 初始化、基本操作測試和檔案傳輸測試。

## 完成工作

### 1. SSH 配置修正
**檔案**: `~/.ssh/config`

添加了 `User root` 配置項，解決 SSH 認證失敗問題：
```ssh
Host aliyun-gz
  HostName 8.134.76.139
  User root
  IdentityFile ~/.ssh/Aliyun-GZ.pem
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

### 2. ECS 初始化腳本
**檔案**: `bootstrap/init-ecs.sh`

功能：
- 自動偵測 OS 類型 (Ubuntu/CentOS)
- 安裝 Docker
- 創建 kai-net Docker 網路
- 創建 /data 基礎目錄
- 驗證安裝結果

執行結果：
```
✓ SSH connection established
✓ Docker installed: Docker version 29.3.0
✓ Network kai-net created
✓ Base root directory created
```

### 3. 基本操作整合測試
**檔案**: `bootstrap/test-aliyun.sh`

測試項目 (15 項)：✅ 15/15 通過
1. SSH 連線測試
2. Docker 可用性
3. Docker 網路檢查
4. 創建測試容器
5. 列出容器
6. 獲取容器狀態
7. 獲取容器 IP
8. 執行容器命令
9. 獲取容器日誌
10. 停止容器
11. 重啟容器
12. 刪除容器

### 4. 檔案傳輸測試
**檔案**: `bootstrap/test-file-transfer.sh`

測試項目 (8 項)：✅ 8/8 通過
1. **uploadFile() - 文字檔**: ✅ 成功上傳並驗證內容
2. **downloadFile() - 文字檔**: ✅ 成功下載並驗證內容
3. **uploadFile() - 二進位檔**: ✅ MD5 驗證通過 (10KB)
4. **uploadFile() - 嵌套路徑**: ✅ 需預先創建目錄
5. **uploadFile() - 錯誤處理**: ✅ 正確偵測不存在的路徑
6. **downloadFile() - 嵌套路徑**: ✅ 成功下載
7. **大檔案傳輸**: ✅ 100KB 檔案上傳成功
8. **錯誤處理**: ✅ 不存在檔案的正確處理

### ⚠️ 發現的問題

**嵌套路徑問題**: `docker cp` 不會自動創建目標目錄

當嘗試上傳到 `/opt/new/path/file.txt` 時，如果 `/opt/new/path/` 不存在，操作會失敗。

**建議修復**: 在 AliyunProvider.uploadFile() 中添加目錄創建：
```typescript
// 在 docker cp 之前創建目標目錄
const remoteDir = remotePath.substring(0, remotePath.lastIndexOf('/'));
await this.sshClient.executeCommand(
  `docker exec ${id} mkdir -p "${remoteDir}"`
);
```

### 5. Provider 配置範例
**檔案**: `bootstrap/providers.yaml.example`

包含 local 和 aliyun-gz 兩個 provider 的配置範本。

## 技術細節

### 解決的問題

1. **Locale 警告干擾**
   - 問題：`bash: warning: setlocale: LC_ALL: cannot change locale (zh_TW.UTF-8)`
   - 解決：所有 SSH 命令添加 `LC_ALL=C`

2. **SSH 用戶名**
   - 問題：默認使用本地用戶名 `flexy`，ECS 使用 `root`
   - 解決：在 SSH config 中添加 `User root`

3. **TypeScript 編譯問題**
   - 問題：ts-node 模組路徑解析問題
   - 解決：提供 Bash 版本測試腳本

### 驗證的功能

| AliyunProvider 方法 | 測試狀態 | 備註 |
|---------------------|----------|------|
| `testConnection()` | ✅ | SSH + Docker 可用 |
| `listSandboxes()` | ✅ | 容器列表正確 |
| `getSandboxStatus()` | ✅ | 狀態、IP、運行時間 |
| `execCommand()` | ✅ | 命令執行正確 |
| `getLogs()` | ✅ | 日誌獲取成功 |
| `startSandbox()` | ✅ | 透過 restart 測試 |
| `stopSandbox()` | ✅ | 停止後狀態正確 |
| `restartSandbox()` | ✅ | 重啟後狀態正確 |
| `deleteSandbox()` | ✅ | 刪除後不再存在 |
| `uploadFile()` | ✅ | 文字、二進位檔案 |
| `downloadFile()` | ✅ | 各種路徑類型 |

## ECS 環境資訊

- **主機**: 8.134.76.139 (aliyun-gz)
- **OS**: Ubuntu 22.04.5 LTS
- **Docker**: 29.3.0
- **網路**: kai-net (172.18.0.0/16)
- **認證**: SSH 私鑰 (~/.ssh/Aliyun-GZ.pem)

## 下一步

1. ✅ 基本操作測試
2. ✅ 檔案傳輸測試
3. 修復嵌套路徑問題
4. 測試 ProviderManager 整合
5. 實際應用程式整合測試

## 創建的檔案

```
bootstrap/
├── init-ecs.sh               # ECS 初始化腳本
├── test-aliyun.sh            # 基本操作測試 (15 項)
├── test-file-transfer.sh     # 檔案傳輸測試 (8 項)
├── test-aliyun-provider.ts   # TypeScript 測試版本
├── test-aliyun-provider.mjs  # JavaScript 測試版本
└── providers.yaml.example    # Provider 配置範例
```

## 執行命令

```bash
# 初始化 ECS (首次運行)
./bootstrap/init-ecs.sh

# 運行基本操作測試
./bootstrap/test-aliyun.sh

# 運行檔案傳輸測試
./bootstrap/test-file-transfer.sh

# 手動 SSH 連接
ssh aliyun-gz

# 查看 Docker 容器
ssh aliyun-gz "docker ps -a"
```
