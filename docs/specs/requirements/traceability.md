# 需求追溯矩陣

**最後更新**: 2026-01-29
**當前版本**: v0.6.0-alpha

## 概述

此文檔建立從產品需求 → 實現文件 → 測試用例的完整追溯鏈。

## 追溯矩陣

| 需求 ID | 需求標題 | 實現文件 | 測試用例 | 狀態 |
|---------|----------|----------|----------|------|
| **功能需求** |
| FE-001 | 容器儀表板 | `frontend/src/pages/Dashboard.tsx` | `tests/e2e/dashboard.spec.ts` | ✅ |
| FE-002 | 新增容器介面 | `frontend/src/components/CreateContainerDialog.tsx` | `tests/e2e/create-container.spec.ts` | ✅ |
| FE-003 | Shell 介面 | `frontend/src/pages/ShellPage.tsx` | `tests/e2e/shell.spec.ts` | ✅ |
| FE-004 | Docs 介面 | - | - | ⏳ |
| **API 端點** |
| API-001 | POST /api/containers | `backend/src/controllers/ContainerController.ts` | `tests/api/containers.spec.ts` | ✅ |
| API-002 | GET /api/containers | `backend/src/controllers/ContainerController.ts` | `tests/api/containers.spec.ts` | ✅ |
| API-003 | DELETE /api/containers/:id | `backend/src/controllers/ContainerController.ts` | `tests/api/containers.spec.ts` | ✅ |
| API-004 | POST /api/containers/:id/start | - | - | ⏳ |
| API-005 | POST /api/containers/:id/stop | - | - | ⏳ |
| **UI 組件** |
| UI-001 | 容器卡片組件 | `frontend/src/components/ContainerCard.tsx` | `tests/unit/ContainerCard.spec.ts` | ✅ |
| **非功能需求** |
| NFR-001 | API 回應時間 | - | 性能測試 | 🔄 |
| NFR-002 | 容器端口隱藏 | Docker 網絡配置 | 安全檢查 | 🔄 |

## 圖例

- ✅ 已完成
- ⏳ 待實現
- 🔄 進行中
- ❌ 已取消

## 如何使用

### 1. 查找需求實現

```bash
# 查找 FE-001 的實現文件
grep -r "FE-001" docs/specs/

# 或查看 id-registry.json
cat docs/specs/requirements/id-registry.json | jq '.assignments.FE-001'
```

### 2. 新增需求

1. 在 `id-registry.json` 中分配新的需求 ID
2. 更新此追溯矩陣
3. 在代碼提交訊息中引用需求 ID：

```bash
git commit -m "feat(container): implement FE-001 容器儀表板"
```

### 3. 追溯變更

```bash
# 查找特定需求的所有相關提交
git log --all --grep="FE-001"

# 查找特定文件的修改歷史
git log --follow -- frontend/src/pages/Dashboard.tsx
```

## 需求狀態流程

```
pending → in-progress → completed → archived
                              ↓
                           cancelled
```

## API 規格對照

| API ID | OpenAPI Spec | 實現控制器 | 測試 |
|--------|--------------|-----------|------|
| API-001 | `docs/specs/api/openapi.yaml` | ContainerController.create | ✅ |
| API-002 | `docs/specs/api/openapi.yaml` | ContainerController.list | ✅ |
| API-003 | `docs/specs/api/openapi.yaml` | ContainerController.delete | ✅ |
| API-004 | `docs/specs/api/openapi.yaml` | - | ⏳ |
| API-005 | `docs/specs/api/openapi.yaml` | - | ⏳ |
