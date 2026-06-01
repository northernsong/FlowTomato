# FlowTomato Agent Harness

This repository is a Flutter-first personal productivity app that combines today tasks, a Pomodoro timer, local-first storage, and later Feishu Base sync.

## Start Here

Before making changes, read these documents in order:

1. `docs/brd.md` - business direction and phased product rhythm.
2. `docs/prd.md` - product requirements, user flows, data fields, and acceptance criteria.
3. `docs/technical-design.md` - Flutter architecture, module boundaries, storage design, and implementation phases.
4. `README.md` - public project summary and current setup notes.

After reading, identify which implementation phase your task belongs to:

1. Phase 1: Flutter project, local fake data, polished UI, basic task and timer interaction.
2. Phase 2: local persistence with SQLite/Drift.
3. Phase 3: Feishu Base sync and sync queue.
4. Phase 4: macOS packaging and desktop experience.

## Current Implementation Priority

Work on Phase 1 first unless the user explicitly asks otherwise.

Phase 1 must deliver:

1. A Flutter app that runs on macOS.
2. A first screen with Now, Todo, Done, and Pomodoro sections.
3. Local in-memory task state.
4. Core task operations: create, set Now, complete, restore, delete, reorder if practical.
5. Core timer operations: start, pause, resume, reset, complete a short development timer in tests.
6. A visual direction aligned with Linear + Things 3 + Raycast: quiet, focused, low saturation, macOS-like.

## Architecture Rules

Follow the architecture in `docs/technical-design.md`.

Keep dependencies flowing in this direction:

```text
UI -> application state -> domain/data services
```

Do not let widgets directly own complex business rules. Put task transitions and timer transitions in testable Dart classes or controllers.

Prefer these boundaries:

1. `lib/features/tasks/` for task domain and task state.
2. `lib/features/pomodoro/` for timer domain and timer state.
3. `lib/features/home/` for the main workbench UI.
4. `lib/app/` for app shell, theme, and routing.
5. `lib/shared/` for common widgets, formatting, and utilities.

## Testing Harness

For behavior changes, write tests first where practical.

Minimum verification before claiming work is complete:

```bash
flutter test
flutter analyze
```

If UI or platform setup changes, also run:

```bash
flutter run -d macos
```

Only report a command as passing if it was run in the current turn and exited successfully.

## Flutter Conventions

Use the local Flutter installation. This workspace has been checked with:

```text
Flutter 3.41.9 stable
Dart 3.11.5
```

Keep the first implementation lean:

1. Avoid introducing persistence before Phase 2.
2. Avoid Feishu API code before Phase 3.
3. Avoid desktop packaging work before Phase 4.
4. Use Flutter built-in widgets when they are enough.
5. Add third-party dependencies only when they remove real complexity.

## UX Rules

The app should open directly into the usable workbench. Do not add a marketing landing page.

The first viewport should make these clear:

1. What is currently being worked on.
2. What remains in today's todo list.
3. What has been completed today.
4. Whether the Pomodoro timer is idle, running, or paused.

Keep operational UI calm, dense, and readable. Prefer clear controls, stable layout dimensions, and concise labels.

## Git Safety

The worktree may contain user changes. Do not revert files you did not intentionally change.

Before editing existing files:

1. Check `git status --short`.
2. Read the target file.
3. Preserve unrelated changes.

Use small, scoped commits only when the user asks for commits.
