import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/chore_provider.dart';
import 'providers/house_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'services/chore_service.dart';
import 'services/pocketbase_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  PocketBaseService().init(AppConfig.backendUrl);

  final localeProvider = LocaleProvider();
  await localeProvider.load();
  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    HouseholdApp(localeProvider: localeProvider, themeProvider: themeProvider),
  );
}

class HouseholdApp extends StatelessWidget {
  const HouseholdApp({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        // FIX: use create: instead of .value() so the provider is properly disposed
        ChangeNotifierProvider<HouseProvider>(create: (_) => HouseProvider()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ChoreService>(create: (_) => ChoreService()),
        Provider<SettingsService>(create: (_) => SettingsService()),
        ChangeNotifierProxyProvider<ChoreService, ChoreProvider>(
          create: (ctx) => ChoreProvider(ctx.read<ChoreService>()),
          update: (_, service, previous) => previous ?? ChoreProvider(service),
        ),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) => MaterialApp(
          title: 'Household Chores',
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.themeMode,
          home: const LoginScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: brightness,
      surface: isDark ? const Color(0xFF101816) : const Color(0xFFFAFBF7),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0B1210)
          : const Color(0xFFFAFBF7),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
