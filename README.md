# Household Chores Manager

A self-hosted app for organizing household tasks, reminders, assignments, and chore history. It is designed for normal home use: run the server on a home computer, mini PC, Raspberry Pi, Jetson, or NAS, then use the web app or mobile app from your household devices.

The app keeps your data on your own server. There are no subscriptions and no required cloud service.

## What You Can Do

- Create recurring chores such as vacuuming, cleaning filters, taking bins out, or garden work.
- Assign chores to household members.
- Temporarily assign a chore to someone else for one round.
- See what is due today, overdue, or past a hard deadline.
- Complete chores for yourself or on behalf of another household member.
- Add notes and before/after photos when completing a chore.
- View completion history per chore.
- Manage users from inside the app once an admin user exists.
- Switch between multiple houses or PocketBase servers.
- Use the app in English, Dutch, or Spanish.
- Configure mobile reminders from the app settings.
- Use Android/iOS local notifications without Home Assistant.
- Optionally send due chore digests to Home Assistant.

## How It Works

The project has two services:

| Service | What it does | Default URL |
| --- | --- | --- |
| PocketBase backend | Stores users, chores, settings, history, and photos | http://localhost:9010 |
| Flutter web app | The web interface you use in your browser | http://localhost:9011 |

When you open the web app on another device, it automatically connects to the backend on the same machine at port `9010`. For example, if the web app is `http://192.168.1.20:9011`, it talks to `http://192.168.1.20:9010`.

## Before You Start

You need:

- Docker Desktop, or Docker Engine with Docker Compose.
- Git, if you want to clone the repository.
- Flutter only if you want to build Android/iOS apps yourself. Docker builds the web app for you.

For the easiest first setup, use Docker Desktop and the web app.

## Quick Start

### 1. Get the Project

```powershell
git clone https://github.com/IceBlackz/householdchores householdchores
cd householdchores
```

If you downloaded a ZIP instead, extract it and open a terminal in the extracted `householdchores` folder.

### 2. Create the Backend Admin File

Copy the example environment file:

```powershell
Copy-Item backend/.env.example backend/.env
```

Open `backend/.env` in a text editor and set these values:

```env
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="choose-a-strong-password"
```

Important password tips:

- Keep the quotes around the password.
- If your password contains `$`, write it as `$$` in this file.
- This account is the PocketBase server admin. You will still create normal app users in the next steps.

### 3. Start the App

Run this from the project root, the folder that contains `docker-compose.yaml`:

```powershell
docker compose up -d --build
```

The first build can take a few minutes because Docker downloads Flutter and PocketBase and builds the web app.

When it finishes, open:

- Web app: http://localhost:9011
- PocketBase admin panel: http://localhost:9010/_/

### 4. Create Your First App User

1. Open http://localhost:9010/_/.
2. Log in with the `ADMIN_EMAIL` and `ADMIN_PASSWORD` from `backend/.env`.
3. Go to **Collections**.
4. Open the `users` collection.
5. Create a new user with an email, password, and name.
6. Set `is_admin` to `true` for your own first user.
7. Save the user.

Now open http://localhost:9011 and log in with the app user you just created.

After this, admin users can manage household users directly inside the app.

## Everyday Use

### Add Household Members

In the dashboard, admin users can open **Manage users** from the toolbar.

Use this to:

- Add new household members.
- Change display names.
- Reset or set passwords.
- Give someone admin access.
- Remove users that are no longer needed.

Tip: keep at least one admin user.

### Add Chores

Use the **+** button on the dashboard.

For each chore you can set:

- Title and description.
- Desired interval, such as every 7 days.
- Hard deadline, such as maximum 14 days.
- Interval unit: days, weeks, months, quarters, or years.
- Season behavior, for chores that only matter in certain seasons.
- Default assignee.
- One-time assignee, for the next completion only.

### Complete Chores

Tap a chore to complete it.

You can:

- Choose who completed it.
- Add notes.
- Add before and after photos.
- Clear a one-time assignment automatically.

Other connected devices update automatically after a chore is completed.

### Understand the Dashboard

The dashboard highlights:

- **Assigned to me**: chores currently assigned to the logged-in user.
- **Needs attention**: chores due today, overdue, or never completed.
- **Critical**: chores past their hard deadline.
- **Total chores**: all chores in the current filter.

Useful filters:

- **All**: every chore.
- **Mine**: chores assigned to you.
- **Attention**: chores that should be done soon or are already late.
- **Critical**: chores past the hard deadline.

## App Settings and Notifications

Admin users can open **App settings** from the dashboard toolbar.

### Mobile Reminders

Mobile reminders are local Android/iOS notifications. They do not require Home Assistant.

You can configure:

- Whether mobile reminders are enabled.
- Whether each person only receives chores assigned to them.
- Daily reminder time.
- Whether the notification shows a **Complete** action.
- Which chores trigger reminders: due today, overdue, never completed, or critical.
- Quiet hours.
- Escalation days, which can turn overdue chores into critical reminders after a chosen number of days.

Important notes:

- Local notifications are scheduled by the mobile app.
- The app refreshes notification schedules when it syncs chores.
- The **Complete** action opens the app and completes the chore for the signed-in user.
- The web browser version does not show mobile OS notifications.

### Server Push Notifications

There is a setting for server push notifications, but the delivery backend is not implemented yet.

True server push while the app is fully closed needs:

- Firebase Cloud Messaging for Android.
- Apple Push Notification service for iOS.
- Device token registration in PocketBase.
- A backend job that sends push messages.

The current app is prepared for this, but today the working direct-app notification system is local mobile notifications.

### Home Assistant Due Digest

If you use Home Assistant, the backend can send a digest of due chores to a Home Assistant webhook.

You can enable this in **App settings** and enter the webhook URL there. You can also use environment variables, described below.

## Optional Home Assistant Setup

Home Assistant is optional. The app works without it.

### Completion Webhook

To notify Home Assistant whenever a chore is completed, add this to `backend/.env`:

```env
HA_WEBHOOK_URL=http://your-home-assistant:8123/api/webhook/your-webhook-id
```

Restart PocketBase:

```powershell
docker compose restart pocketbase
```

The webhook receives chore details, who completed it, and notes.

### Due Reminder Digest

To let the backend send due chore reminders to Home Assistant, configure this in **App settings** or add a fallback webhook URL:

```env
HA_DUE_WEBHOOK_URL=http://your-home-assistant:8123/api/webhook/your-due-reminder-id
HA_DUE_REMINDER_CRON=0 8 * * *
```

The cron format is:

```text
minute hour day month weekday
```

`0 8 * * *` means every day at 08:00.

For manual triggers and signed completion links, also set:

```env
HA_ACTION_SECRET=use-a-long-random-secret
PUBLIC_BACKEND_URL=http://your-server:9010
```

Then restart PocketBase:

```powershell
docker compose restart pocketbase
```

Manual test:

```powershell
curl -X POST "http://localhost:9010/api/householdchores/reminders/send?token=use-a-long-random-secret"
```

## Use From Other Devices

Find your server IP address.

On Windows:

```powershell
ipconfig
```

On Linux or macOS:

```bash
ip addr
```

Then open the web app from another device on the same network:

```text
http://YOUR-SERVER-IP:9011
```

Example:

```text
http://192.168.1.20:9011
```

Make sure both ports are reachable:

- `9011` for the web app.
- `9010` for the backend API.

## Android App

The web app is easiest, but Android gives you direct app notifications.

### Build an APK

You need Flutter installed locally for this part.

From the `frontend` folder:

```powershell
flutter pub get
flutter build apk --release
```

The APK will be created under:

```text
frontend/build/app/outputs/flutter-apk/
```

For a signed release, use the project release script from the repo root:

```powershell
.\release.ps1 -Version 1.1.0
```

### Install on Android

1. Copy the APK to your phone.
2. Enable **Install unknown apps** for the app you use to open the APK.
3. Tap the APK and install it.
4. Open the app and configure the backend URL if needed.

## iOS App

The Flutter app can target iOS, but building iOS requires macOS and Xcode.

General steps:

```bash
cd frontend
flutter pub get
flutter build ios --release
```

You will also need Apple signing configured in Xcode.

## Updating

From the project root:

```powershell
git pull
docker compose up -d --build
```

Your data is stored in `backend/pb_data/` and is not deleted by rebuilding containers.

## Backup

The most important folder is:

```text
backend/pb_data/
```

Back up this folder to preserve:

- Database records.
- Uploaded photos.
- PocketBase application data.

Stop the containers before making a manual copy if you want the safest backup:

```powershell
docker compose down
```

Start again after copying:

```powershell
docker compose up -d
```

## Troubleshooting

### The web app says it cannot connect to the server

Check the containers:

```powershell
docker compose ps
```

Check that the backend responds:

```powershell
curl http://localhost:9010/api/health
```

If you are using another device, make sure it can reach your server IP on port `9010`.

### I cannot log in

Make sure you created an app user in the `users` collection. The PocketBase superuser from `backend/.env` is for the admin panel, not for normal app login.

### I do not see admin buttons

Open the PocketBase admin panel, go to `users`, and confirm your user has `is_admin = true`.

### Mobile notifications do not appear

Check:

- You are using the Android or iOS app, not only the web browser.
- Mobile reminders are enabled in **App settings**.
- The phone granted notification permission.
- The app has synced chores after the settings changed.
- The chore is due, overdue, never completed, or critical according to your settings.

### Home Assistant due reminders do not arrive

Check:

- The Home Assistant webhook URL is correct.
- Due digest is enabled in **App settings**, or `HA_DUE_WEBHOOK_URL` is set.
- `HA_ACTION_SECRET` is set if you use manual trigger or action links.
- PocketBase was restarted after editing `backend/.env`.
- There are chores that are actually due.

### A port is already in use

Edit `docker-compose.yaml` and change the left side of the port mapping.

Example:

```yaml
ports:
  - "9021:80"
```

This changes the host port to `9021`.

## Useful Commands

From the project root:

```powershell
docker compose up -d --build
docker compose ps
docker compose logs -f pocketbase
docker compose restart pocketbase
docker compose down
```

From `frontend/`:

```powershell
flutter pub get
flutter analyze
flutter test
flutter gen-l10n
```

## Project Layout

```text
householdchores/
  docker-compose.yaml
  Dockerfile
  backend/
    .env.example
    nginx.conf
    entrypoint.sh
    pb_data/
    pb_hooks/
    pb_migrations/
  frontend/
    lib/
      models/
      providers/
      screens/
      services/
      l10n/
```
