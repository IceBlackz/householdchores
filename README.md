# Household Chores Manager

A smart, self-hosted household task manager that eliminates the "whose turn is it?" debate. Runs on your local network — no cloud subscriptions, no data leaving your home.

Built with Flutter (Web/Desktop/Mobile) and PocketBase, designed for small home servers like a Jetson Nano or Raspberry Pi.

## Features

- **Smart sorting** — tasks assigned to you float to the top; everything else is sorted by how overdue it is
- **Hard deadlines** — a second "max" interval shows a critical warning when a task is truly past due
- **Flexible intervals** — set recurrence in days, weeks, months, quarters, or years
- **Season-specific schedules** — e.g. clean gutters every 3 months in autumn, every 6 months otherwise
- **Assignments** — assign a default owner per chore; override for a single cycle without changing the default
- **Complete on behalf of** — mark a chore done for any household member, not just yourself
- **Multiple houses** — configure multiple PocketBase servers and switch between them at login
- **Photo proof** — attach before/after photos when completing a task
- **History** — see who completed what and when, with notes and photos
- **Real-time sync** — completing a chore on one device instantly updates all others on the same network
- **Multilingual** — English, Dutch (Nederlands), and Spanish (Español); auto-detects from device locale with a manual override

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Git | any | To clone and update the repo |
| Docker Desktop | 4.x+ | Runs the backend |
| Flutter SDK | 3.29+ | To build and run the frontend |

---

## Installation

### 1. Clone the repository

```bash
git clone <your-repo-url> householdchores
cd householdchores
```

### 2. Configure the backend

```bash
cd backend
cp .env.example .env        # then edit .env with your admin credentials
```

Open `.env` and set:
```
PB_ADMIN_EMAIL=admin@example.com
PB_ADMIN_PASSWORD=yourStrongPassword
```

Optionally, set a Home Assistant webhook URL:
```
HA_WEBHOOK_URL=http://your-ha:8123/api/webhook/your-webhook-id
```

### 3. Start the backend

```bash
docker compose up -d --build
```

- Admin UI: http://localhost:9010/_/
- API: http://localhost:9010/

> **Migrations run automatically** on startup. You never need to run them manually.

### 4. Add users

Open http://localhost:9010/_/ → Collections → `users` → New record.
Fill in `name`, `email`, and `password`. Users log in with email + password in the app.

### 5. Run the frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

The app opens in your browser and connects to `http://localhost:9010` by default.

---

## Accessing from other devices on your network

### Find your server's IP address

**Windows:** run `ipconfig`, look for the IPv4 Address (e.g. `192.168.1.42`).

**Linux / macOS:** run `ip addr` or `ifconfig`.

### Run pointing at your server

```bash
flutter run -d chrome --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

### Build a release web app

```bash
flutter build web --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

Serve `build/web` from any web server. Easiest option — add to `docker-compose.yaml`:

```yaml
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ../frontend/build/web:/usr/share/nginx/html:ro
    restart: unless-stopped
```

Then `docker compose up -d` and open http://192.168.1.42:8080 from any device.

---

## Building & distributing the Android APK

### One-time setup

1. **Accept Android licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

2. **Create a signing keystore** (skip if you already have one):
   ```bash
   keytool -genkey -v -keystore ~/household-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias household
   ```
   Remember the passwords — you'll need them every build.

3. **Create `frontend/android/key.properties`** (do **not** commit this file):
   ```
   storePassword=yourKeystorePassword
   keyPassword=yourKeyPassword
   keyAlias=household
   storeFile=C:/Users/YourName/household-key.jks
   ```

4. **Wire the keystore into the build** — edit `frontend/android/app/build.gradle.kts` and add inside the `android { ... }` block:
   ```kotlin
   val keyPropertiesFile = rootProject.file("key.properties")
   val keyProperties = java.util.Properties()
   keyProperties.load(java.io.FileInputStream(keyPropertiesFile))

   signingConfigs {
       create("release") {
           keyAlias = keyProperties["keyAlias"] as String
           keyPassword = keyProperties["keyPassword"] as String
           storeFile = file(keyProperties["storeFile"] as String)
           storePassword = keyProperties["storePassword"] as String
       }
   }
   buildTypes {
       release {
           signingConfig = signingConfigs.getByName("release")
       }
   }
   ```

### Build the APK

```bash
cd frontend
flutter build apk --release --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Distribute to household members

The simplest approach — no Play Store needed:

1. **Enable "Install unknown apps"** on each Android device:
   Settings → Apps → Special app access → Install unknown apps → enable for your browser or file manager.

2. **Share the APK** via any of:
   - Copy to a shared network folder and open from the phone's file manager
   - Upload to Google Drive / Nextcloud and open the share link on the phone
   - Send via WhatsApp or Signal (avoid email — many clients block APKs)

3. **Tap the APK** on the phone and confirm installation.

> **Tip:** Increment `version` in `frontend/pubspec.yaml` (e.g. `1.0.0+1` → `1.1.0+2`) before each build so Android offers an update prompt rather than a full reinstall.

### Update the app on a phone

Rebuild the APK and share it again. Android will show "Update" if the signing key matches and the version number is higher.

---

## Configuring multiple houses

Tap the **⚙ settings icon** on the login screen to open House Configuration. From there you can:
- Add a new PocketBase server (name + URL + optional Home Assistant webhook)
- Test the connection before saving
- Edit or delete existing houses
- Switch the active house from the login screen dropdown

Each house is a completely independent PocketBase server. Switching houses re-initialises the connection.

---

## Updating

```bash
git pull
cd backend
docker compose up -d --build    # picks up new migrations automatically
cd ../frontend
flutter pub get                  # only needed if pubspec.yaml changed
flutter build apk --release --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

---

## Home Assistant Integration

### Option A — REST sensor (read-only, no setup needed)

```yaml
sensor:
  - platform: rest
    name: Overdue Chores
    resource: "http://192.168.1.42:9010/api/collections/chore_logs/records"
    headers:
      Authorization: "Bearer <your-pb-user-token>"
    value_template: "{{ value_json.totalItems }}"
    scan_interval: 300
```

### Option B — Webhook on completion (recommended)

`backend/pb_hooks/notify_homeassistant.pb.js` fires a POST to your HA webhook whenever a chore is completed.

**Setup:**
1. In HA, create an automation: Trigger → Webhook, note the webhook ID.
2. Add to `backend/.env`:
   ```
   HA_WEBHOOK_URL=http://your-ha:8123/api/webhook/your-webhook-id
   ```
3. `docker compose restart`

Payload sent:
```json
{ "chore": "Clean Toilet", "completed_by": "Alice", "notes": "" }
```

### Option C — MQTT bridge

If you have MQTT in HA, a small bridge script can subscribe to PocketBase SSE and publish to MQTT topics. Ask an AI assistant to generate it — the SSE endpoint is `GET /api/realtime`.

---

## Troubleshooting

**"Cannot connect to the server"**
- Make sure Docker Desktop is running
- `docker compose ps` in `backend/` — `pocketbase-server` should show `Up`
- Use `localhost` for the same machine, LAN IP for other devices

**Can't log in**
- Passwords are set in the PocketBase Admin UI → Collections → users
- Admin and user accounts are separate — admin credentials only work in the Admin UI

**Port already in use**
- Change `9010:9010` to e.g. `9011:9010` in `docker-compose.yaml`, update `BACKEND_URL` to match

**Chores don't update in real-time**
- All devices must be on the same network and pointing at the same server IP
- Check browser console for SSE connection errors

**APK won't install**
- Ensure "Install unknown apps" is enabled for the app used to open the file
- If updating, ensure the new APK was signed with the same keystore as the installed version

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.29+ (Dart) — Web, Desktop, Mobile |
| Backend | PocketBase (Go) — Auth, REST API, SQLite, File Storage, SSE Realtime |
| Infrastructure | Docker & Docker Compose |
| State management | Provider (ChangeNotifier) |
| Localisation | flutter_localizations + intl (EN / NL / ES) |