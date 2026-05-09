import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/chore_provider.dart';
import 'providers/house_provider.dart';
import 'providers/locale_provider.dart';
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

  runApp(HouseholdApp(localeProvider: localeProvider));
}

class HouseholdApp extends StatelessWidget {
  const HouseholdApp({super.key, required this.localeProvider});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
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
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          title: 'Household Chores',
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              surface: const Color(0xFFFAFBF7),
            ),
            scaffoldBackgroundColor: const Color(0xFFFAFBF7),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              surfaceTintColor: Colors.transparent,
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
