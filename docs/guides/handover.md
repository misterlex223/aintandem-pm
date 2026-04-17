---
id: HANDOVER-UX-MAP
title: UX Handover Map (Kai × Flexy)
owner: lead@team
status: final
version: 0.1
last_reviewed: 2025-09-15
---

## Purpose
本文件彙整每個 UX 規格對應的開發任務，並提供追溯到 SRS/SFS/OpenAPI 的連結，作為工程師開發交接清單。

## Kai - Pages
- Catalog: `docs/ux/pages/UXpersona-kai-Catalog.md`
  - Dev Tasks: Implement list (GET /api/catalog/flexy), create (POST), delete (DELETE), directory picker (POST /api/host/directories), CTA to create container (POST /api/flexy), and navigation to Shell/Docs.
  - Trace: SFS F-023/024/025/022; SRS §3.3; OpenAPI paths.
- Shell: `docs/ux/pages/UXpersona-kai-Shell.md`
  - Dev Tasks: Implement proxy route and iframe; WS upgrade handling; error states.
  - Trace: SFS F-018/019; SRS §3.2.2; OpenAPI paths.
- Docs: `docs/ux/pages/UXpersona-kai-Docs.md`
  - Dev Tasks: Implement proxy route and iframe; 404 handling when app is absent.
  - Trace: SFS F-020; SRS §3.2.2; OpenAPI paths.
- Create Container: `docs/ux/pages/UXpersona-kai-CreateContainer.md`
  - Dev Tasks: Form with name + hostPath; DirectoryPicker integration; ensure `folderMapping = <hostPath>:/workspace`; POST /api/flexy; success actions.
  - Trace: SFS F-014/F-022; SRS §3.2.1; OpenAPI paths.

## Kai - Components
- Container: `docs/ux/components/comp-container-*`
- Catalog: `docs/ux/components/comp-catalog-CatalogList-006`, `comp-catalog-CreateCatalogItemModal-007`
- Common: `docs/ux/components/comp-common-DirectoryPicker-006`, `comp-common-ConfirmationDialog-004`, `comp-common-StatusBadge-005`

## Flexy - Pages
- Settings: `flexy/docs/ux/pages/UXP-flexy-Settings.md`
  - Dev Tasks: UI to view/edit config; GET/PUT /api/config; validation; default fallback.
  - Trace: SRS §9.1; SFS §4.5; OpenAPI paths.

## Flexy - Components
- ConfigForm: `flexy/docs/ux/components/UXC-core-ConfigForm-002`

## Indexes
- Kai UX Index: `docs/ux/README.md`
- Flexy UX Index: `flexy/docs/ux/README.md`

## References
- Kai SRS: `docs/specs/srs.md`
- Kai SFS: `docs/specs/sfs.md`
- Kai OpenAPI: `docs/specs/api/openapi.yaml`
- Flexy SRS: `flexy/docs/specs/srs.md`
- Flexy SFS: `flexy/docs/specs/sfs.md`
- Flexy OpenAPI: `flexy/docs/specs/api/openapi.yaml`
