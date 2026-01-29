# Release Checklist

使用 `/product-owner release-checklist --version=X.X.X` 產生具體版本的檢查清單。

## 版本策略

```
ce-orchestrator vX.X.X  ← 核心版本 (決定釋出版本)
    ├── ce-console vX.X.X       (追隨)
    ├── ce-desktop vX.X.X       (追隨)
    └── orchestrator-sdk vX.X.X (追隨)

aintandem-org                  (獨立，無版本對應)
```

## Git Tag 約定

```bash
# 整體釋出
vX.X.X

# 單一組件釋出
vX.X.X-orchestrator
vX.X.X-console
vX.X.X-desktop
```

## 發布流程

1. 檢查版本一致性: `/product-owner check-versions`
2. 檢查同步狀態: `/product-owner sync-status`
3. 產生檢查清單: `/product-owner release-checklist --version=X.X.X`
4. 各 repo 手動發布
5. Meta repo 建立標籤
