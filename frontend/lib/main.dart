import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/chore_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/login/login_screen.dart';
import 'services/auth_service.dart';
import 'services/chore_service.dart';
import 'services/pocketbase_service.dart';

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
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ChoreService>(create: (_) => ChoreService()),
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
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
