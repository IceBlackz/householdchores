class AppConfig {
  // Override at build time: flutter run --dart-define=BACKEND_URL=http://192.168.1.50:9010
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:9010',
  );
}
