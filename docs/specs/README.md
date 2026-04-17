# 產品規格文檔

Kai–Flexy Container Management Platform 的產品規格和技術文檔。

## 目錄結構

```
specs/
├── PRD.md                    # 主產品需求文檔（活躍開發）
├── CHANGELOG.md              # 變更日誌
├── workflow.md               # 工作流系統規格
├── requirements/             # 需求管理
│   ├── traceability.md       # 需求追溯矩陣
│   └── id-registry.json      # 需求 ID 註冊表
├── api/                      # API 規格
│   └── openapi.yaml          # OpenAPI 3.0 規格
├── .claude/                  # 版本狀態（本地，不進 git）
│   └── version-state.json
├── v0.6.0-alpha → releases/  # 當前版本符號連結
└── releases/                 # 版本歷史快照
    └── v0.6.0-alpha/
        ├── PRD.md
        ├── CHANGELOG.md
        └── version-state.json
```

## 快速連結

| 文檔 | 描述 | 狀態 |
|------|------|------|
| [PRD.md](./PRD.md) | 產品需求文檔（活躍） | 🟢 維護中 |
| [CHANGELOG.md](./CHANGELOG.md) | 變更日誌 | 🟢 維護中 |
| [workflow.md](./workflow.md) | 工作流系統規格 | 🟢 維護中 |

## 需求 ID 系統

所有需求都有唯一 ID，便於追溯：

| 前綴 | 類型 | 範例 |
|------|------|------|
| FE | 功能需求 | FE-001 |
| API | API 端點 | API-001 |
| UI | UI 組件 | UI-001 |
| NFR | 非功能需求 | NFR-001 |
| BUG | Bug 修正 | BUG-001 |

詳細請參考: [requirements/id-registry.json](./requirements/id-registry.json)

## 版本管理

### 當前版本
- **版本**: 0.6.0-alpha
- **狀態**: 開發中
- **發布計劃**: 2026-Q1

### 版本歷史
查看 `releases/` 目錄中的各版本快照。

### Git Tags
```bash
# 查看所有版本標籤
git tag -l

# 查看特定版本的 PRD
git show v0.6.0-alpha:docs/specs/PRD.md
```

## 需求追溯

完整的需求追溯矩陣: [requirements/traceability.md](./requirements/traceability.md)

```bash
# 查找特定需求的所有提交
git log --all --grep="FE-001"
```

## 文檔更新流程

1. **新增功能**:
   - 在 `id-registry.json` 中分配需求 ID
   - 在 `PRD.md` 中添加功能描述
   - 更新 `traceability.md`

2. **版本發布**:
   - 使用 `/version-manager prepare-release`
   - 建立版本快照
   - 更新 `CHANGELOG.md`
   - 使用 `/version-manager finalize-release`

## 相關文檔

- [架構設計](../architecture/)
- [開發指南](../guides/)
- [測試指南](../guides/testing-guide.md)
