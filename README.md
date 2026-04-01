# Household Chores Manager

Human input: (Currently broken, intermidiate update. App won't connect to server with "Cannot connect to server" error. Might have to do with the integration of the flutter web folder to the server version, not happy with current implementation.)
A smart, self-hosted household task manager that eliminates the "whose turn is it?" debate. Runs on your local network — no cloud subscriptions, no data leaving your home.

Built with Flutter (Web/Desktop/Mobile) and PocketBase, designed for small home servers like a Jetson Nano or Raspberry Pi.

## Features

- **Smart sorting** — tasks assigned to you float to the top; everything else sorted by how overdue it is
- **Hard deadlines** — critical warning when a task passes its maximum interval
- **Flexible intervals** — days, weeks, months, quarters, or years
- **Season-specific schedules** — different intervals per season (e.g. gutters every 3 months in autumn)
- **Assignments** — default owner per chore; one-time override without changing the default
- **Complete on behalf of** — mark a chore done for any household member
- **User management** — admin users can add, edit, and delete household members from within the app
- **Multiple houses** — configure multiple PocketBase servers and switch between them
- **Photo proof** — attach before/after photos when completing a task
- **History** — full completion log with notes and photos
- **Real-time sync** — completing a chore instantly updates all other connected devices
- **Version compatibility check** — app warns if server and app versions are incompatible
- **Multilingual** — English, Dutch (Nederlands), Spanish (Español); auto-detects device locale

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Git | any | To clone and update the repo |
| Docker Desktop | 4.x+ | Runs backend + web server |
| Flutter SDK | 3.29+ | Only needed to build the Android APK |

> **The web app is built inside Docker** — no Flutter installation needed to deploy the server.

---

## Quick Start

### 1. Clone

```bash
git clone <your-repo-url> householdchores
cd householdchores
```

### 2. Configure

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:
```
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="yourStrongPassword"
```

### 3. Start

```bash
# From the repo root (where docker-compose.yaml lives)
docker compose up -d --build
```

First run takes a few minutes — Docker downloads Flutter and compiles the web app. Subsequent starts are fast (cached layers).

- **Web app:** http://localhost:9011
- **API / Admin UI:** http://localhost:9010/_/

### 4. Add users

Open http://localhost:9010/_/ → Collections → `users` → New record. Set `name`, `email`, `password`.

Then set at least one user as admin: find your account → set `is_admin = true` → Save. After that, manage all users from within the app itself (⚙ → Manage Users).

---

## Accessing from other devices on your network

Find your server's IP (`ipconfig` on Windows, `ip addr` on Linux/macOS), then open `http://192.168.1.x:9011` from any device on the same network. The web app automatically connects to port 9010 on the same host — no configuration needed.

---

## Building & distributing the Android APK

### One-time setup

1. Accept Android licenses: `flutter doctor --android-licenses`
2. Create a signing keystore:
   ```bash
   keytool -genkey -v -keystore ~/household-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias household
   ```
3. Create `frontend/android/key.properties` (do **not** commit):
   ```
   storePassword=yourKeystorePassword
   keyPassword=yourKeyPassword
   keyAlias=household
   storeFile=C:/Users/YourName/household-key.jks
   ```
4. Wire the keystore into `frontend/android/app/build.gradle.kts` (see README for snippet).

### Build

```powershell
# From repo root — bumps version, builds APK, tags git, pushes, optional GitHub release
.\release.ps1 -Version 1.1.0
```

Output APK: `householdchores-v1.1.0.apk`

### Distribute

1. Enable "Install unknown apps" on the Android device
2. Share the APK via Google Drive, WhatsApp, or a shared network folder
3. Tap the APK on the device → Install

---

## Updating the server

```bash
git pull
docker compose up -d --build
```

That's it. Migrations apply automatically. The web app is rebuilt automatically. Your data (`backend/pb_data/`) is never touched.

---

## Configuring multiple houses

Tap **⚙** on the login screen → House Configuration. Add a PocketBase server URL, test the connection, save. Switch between houses from the login screen dropdown.

---

## Home Assistant Integration

### Option B — Webhook on completion (recommended)

Add to `backend/.env`:
```
HA_WEBHOOK_URL=http://your-ha:8123/api/webhook/your-id
```
Then `docker compose restart pocketbase`. The hook fires on every chore completion with `{ chore, completed_by, notes }`.

### Option A — REST sensor

Poll PocketBase directly from `configuration.yaml` — no setup needed.

---

## Troubleshooting

**"Cannot connect to the server"**
- Check Docker is running: `docker compose ps`
- On web: the app auto-connects to the same host on port 9010 — make sure port 9010 is accessible

**"App needs updating" / "Server needs updating"**
- MAJOR versions must match. Run `.\release.ps1` or `docker compose up -d --build` to update

**Port conflict**
- Change `9010:9010` or `9011:80` in `docker-compose.yaml`

**APK won't install**
- Ensure "Install unknown apps" is enabled
- Ensure new APK was signed with the same keystore as installed version

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.29+ (Dart) — Web, Android, iOS, Desktop |
| Backend | PocketBase (Go) — Auth, REST API, SQLite, File Storage, SSE |
| Web server | nginx:alpine — serves Flutter web build |
| Infrastructure | Docker & Docker Compose |
| State management | Provider (ChangeNotifier) |
| Localisation | flutter_localizations + intl (EN / NL / ES) |