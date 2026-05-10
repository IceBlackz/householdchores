# Household Chores Manager

A self-hosted app for organizing household tasks, reminders, assignments, proof photos, and chore history. Run the server on a home computer, mini PC, Raspberry Pi, Jetson, or NAS, then use the web app or mobile app from household devices.

Your data stays on your own server. There are no subscriptions and no required cloud service.

## Index

- [Features](#features)
- [How It Works](#how-it-works)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [First App User](#first-app-user)
- [Everyday Use](#everyday-use)
- [Rooms and Focus Zones](#rooms-and-focus-zones)
- [Settings and Configuration](#settings-and-configuration)
- [Notifications and Home Assistant](#notifications-and-home-assistant)
- [Install From the Website](#install-from-the-website)
- [HTTPS Setup](#https-setup)
- [Android App](#android-app)
- [iOS App](#ios-app)
- [Updating and Backup](#updating-and-backup)
- [Automated Checks](#automated-checks)
- [Troubleshooting](#troubleshooting)
- [Useful Commands](#useful-commands)
- [Project Layout](#project-layout)
- [Roadmap Ideas](#roadmap-ideas)

## Features

- Create recurring chores such as vacuuming, cleaning filters, taking bins out, or garden work.
- Start new chores from common templates, then adjust the details.
- Organize chores by room or focus zone.
- Create a chore directly inside a room.
- Assign a chore to multiple rooms as independent copies.
- Duplicate a room with its tasks, useful for rooms like multiple toilets or bedrooms.
- Add suggested default chores for a room, such as floors, windows, dusting, bins, kitchen counters, or toilet cleaning.
- Assign chores to household members.
- Temporarily assign a chore to someone else for one round.
- See what is assigned to you, due today, overdue, or past a hard deadline.
- Set desired intervals and hard deadlines in days, weeks, months, quarters, or years.
- Add seasonal behavior and season-specific interval overrides.
- Complete chores for yourself or on behalf of another household member.
- Add notes and before/after photos when completing a chore.
- Use optional quick-complete buttons for fast check-ins.
- Configure dashboard preferences, including default focus filter and completion feedback.
- View completion history per chore.
- Manage users from inside the app once an admin user exists.
- Switch between multiple houses or PocketBase servers.
- Use the app in English, Dutch, or Spanish.
- Configure mobile reminders from app settings.
- Use Android/iOS local notifications without Home Assistant.
- Optionally send due chore digests and completion events to Home Assistant.

## How It Works

The project has two services:

| Service | What it does | Default URL |
| --- | --- | --- |
| PocketBase backend | Stores users, chores, settings, history, and photos | http://localhost:9010 |
| Flutter web app | The web interface you use in your browser | http://localhost:9011 |

When you open the web app on another device, it automatically connects to the backend on the same machine at port `9010`. For example, if the web app is `http://192.168.1.20:9011`, it talks to `http://192.168.1.20:9010`.

If you use an HTTPS proxy, override the backend URL in `frontend/web/config.js` before rebuilding the web container.

## Requirements

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

Password notes:

- Keep the quotes around the password.
- If your password contains `$`, write it as `$$` in this file.
- This is the PocketBase server admin. You will still create normal app users separately.

### 3. Start the App

Run this from the project root, the folder that contains `docker-compose.yaml`:

```powershell
docker compose up -d --build
```

The first build can take a few minutes because Docker downloads Flutter and PocketBase and builds the web app.

When it finishes, open:

- Web app: http://localhost:9011
- PocketBase admin panel: http://localhost:9010/_/

## First App User

1. Open http://localhost:9010/_/.
2. Log in with the `ADMIN_EMAIL` and `ADMIN_PASSWORD` from `backend/.env`.
3. Go to **Collections**.
4. Open the `users` collection.
5. Create a new user with an email, password, and name.
6. Set `is_admin` to `true` for your own first user.
7. Save the user.

Now open http://localhost:9011 and log in with that app user. After this, admin users can manage household users directly inside the app.

## Everyday Use

### Dashboard

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

Use the house icon to switch houses. Use the menu icon for users, app settings, dashboard preferences, house configuration, language selection, help, install instructions, and logout.

### Add Household Members

In the dashboard menu, admin users can open **Manage users**.

Use this to:

- Add new household members.
- Change display names.
- Reset or set passwords.
- Give someone admin access.
- Remove users that are no longer needed.

Keep at least one admin user.

### Add Chores

Use the **+** button on the dashboard.

For each chore you can set:

- Title and description.
- A template to pre-fill common chore details.
- Desired interval, such as every 7 days.
- Hard deadline, such as maximum 14 days.
- Interval unit: days, weeks, months, quarters, or years.
- Season behavior, for chores that only matter in certain seasons.
- Season-specific interval overrides.
- Room assignment. Selecting multiple rooms creates separate chore copies.
- Default assignee.
- One-time assignee, for the next completion only.

### Complete Chores

Tap a chore to open the completion screen.

You can:

- Choose who completed it.
- Add notes.
- Add before and after photos.
- Clear a one-time assignment automatically.

If quick-complete is enabled in **Dashboard preferences**, use the check button on a chore to complete it immediately as the signed-in user.

Other connected devices update automatically after a chore is completed.

## Rooms and Focus Zones

Rooms help keep the dashboard from turning into one giant wall of chores. Use **Rooms and focus zones** from the dashboard menu.

You can:

- Add rooms such as Kitchen, Bathroom, Downstairs toilet, Bedroom, Garden, or Hallway.
- Add a chore directly inside a room.
- Use suggested chores for common room needs.
- Duplicate a room and all of its chores.
- Filter the dashboard to one room at a time.
- Delete a room without deleting its chores. Existing chores are kept, but become unassigned from that room.

When creating or editing a chore, you can select one or more rooms. If multiple rooms are selected, the app creates independent chore copies. Completing the floor in the kitchen will not complete the floor in the bathroom.

Room suggestions are meant to reduce setup friction. For example:

- Most rooms can suggest floors, windows, dusting, bins, and a general tidy/reset.
- Kitchen-like rooms also suggest counters/stovetop and fridge checks.
- Bathroom or toilet-like rooms also suggest toilet cleaning and sink/mirror cleaning.
- Bedroom-like rooms also suggest changing bedding.

Duplicating a room copies the room setup and creates new chore records for the new room. Completion history is not copied, so the duplicated room starts fresh.

## Settings and Configuration

### Dashboard Preferences

All users can open **Dashboard preferences** from the dashboard menu.

You can configure:

- Whether quick-complete buttons are shown.
- Whether completion micro-celebrations are enabled.
- Which dashboard filter opens by default.

These preferences are stored locally on the device.

### App Settings

Admin users can open **App settings** from the dashboard menu.

Use this for household-level settings such as:

- Mobile reminders.
- Reminder triggers.
- Quiet hours and escalation.
- Home Assistant due digest settings.
- Placeholder server push settings.

### House Configuration

Open **House Configuration** from the dashboard menu to manage server connections.

You can:

- Add a house or backend server.
- Edit a house name or server URL.
- Store an optional per-house Home Assistant webhook.
- Test the server connection.
- Switch houses from the dashboard house icon.

## Notifications and Home Assistant

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

### Home Assistant Completion Webhook

To notify Home Assistant whenever a chore is completed, add this to `backend/.env`:

```env
HA_WEBHOOK_URL=http://your-home-assistant:8123/api/webhook/your-webhook-id
```

Restart PocketBase:

```powershell
docker compose restart pocketbase
```

The webhook receives chore details, who completed it, and notes.

### Home Assistant Due Digest

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

## Install From the Website

The server includes a friendly install page:

```text
http://YOUR-SERVER-IP:9011/install.html
```

Open that page on the device you want to install.

On Android:

- Tap **Install web app** if the button appears.
- Or open the browser menu and choose **Install app** or **Add to Home screen**.
- If an APK was published to the server, use **Download Android APK** on the install page.

On iPhone or iPad:

- Open the install page in Safari.
- Tap the Share button.
- Choose **Add to Home Screen**.

On desktop:

- Chrome, Edge, and some other browsers may show an install icon in the address bar.
- You can also use the browser menu and choose **Install Household Chores** when available.

### Use From Other Devices

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

Make sure both ports are reachable:

- `9011` for the web app.
- `9010` for the backend API.

## HTTPS Setup

Install prompts and modern web-app features work best over HTTPS. Browsers usually allow `localhost` for testing, but phones and tablets on your home network should use HTTPS for the smoothest install experience.

If you open the web app through HTTPS, the backend API should also be HTTPS. Otherwise the browser can block the app because an HTTPS page is trying to call an HTTP API.

### Simple HTTPS Test With npm

This option is useful for testing the install flow. For regular household use, a trusted certificate through Caddy, Nginx Proxy Manager, Tailscale, Apache, or another reverse proxy will be nicer.

1. Install Node.js.

2. Start the normal app first:

```powershell
docker compose up -d --build
```

3. Edit `frontend/web/config.js` and set the backend URL to the HTTPS API proxy:

```javascript
window.HOUSEHOLDCHORES_CONFIG = {
  backendUrl: "https://YOUR-SERVER-IP:9444",
};
```

4. Rebuild the web container:

```powershell
docker compose up -d --build web
```

5. Start both HTTPS proxies:

```powershell
npx local-ssl-proxy --config https-proxy.example.json
```

This proxies:

- `https://YOUR-SERVER-IP:9443` to the web app on `http://YOUR-SERVER-IP:9011`.
- `https://YOUR-SERVER-IP:9444` to the backend API on `http://YOUR-SERVER-IP:9010`.

6. Open the HTTPS install page:

```text
https://YOUR-SERVER-IP:9443/install.html
```

Your browser or phone may warn about the temporary certificate. For a truly smooth household install, use a trusted certificate instead of a temporary self-signed one.

### HTTPS With Apache

Apache can serve one clean HTTPS address for both the web app and the PocketBase API.

Example final address:

```text
https://chores.example.com/install.html
```

In this setup:

- Apache sends normal website traffic to the web container on `http://127.0.0.1:9011`.
- Apache sends `/api/` and `/_/` traffic to PocketBase on `http://127.0.0.1:9010`.
- The app can use `https://chores.example.com` as its backend URL because PocketBase is available under the same HTTPS host.

Enable Apache modules:

```bash
sudo a2enmod ssl proxy proxy_http headers rewrite
sudo systemctl restart apache2
```

Get a trusted certificate. The most common option is Let's Encrypt:

```bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d chores.example.com
```

Edit `frontend/web/config.js` before rebuilding the web container:

```javascript
window.HOUSEHOLDCHORES_CONFIG = {
  backendUrl: "https://chores.example.com",
};
```

Rebuild the web container:

```powershell
docker compose up -d --build web
```

Use an Apache virtual host like this:

```apache
<VirtualHost *:80>
    ServerName chores.example.com
    Redirect permanent / https://chores.example.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName chores.example.com

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/chores.example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/chores.example.com/privkey.pem

    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"

    ProxyPass /api/ http://127.0.0.1:9010/api/
    ProxyPassReverse /api/ http://127.0.0.1:9010/api/

    ProxyPass /_/ http://127.0.0.1:9010/_/
    ProxyPassReverse /_/ http://127.0.0.1:9010/_/

    ProxyPass / http://127.0.0.1:9011/
    ProxyPassReverse / http://127.0.0.1:9011/
</VirtualHost>
```

Reload Apache:

```bash
sudo apachectl configtest
sudo systemctl reload apache2
```

Open:

```text
https://chores.example.com/install.html
```

The order of the `ProxyPass` rules matters. Keep `/api/` and `/_/` above `/`.

### What Setup Information Carries Over?

For the installed web app, also called the PWA, setup is almost automatic:

- It opens the same website it was installed from.
- It uses the same `frontend/web/config.js` backend URL.
- If Apache serves both web and API from one HTTPS hostname, the app can simply use `https://chores.example.com`.
- The user should still log in normally. Do not put usernames or passwords in install links.

For the downloaded Android APK, setup is not automatic yet:

- Android does not reliably tell a sideloaded APK which website it was downloaded from.
- The native app currently uses its built-in default backend URL or whatever the user configures in House Configuration.
- A future improvement would be a QR code or deep link such as `householdchores://configure?server=https://chores.example.com` that opens the app and pre-fills the server URL.

PWA install is already easy to connect, but APK auto-configuration needs a small deep-link onboarding feature.

## Android App

The web app is easiest, but Android gives you direct app notifications and APK installs.

The install page links to:

```text
http://YOUR-SERVER-IP:9011/downloads/householdchores-latest.apk
```

That file exists after a release build copies an APK into `frontend/web/downloads/householdchores-latest.apk` and the web container is rebuilt.

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

The release script also copies the APK to:

```text
frontend/web/downloads/householdchores-latest.apk
```

After that, rebuild the web container:

```powershell
docker compose up -d --build web
```

Users can then download it from the install page without installing Flutter.

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

## Updating and Backup

### Updating

From the project root:

```powershell
git pull
docker compose up -d --build
```

Your data is stored in `backend/pb_data/` and is not deleted by rebuilding containers.

### Backup

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

## Automated Checks

Run these from `frontend/`:

```powershell
flutter pub get
flutter analyze
flutter test
```

The test suite currently covers:

- Chore model parsing and assignee behavior.
- Chore scheduling interval behavior.
- Dashboard preference persistence.

For a quick regression pass before a change is merged, run:

```powershell
flutter test
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

### The browser still shows an old interface after updating

The web build includes deployment metadata and an update helper that clears stale app-shell caches automatically. If one browser is already stuck on an older service worker, open:

```text
http://YOUR-SERVER-IP:9011/cache-reset.html
```

For local testing, use:

```text
http://localhost:9011/cache-reset.html
```

This unregisters the old service worker, clears web caches for the app, and redirects back to the newest build.

### I cannot log in

Make sure you created an app user in the `users` collection. The PocketBase superuser from `backend/.env` is for the admin panel, not for normal app login.

### I do not see admin options

Open the PocketBase admin panel, go to `users`, and confirm your user has `is_admin = true`.

Admin options are in the dashboard menu. The house icon is only for switching houses.

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
    test/
```

## Roadmap Ideas

Some suggestions are intentionally not implemented yet because they need a product choice or heavier platform work:

- **Leaderboard or personal habit tracking**: useful motivation, but the app should choose a tone first. Competitive scoring can be fun for roommates and annoying for families.
- **Adaptive cleanliness decay**: powerful, but needs richer completion history, occupancy/context inputs, and careful rules so it does not feel unpredictable.
- **Expense tracking**: useful for cleaning supplies and shared houses, but it introduces finance records, settlement logic, and permissions.
- **Offline mode**: valuable for weak Wi-Fi areas, but PocketBase write conflict handling and local cache reconciliation need careful design.
- **Voice entry and GPS-aware reminders**: useful, but they require platform integrations and privacy decisions.
- **APK auto-configuration**: likely worth doing with a QR code or deep link so a downloaded APK can pre-fill the server URL.
