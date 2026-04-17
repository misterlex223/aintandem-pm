# AliyunProvider 容器創建功能測試

## 完成時間
2026-04-17

## 測試結果

**10/10 測試通過** ✅

### 測試覆蓋範圍

| 測試項目 | 狀態 |
|---------|------|
| 基本容器創建 | ✅ |
| 環境變量設置 | ✅ |
| 端口映射 | ✅ |
| 卷掛載 | ✅ |
| 工作目錄設置 | ✅ |
| 自定義命令 | ✅ |
| 錯誤處理 (重複名稱) | ✅ |
| 錯誤處理 (無效圖像) | ✅ |

### 測試的 Docker 參數

```bash
docker run -d \
  --name ${CONTAINER_NAME} \
  --network ${DOCKER_NETWORK} \
  -e VAR=value \                    # 環境變量
  -p 8080:8080 \                     # 端口映射
  -v /host:/container \              # 卷掛載
  -w /workspace \                     # 工作目錄
  ${IMAGE} \
  sleep 3600                         # 保持運行
```

## 下一步：實現 AliyunProvider.createSandbox()

基於測試結果，現在需要在 AliyunProvider 中實現 createSandbox 方法。

### 方法簽名

```typescript
async createSandbox(options: {
  name: string;
  imageName?: string;
  envVars?: Record<string, string>;
  portMappings?: Array<{ hostPort: number; containerPort: number }>;
  volumeMounts?: Array<{ hostPath: string; containerPath: string }>;
  workingDir?: string;
  command?: string[];
}): Promise<string>  // Returns container ID
```

### 實現要點

1. **SSH 命令構建**
   - 將 Docker 參數轉換為 SSH 執行的命令
   - 正確處理引號轉義

2. **目錄創建**
   - 對於卷掛載，確保本地目錄存在
   - 對於嵌套路徑，使用 `mkdir -p`

3. **錯誤處理**
   - 重複名稱檢測
   - 無效圖像處理
   - 網路不存在處理

4. **返回驗證**
   - 確認容器正在運行
   - 返回容器 ID

## 完整測試覆蓋

### E2E 測試總結

| 類別 | 測試文件 | 通過項目 |
|------|----------|----------|
| 基本操作 | `test-basic-ops.sh` | 15/15 ✅ |
| 檔案傳輸 | `test-file-transfer.sh` | 8/8 ✅ |
| API 測試 | `test-aliyun-api.ts` | 10/10 ✅ |
| 容器創建 | `test-create-sandbox.sh` | 10/10 ✅ |
| **合計** | **4 個測試套件** | **43/43** ✅ |

### 測試目錄

```
project/tests/e2e/aliyun-provider/
├── setup/
│   ├── init-ecs.sh              # ECS 初始化
│   └── providers.yaml.example   # 配置範本
├── bash/
│   ├── test-basic-ops.sh        # 基本操作 (15 項)
│   ├── test-file-transfer.sh    # 檔案傳輸 (8 項)
│   └── test-create-sandbox.sh   # 容器創建 (10 項) ⭐ 新
├── api/
│   ├── test-aliyun.ts           # 連接測試
│   └── test-aliyun-api.ts       # 完整 API (10 項)
└── README.md                     # 使用說明
```

## 快速命令

```bash
# 運行所有測試
cd project/tests/e2e/aliyun-provider
./bash/test-basic-ops.sh
./bash/test-file-transfer.sh
./bash/test-create-sandbox.sh

# API 測試
cd repos/ce-orchestrator
npx ts-node project/tests/e2e/aliyun-provider/api/test-aliyun-api.ts
```

## 已驗證的功能

| 功能 | Bash 測試 | API 測試 | 狀立實現 |
|------|-----------|----------|----------|
| 連接測試 | ✅ | ✅ | ✅ |
| 列出容器 | ✅ | ✅ | ✅ |
| 獲取狀態 | ✅ | ✅ | ✅ |
| 執行命令 | ✅ | ✅ | ✅ |
| 獲取日誌 | ✅ | ✅ | ✅ |
| 啟動容器 | ✅ | ✅ | ❌ |
| 停止容器 | ✅ | ✅ | ✅ |
| 重啟容器 | ✅ | ✅ | ✅ |
| 刪除容器 | ✅ | ✅ | ✅ |
| 上傳檔案 | ✅ | ✅ | ✅ |
| 下載檔案 | ✅ | ✅ | ✅ |
| **創建容器** | ✅ | ❌ | ❌ |

⚠️ **AliyunProvider 缺少 createSandbox 方法** - 需要實現
