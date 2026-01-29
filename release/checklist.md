# Release Checklist

## 版本策略

```
ce-orchestrator vX.X.X  ← 核心版本 (決定發布版本)
    ├── ce-console vX.X.X       (追隨)
    ├── ce-desktop vX.X.X       (追隨)
    └── orchestrator-sdk vX.X.X (追隨)

aintandem-org                  (獨立，無版本對應)
```

## Git Tag 約定

```bash
# 整體發布
vX.X.X

# 單一組件發布
vX.X.X-orchestrator
vX.X.X-console
vX.X.X-desktop
```

## 發布流程

### 1. 版本檢查

```bash
# 檢查版本一致性
bash release/sync-versions.sh check

# 或使用 version-manager plugin
/version-manager check-versions
```

### 2. 規格文檔檢查

```bash
# 檢查 PRD 狀態
cat docs/specs/.claude/version-state.json

# 檢查需求追溯
cat docs/specs/requirements/traceability.md
```

### 3. 版本同步

```bash
# 同步所有 submodule 到目標版本
bash release/sync-versions.sh sync 0.6.0

# 或使用 version-manager plugin
/version-manager sync-versions --version=0.6.0
```

### 4. 發布前檢查清單

#### 功能完整性
- [ ] 所有計劃功能已實現
- [ ] 所有功能測試通過
- [ ] 無已知阻塞性 bug

#### 文檔完整性
- [ ] PRD.md 已更新
- [ ] CHANGELOG.md 已更新
- [ ] API 規格已同步 (openapi.yaml)
- [ ] 需求追溯矩陣已更新

#### 依賴兼容性
- [ ] 各 submodule 版本一致
- [ ] package.json 依賴版本已檢查
- [ ] 無 breaking changes 未記錄

#### 部署準備
- [ ] Docker image 已構建
- [ ] 環境變數已確認
- [ ] 遷移腳本已準備 (如需要)

### 5. 執行發布

```bash
# 5.1 提交變更
git add .
git commit -m "chore: release v0.6.0

- Sync all submodules to v0.6.0
- Update PRD and CHANGELOG
- Update requirements traceability"

# 5.2 建立標籤
git tag -a v0.6.0 -m "Release v0.6.0

# 5.3 推送到遠端
git push origin main
git push origin v0.6.0
```

### 6. 各 submodule 發布

```bash
# ce-orchestrator
cd repos/ce-orchestrator
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0

# ce-console
cd ../ce-console
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0

# ce-desktop
cd ../ce-desktop
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0

# orchestrator-sdk
cd ../orchestrator-sdk
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0
```

## Version Manager Plugin 整合

使用已安裝的 version-manager plugin：

```bash
# 準備發布
/version-manager prepare-release 0.6.0

# 建立快照
/version-manager create-snapshot 0.6.0

# 完成發布
/version-manager finalize-release 0.6.0
```

## 版本回滾

如需回滾已發布的版本：

```bash
# 刪除本地標籤
git tag -d v0.6.0

# 刪除遠端標籤
git push origin :refs/tags/v0.6.0

# 重新建立正確的標籤
git tag -a v0.6.0 -m "Release v0.6.0 (fixed)"
git push origin v0.6.0
```

## 相關文檔

- [Version Manager Plugin](../../.claude/plugins/cache/aintandem-agent-team/version-manager/1.0.0/README.md)
- [需求追溯矩陣](../docs/specs/requirements/traceability.md)
- [變更日誌](../docs/specs/CHANGELOG.md)
