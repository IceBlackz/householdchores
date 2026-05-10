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
| Install/distribution | PWA install page, optional Android APK download, Apache/npm HTTPS docs |

## Project Structure

```text
householdchores/
  docker-compose.yaml
  Dockerfile
  README.md
  AI_CONTEXT.md
  https-proxy.example.json
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
    web/
      config.js
      install.html
      manifest.json
      downloads/.gitkeep
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
- `backend/nginx.conf` serves Flutter web, `/install.html`, `/config.js`, and APK files from `/downloads/`.

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

## Install, PWA, and APK Distribution

The web app includes a static install page:

```text
frontend/web/install.html
```

Served URL:

```text
http://server:9011/install.html
```

Important behavior:

- `frontend/web/manifest.json` has app metadata for installable PWA behavior.
- `frontend/web/config.js` optionally overrides the web backend URL at runtime.
- If `config.js` has an empty `backendUrl`, web defaults to the same host on port `9010`.
- For HTTPS reverse proxies, set `backendUrl` to the HTTPS API/base URL before rebuilding the web container.
- The install page links to `/downloads/householdchores-latest.apk`.
- `frontend/web/downloads/.gitkeep` keeps the folder present, but APK files are ignored by git.

PWA versus APK setup:

- PWA installs open the same website they were installed from and reuse `config.js`, so connection setup is easy.
- APK installs do not automatically know which website they were downloaded from. A future QR/deep-link onboarding flow would be needed to prefill the server URL.
- Never put usernames or passwords in install URLs.

HTTPS options documented in `README.md`:

- npm test proxy using `https-proxy.example.json` and `npx local-ssl-proxy`.
- Apache reverse proxy with Let's Encrypt.

Apache is the preferred lightweight production-ish path when available because one HTTPS hostname can serve both the web app and PocketBase paths:

- `/` -> web container on `9011`
- `/api/` -> PocketBase on `9010`
- `/_/` -> PocketBase admin on `9010`

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

Tracks configured houses and active house. Web backend URL comes from `frontend/web/config.js` when configured, otherwise it auto-detects the current host with backend port `9010`.

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
curl http://localhost:9011/install.html
curl http://localhost:9011/config.js
```

Useful browser smoke tests:

- Open `http://localhost:9011/` and confirm the login page renders.
- Open `http://localhost:9011/install.html` and confirm the install page shows the detected backend URL.

## Release Script

`release.ps1`:

- Bumps app/server version references.
- Builds the Android APK.
- Copies the release APK to the repository root as `householdchores-vX.Y.Z.apk`.
- Copies the latest APK to `frontend/web/downloads/householdchores-latest.apk` for server downloads.
- Commits, tags, pushes, and optionally creates a GitHub release if `gh` is installed.

APK files are ignored by git.

## Common Gotchas

- Do not revert unrelated dirty work. The repo may already contain user changes.
- Do not delete `backend/pb_data/`.
- Do not use `git reset --hard` unless the user explicitly requests it.
- Use `apply_patch` for manual edits.
- On Windows, Flutter/Dart commands may need to run outside sandbox because SDK/cache access can hang or be denied.
- PocketBase `getFirstListItem()` throws on 404. Use `getFullList()` when an empty result is expected.
- Capture Flutter `BuildContext` dependencies before `await`, then check `mounted` after awaits.
- For Flutter web uploads, use bytes-based multipart files.
- Keep cleanup simple: stale local planning/tool files should not be committed unless they document real project behavior.
