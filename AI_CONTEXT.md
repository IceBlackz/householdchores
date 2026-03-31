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
  providers/       ChoreProvider, HouseProvider, LocaleProvider (ChangeNotifier)
  screens/         dashboard/, add_chore/, complete_chore/, configuration/, history/, login/
  l10n/            ARB files + generated AppLocalizations
```

---

## Services — Critical design rules

### PocketBaseService (singleton)
`PocketBaseService()` is a singleton holding the single `PocketBase client` instance. All services share this client. Call `PocketBaseService().init(url)` once at startup. Call `PocketBaseService().setBaseUrl(url)` when switching houses.

### AuthService (singleton)
`AuthService()` is a singleton. It does **not** hold its own `PocketBase` instance. It uses a getter `PocketBase get _pb => PocketBaseService().client` so it always shares auth state with `ChoreService` and any other consumer of the same client.

> **DO NOT** give `AuthService` its own `PocketBase _pb` field — this was a previous bug that caused "Not initialized" at login because the field started as `null` and was never set.

### ChoreService
Injected via Provider with `PocketBaseService().client`. Has an optional `completedBy` parameter on `completeChore()` to mark tasks done on behalf of another user.

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
| `completed_by` | Relation → `users` | Can differ from the logged-in user |
| `photo_before` | File | Max 1 |
| `photo_after` | File | Max 1 |
| `notes` | Text | |

Index: `CREATE INDEX idx_chore_logs_chore_created ON chore_logs (chore, created DESC)`

### API Rules

All collections require `@request.auth.id != ""` for List/View/Create/Update.

---

## Core Business Logic

### Due Date Calculation

`Chore` exposes two date methods in `models/chore.dart`:

**`nextDueDate(DateTime lastCompleted, String activeSeason)`** — desired due date:
1. Check for a season-specific override (`season_spring_override` etc.) — use it if > 0.
2. Otherwise use `interval_desired_days`.
3. Apply the value using `interval_unit` arithmetic.

**`maxDueDate(DateTime lastCompleted)`** — hard deadline:
- Always uses `interval_max_days` with no season overrides.

```dart
static DateTime _addInterval(DateTime base, int value, String unit) {
  // days   → base.add(Duration(days: value))
  // weeks  → base.add(Duration(days: value * 7))
  // months → DateTime(y, m + value, d)   ← correct calendar arithmetic
  // quarters → DateTime(y, m + value*3, d)
  // years  → DateTime(y + value, m, d)
}
```

### Dashboard Status Logic (`ChoreListTile`)

Status is derived by comparing today against `dueDate` (desired) and `maxDueDate` (hard), both passed in from `ChoreProvider`:

| Condition | Label | Colour |
|-----------|-------|--------|
| `dueDate.year < 2000` (sentinel) | "Never completed" | Red |
| `today > maxDueDate` | "!! Xd past max" | Dark red + warning icon + red card tint |
| `today > dueDate` | "Overdue (X days)" | Orange — shows `abs()` days, never negative |
| `today == dueDate` | "Due today" | Orange |
| `today < dueDate` | "Due in X d" | Green |

### Dashboard Sorting (`ChoreProvider.refresh`)

1. Fetch all chores (with `default_assignee` + `onetimeonly_assignee` expanded).
2. Single batched query for latest log per chore (OR filter, sort `-created`, `putIfAbsent`).
3. For chores with no log: both `dueDate` and `maxDueDate` = `DateTime.now() - 9999 days` (sentinel, year < 2000).
4. Sort: assigned to current user first, then by ascending desired due date.

`ChoreProvider` exposes both:
- `DateTime? dueDate(String choreId)`
- `DateTime? maxDueDate(String choreId)`

### SSE Refresh Deduplication

`_onRealtimeEvent` checks `if (_isLoading) return` before triggering a refresh. This prevents a redundant double-fetch when a manual `completeChore()` call triggers an SSE event while its own `refresh()` is already in flight.

### One-Time Assignment Override

- `onetimeonly_assignee` overrides `default_assignee` for sorting and display.
- `ChoreService.completeChore()` clears it (PATCH `onetimeonly_assignee: ''`) atomically after creating the log.

### Complete on Behalf of Another User

`ChoreService.completeChore(choreId, {String? completedBy, ...})` accepts an optional `completedBy` user ID. If omitted, it falls back to `_pb.authStore.record?.id` (the logged-in user). The complete-chore screen fetches all users and shows a dropdown defaulting to the current user.

### N+1 Prevention

`ChoreService.fetchLatestLogPerChore(List<String> choreIds)` uses a single OR-filtered query:
```dart
filter = choreIds.map((id) => 'chore="$id"').join('||')
```
Records arrive sorted `-created`; `putIfAbsent` keeps only the first (latest) per chore.

---

## Multi-House Support

`HouseProvider` manages a list of `House` objects persisted to `SharedPreferences`. Key points:

- `addHouse(...)` returns `Future<String>` (the new house's ID) so the caller can immediately `switchHouse(newId)` — **do not use** `houseProvider.activeHouseId` after `addHouse`, it still points to the previously active house.
- `refresh()` is a public method that calls `notifyListeners()`. It exists because `notifyListeners()` is `@protected` and cannot be called from outside the class.
- The `ConfigurationScreen` requires `houseToEdit` to be passed when editing — it uses this in `initState()` to pre-fill controllers. If not passed, the screen opens in "add" mode with defaults.
- `ConfigurationScreen` uses `SingleTickerProviderStateMixin` and a `TabController` — the `TabBar` is in the `AppBar.bottom`. The screen jumps to tab index 1 (the form) when opened in edit mode.

---

## Localisation

- **Packages:** `flutter_localizations` (SDK), `intl: ^0.20.0`, `shared_preferences: ^2.3.3`
- **Config:** `frontend/l10n.yaml` → ARB dir `lib/l10n/`, template `app_en.arb`
- **Languages:** English (`en`), Dutch (`nl`), Spanish (`es`)
- **Generation:** `flutter gen-l10n` (or `flutter build`) generates `lib/l10n/app_localizations*.dart`
- **Runtime:** `LocaleProvider` reads/writes `locale_language_code` key via `shared_preferences`. `null` = device locale.
- **Usage:** Always retrieve `l10n` before any `await` to avoid BuildContext-across-async-gap lint warnings.
- **Season filter labels** in `_SeasonFilterBar` use `l10n.spring`, `.summer`, `.autumn`, `.winter`, `.allSeasons` — **never** raw English strings.

---

## Framework Quirks & Gotchas

### PocketBase Dart SDK

- **DO NOT** use `record.expand['field']` — use `record.get<RecordModel?>('expand.field')`.
- **DO NOT** use `record.created` — use `record.getStringValue('created')`.
- **DO NOT** use `getFirstListItem()` when the result may be empty (throws 404). Use `getFullList` with a filter.
- `RecordModel` constructor takes no named params. For test records use `RecordModel.fromJson({...})` with `id`, `collectionId`, `collectionName` at top level and `expand` as a nested key.
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

### http Package (v1.x)

`timeout` is **not** a named parameter on `http.Client.get()`. Chain it on the Future:
```dart
await client.get(uri).timeout(Duration(milliseconds: timeoutMs));
```

### ChangeNotifierProvider

Always use `create:` for providers that the widget tree owns:
```dart
ChangeNotifierProvider<HouseProvider>(create: (_) => HouseProvider())
```
Never use `.value()` with a freshly constructed object — it won't be disposed when removed from the tree.

---

## Backend Migrations

JavaScript files in `backend/pb_migrations/` — auto-applied on container start (volume-mounted). Format:
```js
migrate((app) => { /* up */ }, (app) => { /* down */ })
```

Collections are referenced by internal ID. Use `app.findCollectionByNameOrId("chores")` if ID is unknown.

New fields use `new Field({...})` with a stable `id` (e.g. `"select1234567801"`).

---

## Home Assistant Integration

### Option B — Webhook on completion (included)

`backend/pb_hooks/notify_homeassistant.pb.js` fires on `chore_logs` create and POSTs to `HA_WEBHOOK_URL` from `backend/.env`. Hook sends: `{ chore, completed_by, notes }`.

`pb_hooks/` is volume-mounted so changes apply on `docker compose restart` without rebuilding.

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
docker compose restart             # restart (picks up pb_hooks/ changes)
docker compose logs -f pocketbase  # live logs

# Frontend
flutter pub get
flutter analyze                    # must return zero issues
flutter gen-l10n                   # regenerate after editing ARB files
flutter run -d chrome
flutter build web --dart-define=BACKEND_URL=http://<ip>:9010
flutter build apk --release --dart-define=BACKEND_URL=http://<ip>:9010
```