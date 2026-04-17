---
id: UX-INDEX-KAI
title: Kai UX Index (Traceability)
status: final
owner: ux@team
version: 0.2
last_updated: 2025-09-30
---

# Kai UX 設計文件索引

本索引整合 Kai 的 UX 規格並建立與 SRS/SFS/OpenAPI 的追溯鏈，供開發交接。

## 目錄結構

- [元件 (Components)](./components/README.md): UI 元件規格
  - [Kai 模組元件](./components/kai/): Kai 特有元件
  - [Container 模組元件](./components/container/): Container 特有元件
  - [Catalog 模組元件](./components/catalog/): Catalog 特有元件
  - [共用元件](./components/common/): 跨模組共用元件
- [流程 (Flows)](./flows/README.md): 使用者流程
- [頁面 (Pages)](./pages/README.md): 頁面規格
- [模式 (Patterns)](./patterns/README.md): 互動模式
- [角色 (Personas)](./personas/README.md): 使用者角色
- [需求 (Requirements)](./requirements/README.md): UX 需求
- [場景 (Scenarios)](./scenarios/README.md): 使用者場景
- [使用者故事 (User Stories)](./user-stories/README.md): 使用者故事

## 頁面 (Pages)

- Catalog: [page-kai-Catalog.md](./pages/kai/page-kai-Catalog.md) → SFS-F-023/024/025；APIs: `GET/POST/DELETE /api/catalog/flexy`, `POST /api/host/directories`
- Shell: [page-kai-Shell.md](./pages/kai/page-kai-Shell.md) → SFS-F-018/019；APIs: `GET /flexy/:id/shell`
- Docs: [page-kai-Docs.md](./pages/kai/page-kai-Docs.md) → SFS-F-020；APIs: `GET /flexy/:id/docs/*`
- Dashboard: [page-kai-Dashboard.md](./pages/kai/page-kai-Dashboard.md)
- CreateContainer: [page-kai-CreateContainer.md](./pages/kai/page-kai-CreateContainer.md)

## 流程 (Flows)

- Container 流程: [flow-container-001.md](./flows/container/flow-container-001.md)（容器列表）等
- Catalog 流程: [flow-catalog-001.md](./flows/catalog/flow-catalog-001.md)（Catalog 管理）
- Kai 流程: [flow-kai-001.md](./flows/kai/flow-kai-001.md)

## 元件 (Components)

### Container 模組
- ContainerList: [comp-container-ContainerList-001.md](./components/container/comp-container-ContainerList-001.md)
- ContainerCard: [comp-container-ContainerCard-002.md](./components/container/comp-container-ContainerCard-002.md)
- CreateContainerModal: [comp-container-CreateContainerModal-003.md](./components/container/comp-container-CreateContainerModal-003.md)

### Catalog 模組
- CatalogList: [comp-catalog-CatalogList-006.md](./components/catalog/comp-catalog-CatalogList-006.md)
- CreateCatalogItemModal: [comp-catalog-CreateCatalogItemModal-007.md](./components/catalog/comp-catalog-CreateCatalogItemModal-007.md)

### Common 模組
- DirectoryPicker: [comp-common-DirectoryPicker-006.md](./components/common/comp-common-DirectoryPicker-006.md)
- ConfirmationDialog: [comp-common-ConfirmationDialog-004.md](./components/common/comp-common-ConfirmationDialog-004.md)
- StatusBadge: [comp-common-StatusBadge-005.md](./components/common/comp-common-StatusBadge-005.md)

## 角色 (Personas)

- Container 開發者: [persona-container-Dev.md](./personas/container/persona-container-Dev.md)
- Kai 操作員: [persona-kai-Operator.md](./personas/kai/persona-kai-Operator.md)

## 需求追溯 (Requirements Traceability)

- SRS（Kai）: [specs/srs.md](../specs/srs.md) → 3.2.2（代理），3.2.3（host 目錄瀏覽），3.3（Catalog）
- SFS（Kai）: [specs/sfs.md](../specs/sfs.md) → F-018/019（Shell 代理）、F-020（Docs 代理）、F-022（Host 瀏覽）、F-023/024/025（Catalog）
- OpenAPI（Kai）: [specs/api/openapi.yaml](../specs/api/openapi.yaml) → 對應端點已定義

## Cross-Project

- Flexy UX Index: [Flexy/docs/ux/README.md](../../Flexy/docs/ux/README.md)
