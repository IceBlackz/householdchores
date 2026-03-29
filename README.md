# Household Chores Manager

A smart, self-hosted household task manager that eliminates the "whose turn is it?" debate. Runs on your local network — no cloud subscriptions, no data leaving your home.

Built with Flutter (Web/Desktop/Mobile) and PocketBase, designed for small home servers like a Jetson Nano or Raspberry Pi.

## Features

- **Smart sorting** — tasks assigned to you float to the top; everything else is sorted by how overdue it is
- **Flexible intervals** — set recurrence in days, weeks, months, quarters, or years
- **Season-specific schedules** — e.g. clean gutters every 3 months in autumn, every 6 months otherwise
- **Assignments** — assign a default owner per chore; override for a single cycle without changing the default
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

### 3. Start the backend

```bash
docker compose up -d --build
```

- Admin UI: http://localhost:9010/_/
- API: http://localhost:9010/

The first time you open the Admin UI you will be prompted to create an admin account (the credentials you set in `.env`).

> **Migrations run automatically** on startup. You never need to run them manually.

### 4. Add users

Open http://localhost:9010/_/ → Collections → `users` → New record.
Fill in `name`, `email`, and `password`. Users log in with email + password in the app.

### 5. Start the frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

The app opens in your browser and connects to `http://localhost:9010` by default.

---

## Accessing from other devices on your network

Other phones, tablets, or computers on the same Wi-Fi can use the app — they just need to point at your server's IP address instead of `localhost`.

### Find your server's IP address

**Windows:**
```
ipconfig
```
Look for the IPv4 Address of your active adapter (e.g. `192.168.1.42`).

**Linux / macOS:**
```bash
ip addr   # or: ifconfig
```

### Run the Flutter app pointing at your server

```bash
cd frontend
flutter run -d chrome --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

### Build a release web app (serve to the whole household)

```bash
cd frontend
flutter build web --dart-define=BACKEND_URL=http://192.168.1.42:9010
```

Then serve the `build/web` folder with any web server. The simplest option — add to `docker-compose.yaml`:

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

## Updating

```bash
git pull
cd backend
docker compose up -d --build    # picks up new migrations automatically
cd ../frontend
flutter pub get                  # only needed if pubspec.yaml changed
flutter run -d chrome            # or rebuild web
```

---

## Home Assistant Integration

Three options, from simplest to most powerful.

### Option A — REST sensor (read-only, no setup needed)

Poll the PocketBase API from `configuration.yaml` to show chore counts on your HA dashboard:

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

The backend includes `pb_hooks/notify_homeassistant.pb.js`. When a chore is completed it fires a POST to a Home Assistant webhook.

**Setup:**
1. In HA, create an automation: Trigger → Webhook, note the webhook ID.
2. Add to `backend/.env`:
   ```
   HA_WEBHOOK_URL=http://your-ha:8123/api/webhook/your-webhook-id
   ```
3. Restart the backend: `docker compose restart`

The hook sends:
```json
{ "chore": "Clean Toilet", "completed_by": "Alice", "notes": "" }
```

Use the `completed_by` field in your HA automation to send a personalised notification.

### Option C — MQTT bridge (most powerful)

If you already have MQTT in your HA setup, a small bridge script can subscribe to PocketBase SSE and publish to MQTT topics. HA's MQTT integration then creates full sensor entities. Ask an AI assistant to generate this script — the SSE endpoint is `GET /api/realtime`.

---

## Troubleshooting

**Can't connect / "Cannot connect to the server"**
- Make sure Docker Desktop is running
- Run `docker compose ps` in the `backend` folder — `pocketbase-server` should show `Up`
- Check the URL: localhost for same machine, LAN IP for other devices

**Wrong password / can't log in**
- Passwords are set in the PocketBase Admin UI (http://localhost:9010/_/ → Collections → users)
- Admin and user accounts are separate — admin credentials only work in the Admin UI

**Docker won't start / port already in use**
- Change the port in `docker-compose.yaml` from `9010:9010` to e.g. `9011:9010`, then update `BACKEND_URL` accordingly

**Chores don't update in real-time on other devices**
- All devices must be on the same network and pointing at the same server IP
- Check browser console for SSE connection errors

**Migrations not applying**
- Check container logs: `docker compose logs pocketbase`
- Make sure `./pb_migrations` is mounted (check `docker-compose.yaml` volumes)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.29+ (Dart) — Web, Desktop, Mobile |
| Backend | PocketBase (Go) — Auth, REST API, SQLite, File Storage, SSE Realtime |
| Infrastructure | Docker & Docker Compose |
| State management | Provider (ChangeNotifier) |
| Localisation | flutter_localizations + intl (EN / NL / ES) |
