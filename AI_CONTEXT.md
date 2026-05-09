# AI Developer Context

This document is for future AI/developer sessions. It summarizes the current architecture, conventions, and important gotchas for Household Chores Manager.

## Current Architecture

| Layer | Technology |
| --- | --- |
| Backend | PocketBase in Docker on port 9010 |
| Web app | Flutter web build served by nginx on port 9011 |
| Mobile app | Flutter Android/iOS |
| State management | Provider and ChangeNotifier |
| Auth | PocketBase email/password auth |
| Localization | Flutter gen-l10n with EN/NL/ES ARB files |
| Notifications | Local Android/iOS notifications plus optional Home Assistant webhook digest |

## Project Structure

```text
householdchores/
  docker-compose.yaml
  Dockerfile
  README.md
  AI_CONTEXT.md
  backend/
    .env.example
    entrypoint.sh
    nginx.conf
    pb_data/
    pb_hooks/
      due_reminders.pb.js
      notify_homeassistant.pb.js
      version.pb.js
    pb_migrations/
  frontend/
    lib/
      config/
      constants/
      l10n/
      models/
        notification_settings.dart
      providers/
      screens/
        admin/
        dashboard/
      services/
        notification_service.dart
        settings_service.dart
```

## Docker Rules

Run Docker Compose from the repository root:

```powershell
docker compose up -d --build
docker compose ps
docker compose logs -f pocketbase
docker compose restart pocketbase
```

Important:

- `Dockerfile` has two targets: `pocketbase` and `web`.
- `docker-compose.yaml` builds both services from the repository root.
- `backend/pb_data/` is persistent application data. Never delete it unless the user explicitly asks.
- `backend/pb_migrations/` and `backend/pb_hooks/` are mounted into the PocketBase container.
- `.dockerignore` must exclude Flutter generated folders such as `frontend/.dart_tool/` and build output.

## Backend Startup

`backend/entrypoint.sh` starts PocketBase and upserts the configured superuser from:

```env
ADMIN_EMAIL
ADMIN_PASSWORD
```

The PocketBase superuser is for the PocketBase admin UI. Normal app users live in the `users` auth collection.

## App User Admin Flow

The first normal app user must be created in PocketBase admin UI:

1. Log into `http://localhost:9010/_/` with the superuser.
2. Open `users`.
3. Create a user.
4. Set `is_admin = true`.

After that, app admins can manage users from the dashboard.

## Collections

### `chores`

Important fields:

- `title`
- `description`
- `interval_desired_days`
- `interval_max_days`
- `interval_unit`: days/weeks/months/quarters/years
- `season`: All/Spring/Summer/Autumn/Winter
- `default_assignee`
- `onetimeonly_assignee`
- `season_spring_override`
- `season_summer_override`
- `season_autumn_override`
- `season_winter_override`

### `chore_logs`

Important fields:

- `chore`
- `completed_by`
- `photo_before`
- `photo_after`
- `notes`

### `users`

PocketBase auth collection with app-specific fields:

- `name`
- `is_admin`

### `app_settings`

Stores admin-configurable app settings.

Current key:

```text
notification_settings
```

Value is JSON represented by `NotificationSettings` in `frontend/lib/models/notification_settings.dart`.

## Notification Behavior

Admin settings screen:

```text
frontend/lib/screens/admin/app_settings_screen.dart
```

Settings service:

```text
frontend/lib/services/settings_service.dart
```

Local notification scheduler:

```text
frontend/lib/services/notification_service.dart
```

Important behavior:

- Local notifications are supported only on Android, iOS, and macOS.
- Web returns early and does not try to initialize local notifications.
- Notifications are scheduled after dashboard chore sync.
- `matchDateTimeComponents: DateTimeComponents.time` repeats reminders daily at the configured time.
- Quiet hours can move the reminder time outside the quiet window.
- Escalation days can make overdue chores count as critical.
- The action ID `complete` opens the app and completes the chore for the signed-in user.

Server push is not implemented yet. The settings model has `serverPushEnabled`, but true push still needs FCM/APNs credentials, device-token registration, and a backend sender.

## Home Assistant Hooks

`backend/pb_hooks/notify_homeassistant.pb.js` can notify Home Assistant when a chore is completed.

`backend/pb_hooks/due_reminders.pb.js` provides:

- Cron-driven due reminder digest.
- Manual endpoint: `POST /api/householdchores/reminders/send?token=...`
- Action endpoint: `/api/householdchores/actions/complete?token=...`

The due digest reads app settings first, with environment variables as fallback.

Useful env vars:

```env
HA_WEBHOOK_URL
HA_DUE_WEBHOOK_URL
HA_DUE_REMINDER_CRON
HA_ACTION_SECRET
PUBLIC_BACKEND_URL
HA_ACTION_TOKEN_TTL_SECONDS
```

## Frontend Services

### PocketBaseService

Singleton PocketBase client. Other services should use `PocketBaseService().client`.

### AuthService

Uses the shared PocketBase client. Do not create a separate PocketBase instance inside AuthService.

### HouseProvider

Tracks configured houses and active house. Web auto-detects backend URL from the current host and port `9010`.

### ChoreProvider

Fetches chores, latest logs, due dates, and max due dates. Exposes `dueDates` and `maxDueDates` maps for notification scheduling.

### ChoreService

Uses the shared PocketBase client dynamically, so house switching works.

## Localization

Source files:

```text
frontend/lib/l10n/app_en.arb
frontend/lib/l10n/app_nl.arb
frontend/lib/l10n/app_es.arb
```

After editing ARB files:

```powershell
cd frontend
flutter gen-l10n
```

Generated files in `frontend/lib/l10n/app_localizations*.dart` are currently committed in this project.

## Verification Commands

From `frontend/`:

```powershell
flutter analyze
flutter test
```

From repo root:

```powershell
docker compose up -d --build
docker compose ps
curl http://localhost:9010/api/health
curl http://localhost:9011/
```

## Common Gotchas

- Do not revert unrelated dirty work. The repo may already contain user changes.
- Do not delete `backend/pb_data/`.
- Do not use `git reset --hard` unless the user explicitly requests it.
- Use `apply_patch` for manual edits.
- On Windows, Flutter/Dart commands may need to run outside sandbox because SDK/cache access can hang or be denied.
- PocketBase `getFirstListItem()` throws on 404. Use `getFullList()` when an empty result is expected.
- Capture Flutter `BuildContext` dependencies before `await`, then check `mounted` after awaits.
- For Flutter web uploads, use bytes-based multipart files.
