# AI Developer Context

Hello AI assistant! Read this document carefully before making any changes. It describes the full architecture, schema, business logic, known bugs, and conventions for the Household Chores app.

---

## Architecture

| Layer | Technology |
|-------|-----------|
| Backend | PocketBase (Go) in Docker on port 9010 |
| Web server | nginx:alpine in Docker on port 9011 |
| Frontend | Flutter (Dart) — Web, Android, iOS, Desktop |
| State management | Provider (`ChangeNotifier`) |
| Localisation | `flutter_localizations` + `intl` + ARB files |
| Auth | PocketBase email/password; JWT handled by `pocketbase` Dart SDK |

### Project structure

```
householdchores/               ← repo root — run docker compose from here
  docker-compose.yaml          ← orchestrates pocketbase + web
  Dockerfile.web               ← multi-stage: Flutter build → nginx
  .dockerignore                ← excludes .dart_tool/ and build/ from Docker context
  VERSION                      ← single version source of truth (e.g. 1.0.0)
  release.ps1                  ← version bump, APK build, git tag, push
  prepare_context.bat          ← cleans project and zips for AI handoff
  backend/
    Dockerfile                 ← PocketBase container
    nginx.conf                 ← nginx config (baked into web image)
    .env                       ← ADMIN_EMAIL, ADMIN_PASSWORD, HA_WEBHOOK_URL
    pb_hooks/                  ← volume-mounted JS hooks
      version.pb.js            ← exposes GET /api/householdchores/version
      notify_homeassistant.pb.js
    pb_migrations/             ← volume-mounted, auto-applied on start
    pb_data/                   ← bind-mounted SQLite + uploads — NEVER deleted
  frontend/
    lib/
      config/app_config.dart   ← appVersion const + dynamic backendUrl getter
      constants/               ← AppConstants, Collections, IntervalUnits
      models/                  ← Chore, ChoreLog, AppUser (typed, immutable)
      services/                ← ChoreService, AuthService, PocketBaseService,
                                  VersionService, ConnectionValidator
      providers/               ← ChoreProvider, HouseProvider, LocaleProvider
      screens/
        dashboard/             ← main chore list + season filter
        login/                 ← login + version check + house switcher
        add_chore/             ← create/edit chore form
        complete_chore/        ← mark done + completed-by picker + photos
        configuration/         ← house management (add/edit/delete/test)
        history/               ← completion log per chore
        admin/                 ← user_management_screen.dart (admin only)
      l10n/                    ← app_en.arb, app_nl.arb, app_es.arb + generated
```

---

## Docker — critical rules

**Always run docker compose from the repo root**, never from `backend/`:
```bash
docker compose up -d --build   # build + start
docker compose logs -f pocketbase
docker compose restart pocketbase
docker compose down
```

**Why `docker-compose.yaml` is at root:** Both services need to see `frontend/` and `backend/`. Using a single build context (`.`) with explicit dockerfile paths avoids a Docker Desktop Windows bug where BuildKit fails to resolve dockerfile paths when services have different contexts.

**`.dockerignore` is critical.** It excludes `frontend/.dart_tool/` which contains `package_config.json` with Windows absolute paths (`C:\Users\...`) that break `dart format` inside the Linux container. Never remove it.

**Data safety:** `backend/pb_data/` is a bind mount. It survives any `docker compose up -d --build` or `docker compose down`. Never add it to `.dockerignore`.

---

## Services — critical design rules

### PocketBaseService (singleton)
Single `PocketBase client` instance. All services share it. Initialised in `main.dart` via `PocketBaseService().init(AppConfig.backendUrl)`.

### AuthService (singleton)
Uses `PocketBase get _pb => PocketBaseService().client` — **never** a separate `PocketBase? _pb` field. The old pattern caused "Not initialized" at login. Has `isCurrentUserAdmin` getter.

### HouseProvider
`defaultLocalHouseUrl` is a **static getter** delegating to `AppConfig.backendUrl` — **never** a `const String`. On web, `AppConfig.backendUrl` reads `Uri.base` and returns `http://[same-host]:9010`, so the app served from `:9011` automatically connects to `:9010`.

### VersionService
Calls `GET /api/householdchores/version` before login. MAJOR version mismatch blocks login. Missing endpoint / network error shows a dismissable warning. `endpointNotFound` means the server predates versioning.

### ChoreService
`completeChore(choreId, {String? completedBy, ...})` — `completedBy` defaults to logged-in user but can be overridden to mark a chore done on behalf of another user.

---

## Backend URL — web auto-detection

`AppConfig.backendUrl` (in `lib/config/app_config.dart`):
```dart
static String get backendUrl {
  if (kIsWeb) {
    final base = Uri.base;          // e.g. http://192.168.1.42:9011
    return '${base.scheme}://${base.host}:9010';  // → http://192.168.1.42:9010
  }
  return String.fromEnvironment('BACKEND_URL', defaultValue: 'http://127.0.0.1:9010');
}
```
This means the web app requires **zero configuration** — it always talks to the backend on the same host.

---

## Versioning

- `VERSION` file at repo root is the single source of truth
- `backend/pb_hooks/version.pb.js` exposes `GET /api/householdchores/version`
- `AppConfig.appVersion` constant in `app_config.dart`
- `release.ps1` updates all three atomically, builds APK, tags git
- MAJOR version compatibility: app 1.x ↔ server 1.x ✓ — app 1.x ↔ server 2.x ✗

---

## Database Schema

### `chores`

| Field | Type | Notes |
|-------|------|-------|
| `title` | Text | |
| `description` | Text | |
| `interval_desired_days` | Number | Target recurrence value |
| `interval_max_days` | Number | Hard deadline value |
| `interval_unit` | Select | `days`/`weeks`/`months`/`quarters`/`years` |
| `season` | Select | `All`/`Spring`/`Summer`/`Autumn`/`Winter` |
| `default_assignee` | Relation → `users` | Max 1, optional |
| `onetimeonly_assignee` | Relation → `users` | Cleared on completion |
| `season_spring_override` | Number | 0 = use default |
| `season_summer_override` | Number | |
| `season_autumn_override` | Number | |
| `season_winter_override` | Number | |

### `chore_logs`

| Field | Type | Notes |
|-------|------|-------|
| `chore` | Relation → `chores` | cascadeDelete = true |
| `completed_by` | Relation → `users` | Can differ from logged-in user |
| `photo_before` | File | Max 1 |
| `photo_after` | File | Max 1 |
| `notes` | Text | |

Index: `CREATE INDEX idx_chore_logs_chore_created ON chore_logs (chore, created DESC)`

### `users` (auth collection)

| Field | Type | Notes |
|-------|------|-------|
| `name` | Text | Display name |
| `email` | Text | Login credential |
| `is_admin` | Bool | Added by migration 1774900001 |

**Collection rules (post migration 1774900001):**
- Create/Delete: `@request.auth.id != "" && @request.auth.is_admin = true`
- Update: `@request.auth.id != "" && (@request.auth.is_admin = true || @request.auth.id = id)`

---

## Core Business Logic

### Due Date Calculation

`Chore` exposes two date methods:

**`nextDueDate(DateTime lastCompleted, String activeSeason)`** — desired:
1. Check season override (> 0 = use it, else use `intervalDesiredDays`)
2. Apply via `intervalUnit` arithmetic (months/quarters/years use calendar math, not days × N)

**`maxDueDate(DateTime lastCompleted)`** — hard deadline:
- Always uses `intervalMaxDays`, no season overrides

### Dashboard Status (`ChoreListTile`)

| Condition | Badge | Colour |
|-----------|-------|--------|
| `dueDate.year < 2000` (sentinel) | "Never completed" | Red |
| `today > maxDueDate` | "!! Xd past max" | Dark red + warning icon |
| `today > dueDate` | "Overdue (X days)" — `abs()` | Orange |
| `today == dueDate` | "Due today" | Orange |
| `today < dueDate` | "Due in X d" | Green |

### SSE Refresh Deduplication
`_onRealtimeEvent` checks `if (_isLoading) return` — prevents double-fetch when a manual `completeChore()` triggers an SSE event while its own `refresh()` is in flight.

### N+1 Prevention
`ChoreService.fetchLatestLogPerChore` batches all chore IDs into a single OR-filter query.

---

## User Management (Admin)

- `is_admin = true` users see a `manage_accounts` icon in the dashboard AppBar
- Opens `UserManagementScreen` — create/edit/delete users, set admin flag
- Cannot delete your own account
- Uses PocketBase's auth collection create/update/delete APIs

---

## Localisation: How to deliver new ARB keys

**Never ask the user to manually edit ARB files.** Always deliver a self-deleting PowerShell script named `patch_l10n.ps1` dropped into `frontend/`.

### Rules
- Use escaped double-quotes (`""`) — **never** PowerShell here-strings
- Idempotency: check with `-match` before inserting
- Always end with `flutter gen-l10n` then `Remove-Item`

### Template
```powershell
# patch_l10n.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$l10nDir = "$PSScriptRoot\lib\l10n"

function Add-Key($file, $key, $fragment) {
  $path = Join-Path $l10nDir $file
  $content = Get-Content $path -Raw -Encoding UTF8
  if ($content -match """$key""") {
    Write-Host "  $file - $key already present, skipping."; return
  }
  $content = $content.TrimEnd().TrimEnd('}').TrimEnd() + ",`n$fragment`n}"
  Set-Content $path -Value $content -Encoding UTF8 -NoNewline
  Write-Host "  $file - $key added."
}

Add-Key 'app_en.arb' 'myKey' '  "myKey": "English value"'
Add-Key 'app_nl.arb' 'myKey' '  "myKey": "Dutch value"'
Add-Key 'app_es.arb' 'myKey' '  "myKey": "Spanish value"'

Push-Location $PSScriptRoot
flutter gen-l10n
Pop-Location
Remove-Item "$PSScriptRoot\patch_l10n.ps1" -Force
```

For placeholder keys, build the annotation string using `+` concatenation (no here-strings).

---

## How to deliver code files to the user

**Always deliver complete files — never diffs, partial snippets, or "replace this section".**

Use `create_file` → `/mnt/user-data/outputs/filename` then `present_files`. Do this for **every** source file that changes.

If a file would exceed ~400 lines, split it first (extract widgets to `widgets/`, helpers to services), then deliver both smaller files in full.

**Never** paste source files inline in chat as code blocks — use the file tool. Inline blocks are only for: short illustrations, CLI commands, and `patch_l10n.ps1` scripts.

---

## Framework Quirks & Gotchas

### PocketBase Dart SDK
- Use `record.get<RecordModel?>('expand.field')` — not `record.expand['field']`
- Use `record.getStringValue('created')` — not `record.created`
- Never use `getFirstListItem()` when result may be empty (throws 404) — use `getFullList` with filter
- `subscribe()` returns `Future<UnsubscribeFunc>` — store and call in `dispose()`

### Flutter Web File Uploads
```dart
final bytes = await xfile.readAsBytes();
http.MultipartFile.fromBytes('field', bytes, filename: xfile.name)
```

### Flutter Colors
Use `.withValues(alpha: 0.1)` not deprecated `.withOpacity(0.1)`

### BuildContext Across Async Gaps
Capture `l10n`, `ScaffoldMessenger` etc. **before** any `await`. Guard with `if (mounted)` after.

### http Package (v1.x)
Chain `.timeout()` on the Future — it is not a named param:
```dart
await client.get(uri).timeout(Duration(milliseconds: ms));
```

### ChangeNotifierProvider
Always use `create:` — never `.value()` with a freshly constructed object.

### Docker + Windows
`.dockerignore` **must** exclude `frontend/.dart_tool/` — it contains `package_config.json` with Windows absolute paths that break `dart format` in the Linux container.

---

## Backend Migrations

JS files in `backend/pb_migrations/` auto-apply on container start. Format:
```js
migrate((app) => { /* up */ }, (app) => { /* down */ })
```
Reference collections by `app.findCollectionByNameOrId("name")`. New fields need a stable `id` string.

---

## Useful Commands

```bash
# From repo root:
docker compose up -d --build      # start / rebuild everything
docker compose restart pocketbase # restart backend (picks up hook changes)
docker compose logs -f pocketbase # live backend logs
docker compose ps                 # check container status

# Frontend (from frontend/):
flutter pub get
flutter analyze                   # must return zero issues
flutter gen-l10n                  # after editing ARB files
flutter run -d chrome             # dev run (connects to localhost:9010)

# Release (from repo root):
.\release.ps1 -Version X.Y.Z     # full release pipeline
```