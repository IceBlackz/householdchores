# Household Chores Frontend

This is the Flutter app for Household Chores Manager. It builds for web, Android, iOS, and desktop, although the Docker deployment builds the web version automatically.

Most users do not need to run commands in this folder. Use the root `README.md` first.

## Common Developer Commands

Run these from the `frontend` folder:

```powershell
flutter pub get
flutter analyze
flutter test
flutter gen-l10n
```

Run the app locally in Chrome:

```powershell
flutter run -d chrome
```

The web app connects to `http://localhost:9010` by default when running locally.

## Mobile Notifications

Android and iOS use `flutter_local_notifications` for local scheduled reminders.

Important behavior:

- Web builds skip local notification scheduling.
- Android needs notification permission on recent Android versions.
- iOS asks for alert, badge, and sound permission.
- Notification schedules are refreshed when chores sync.
- Supported notifications can show a **Complete** action that opens the app and completes the chore.

## Localization

The app uses Flutter generated localizations.

Source files:

```text
lib/l10n/app_en.arb
lib/l10n/app_nl.arb
lib/l10n/app_es.arb
```

After editing ARB files, run:

```powershell
flutter gen-l10n
```

## Build Web

```powershell
flutter build web --release
```

Docker does this automatically from the project root:

```powershell
docker compose up -d --build
```

## Build Android APK

```powershell
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/
```
