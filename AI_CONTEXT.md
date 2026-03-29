# AI Developer Context

Hello AI assistant! Read this document carefully before making changes. It describes the architecture, schema, business logic, and framework quirks of the Household Chores app.

---

## Architecture

| Layer | Technology |
|-------|-----------|
| Backend | PocketBase (Go) in Docker on port 9010 |
| Frontend | Flutter (Dart) — Web, Desktop, Mobile |
| State management | Provider (`ChangeNotifier`) |
| Localisation | `flutter_localizations` + `intl` + ARB files |
| Auth | PocketBase email/password; JWT handled by `pocketbase` Dart SDK |

### Frontend Layer Structure

```
lib/
  config/          app_config.dart — BACKEND_URL dart-define
  constants/       app_constants.dart — AppConstants, Collections, IntervalUnits
  models/          Chore, ChoreLog, AppUser (typed, immutable)
  services/        ChoreService, AuthService, PocketBaseService (singleton)
  providers/       ChoreProvider, LocaleProvider (ChangeNotifier)
  screens/         dashboard/, add_chore/, complete_chore/, history/, login/
  l10n/            ARB files + generated AppLocalizations
```

---

## Database Schema

### `chores` (Base collection)

| Field | Type | Notes |
|-------|------|-------|
| `title` | Text | |
| `description` | Text | |
| `interval_desired_days` | Number | Target recurrence value |
| `interval_max_days` | Number | Hard deadline value |
| `interval_unit` | Select | `days`/`weeks`/`months`/`quarters`/`years` — default `days` |
| `season` | Select | `All`/`Spring`/`Summer`/`Autumn`/`Winter` |
| `default_assignee` | Relation → `users` | Max 1, optional |
| `onetimeonly_assignee` | Relation → `users` | Max 1, cycle override — cleared on completion |
| `season_spring_override` | Number | Override interval for Spring (0 = use default) |
| `season_summer_override` | Number | Override interval for Summer |
| `season_autumn_override` | Number | Override interval for Autumn |
| `season_winter_override` | Number | Override interval for Winter |

### `chore_logs` (Base collection)

| Field | Type | Notes |
|-------|------|-------|
| `chore` | Relation → `chores` | cascadeDelete = true |
| `completed_by` | Relation → `users` | |
| `photo_before` | File | Max 1 |
| `photo_after` | File | Max 1 |
| `notes` | Text | |

Index: `CREATE INDEX idx_chore_logs_chore_created ON chore_logs (chore, created DESC)`

### API Rules

All collections require `@request.auth.id != ""` for List/View/Create/Update.

---

## Core Business Logic

### Due Date Calculation

`Chore.nextDueDate(DateTime lastCompleted, String activeSeason)` in `models/chore.dart`:

1. Check for a season-specific override (`season_spring_override` etc.) — use it if > 0.
2. Otherwise use `interval_desired_days`.
3. Apply the value using `interval_unit` arithmetic:
   - `days` → `base.add(Duration(days: value))`
   - `weeks` → `base.add(Duration(days: value * 7))`
   - `months` → `DateTime(y, m + value, d)` (correct calendar arithmetic, not days × 30)
   - `quarters` → `DateTime(y, m + value * 3, d)`
   - `years` → `DateTime(y + value, m, d)`

### Dashboard Sorting (`ChoreProvider.refresh`)

1. Fetch all chores (with `default_assignee` + `onetimeonly_assignee` expanded).
2. Single batched query for latest log per chore (OR filter, sort `-created`, `putIfAbsent`).
3. For chores with no log: due date = `DateTime.now() - 9999 days` (sentinel, year < 2000 on display).
4. Sort: assigned to current user first, then by ascending due date.

### One-Time Assignment Override

- `onetimeonly_assignee` overrides `default_assignee` for sorting and display.
- `ChoreService.completeChore()` clears it (PATCH `onetimeonly_assignee: ''`) atomically after creating the log.

### N+1 Prevention

`ChoreService.fetchLatestLogPerChore(List<String> choreIds)` uses a single OR-filtered query:
```dart
filter = choreIds.map((id) => 'chore="$id"').join('||')
```
Records arrive sorted `-created`; `putIfAbsent` keeps only the first (latest) per chore.

---

## Realtime Sync (SSE)

`ChoreProvider` subscribes to PocketBase SSE after first load:

```dart
_unsubscribeChores = await pb.collection('chores').subscribe('*', _onRealtimeEvent);
_unsubscribeLogs   = await pb.collection('chore_logs').subscribe('*', _onRealtimeEvent);
```

Any event from either collection triggers a full `refresh()`. Subscriptions are cancelled in `dispose()`. `DashboardScreen.initState` calls `refresh()` then `initRealtime()` via a `addPostFrameCallback`.

---

## Localisation

- **Packages:** `flutter_localizations` (SDK), `intl: ^0.20.0`, `shared_preferences: ^2.3.3`
- **Config:** `frontend/l10n.yaml` → ARB dir `lib/l10n/`, template `app_en.arb`
- **Languages:** English (`en`), Dutch (`nl`), Spanish (`es`)
- **Generation:** `flutter gen-l10n` (or `flutter build`) generates `lib/l10n/app_localizations*.dart`
- **Runtime:** `LocaleProvider` (ChangeNotifier) reads/writes `locale_language_code` key via `shared_preferences`. `null` = use device locale. Globe icon in `DashboardScreen` AppBar opens a language picker dialog.
- **Usage:** `AppLocalizations.of(context)!.someKey` — always retrieve `l10n` before any `await` to avoid BuildContext-across-async-gap lint warnings.

---

## Framework Quirks & Gotchas

### PocketBase Dart SDK

- **DO NOT** use `record.expand['field']` — use `record.get<RecordModel?>('expand.field')`.
- **DO NOT** use `record.created` — use `record.getStringValue('created')`.
- **DO NOT** use `getFirstListItem()` when the result may be empty (throws 404). Use `getFullList` with a filter.
- `RecordModel` constructor takes no named params. To create test records use `RecordModel.fromJson({...})` with all fields including `id`, `collectionId`, `collectionName` in the top-level map, and `expand` as a nested map key.
- `subscribe()` returns `Future<UnsubscribeFunc>` — store and call in `dispose()`.

### Flutter Web File Uploads

Cannot use `dart:io` or file paths on Web. Use:
```dart
final bytes = await xfile.readAsBytes();
http.MultipartFile.fromBytes('field_name', bytes, filename: xfile.name)
```

### Flutter Colors

Use `.withValues(alpha: 0.1)` instead of deprecated `.withOpacity(0.1)` for Wide Gamut support.

### BuildContext Across Async Gaps

Capture anything from `context` (e.g. `AppLocalizations.of(context)!`, `ScaffoldMessenger.of(context)`) **before** any `await`. Guard post-await context use with `if (mounted)`.

---

## Backend Migrations

JavaScript files in `backend/pb_migrations/` — auto-applied on container start (volume-mounted). Format:
```js
migrate((app) => { /* up */ }, (app) => { /* down */ })
```

Collections are referenced by internal ID (`"pbc_1145403802"` for `chores`). Use `app.findCollectionByNameOrId("chores")` if ID is unknown.

New fields use `new Field({...})` with a stable `id` (e.g. `"select1234567801"`).

---

## Home Assistant Integration

### Option A — REST sensor

Poll the PocketBase API from `configuration.yaml`. No backend changes needed.

### Option B — Webhook on completion (included)

`backend/pb_hooks/notify_homeassistant.pb.js` fires on `chore_logs` create and POSTs to a configured HA webhook URL. Enable by setting `HA_WEBHOOK_URL` in `backend/.env` and restarting. Hook sends: `{ chore, completed_by, notes }`.

`pb_hooks/` is volume-mounted in `docker-compose.yaml` so changes apply on restart without rebuilding.

### Option C — MQTT bridge

A standalone script subscribes to PocketBase SSE (`GET /api/realtime`) and publishes to MQTT. Best for users who already have MQTT configured in HA. Not included — generate with an AI assistant as needed.

---

## Configuration

`frontend/lib/config/app_config.dart` reads `BACKEND_URL` from `--dart-define`:
```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://192.168.1.42:9010
```
Defaults to `http://localhost:9010` if not set.

---

## Useful Commands

```bash
# Backend
docker compose up -d --build      # start / rebuild
docker compose restart             # restart (picks up hook changes)
docker compose logs pocketbase     # view logs

# Frontend
flutter pub get
flutter analyze                    # must return zero issues
flutter gen-l10n                   # regenerate after editing ARB files
flutter run -d chrome
flutter build web --dart-define=BACKEND_URL=http://<ip>:9010
```
