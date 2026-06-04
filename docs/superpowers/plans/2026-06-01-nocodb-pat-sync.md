# NocoDB PAT Sync Implementation Plan

**Goal:** Migrate FlowTomato to NocoDB personal access token configuration.

## Tasks

- [x] Rename integration and tests to `nocodb`.
- [x] Remove the previous OAuth, loopback callback, and tenant token services.
- [x] Introduce `NocoDBWorkspaceConfig` with base URL, PAT, base/source IDs, and table IDs.
- [x] Add NocoDB meta API calls for base/table discovery and creation.
- [x] Cache discovered workspace IDs locally.
- [x] Update `NocoDBApiClient` to use `xc-token` and `/api/v2/tables/{tableId}/records`.
- [x] Update settings UI to collect and validate NocoDB configuration.
- [x] Store the provided PAT in ignored `.env.local`.
- [x] Add `.env.example` without secrets.
- [x] Update product and technical docs to use NocoDB.
- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
