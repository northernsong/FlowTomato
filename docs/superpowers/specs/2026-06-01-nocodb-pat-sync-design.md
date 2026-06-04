# NocoDB PAT Sync Design

## Goal

Replace the previous sync direction with a NocoDB integration based on a personal access token. FlowTomato stays local-first: task and timer actions remain instant, while sync code can read and write NocoDB records when configured.

## Scope

This slice covers:

- NocoDB personal access token configuration.
- Automatic discovery of `Tasks`, `Pomodoro`, and `DailySummary` table IDs.
- Confirmed initialization when the FlowTomato base or required tables do not exist.
- Record list, create, and update wrappers.
- Field mapping for task and pomodoro records.
- A setup service that finds or creates the FlowTomato base and required tables.
- A local cache for discovered workspace IDs.
- A settings dialog that can read local development values from Dart environment variables.

The user supplies only the NocoDB URL and personal access token. The app discovers existing table IDs or asks for confirmation before creating the schema.

## Configuration

Local development uses these variables:

```bash
NOCO_BASE_URL=http://127.0.0.1:8080
NOCO_TOKEN=nc_pat_xxx
```

The real token belongs in `.env.local`, which is ignored by Git. `.env.example` documents the variable names without secrets.

## Architecture

`lib/integrations/nocodb/` contains the platform-specific integration:

- `NocoDBWorkspaceConfig`: base URL, PAT, base/source IDs, and table IDs.
- `NocoDBHttpClient`: small HTTP abstraction for tests and future real clients.
- `NocoDBApiClient`: wraps `/api/v2/meta/...` for schema setup and `/api/v2/tables/{tableId}/records` for records.
- `NocoDBFieldMapper`: converts domain objects to NocoDB field maps.
- `NocoDBSetupService`: discovers or initializes the FlowTomato base and tables.
- `NocoDBWorkspaceCache`: persists discovered IDs locally.
- `NocoDBSyncService`: task search/create/update convenience layer.

UI and controllers should depend on repositories or sync services, not on raw NocoDB field structure.

## Verification

Before claiming completion, run:

```bash
flutter test
flutter analyze
```

Run `flutter run -d macos` when UI/platform behavior changes.
