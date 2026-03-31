import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/house_provider.dart';
import '../../services/auth_service.dart';
import '../configuration/configuration_screen.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<AuthService>().login(
            _emailController.text,
            _passwordController.text,
          );
      if (mounted) {
        final name = context.read<AuthService>().currentUserName ?? 'User';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.welcomeBack(name)),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final houseProvider = context.watch<HouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdLogin),
        actions: [
          // House switcher
          PopupMenuButton<String>(
            onSelected: (houseId) async {
              await context.read<HouseProvider>().switchHouse(houseId);
            },
            itemBuilder: (context) => houseProvider.houses
                .map((house) => PopupMenuItem(
                      value: house.id,
                      child: Row(
                        children: [
                          Icon(Icons.home,
                              color: house.id == houseProvider.activeHouseId
                                  ? Colors.teal
                                  : Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(house.name)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          // Configuration screen button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.houseConfiguration,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ConfigurationScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<HouseProvider>(
              builder: (context, hp, _) => Text(
                hp.activeHouse?.name ?? l10n.householdChores,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              houseProvider.activeHouseUrl,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: l10n.password),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text(l10n.login),
                  ),
          ],
        ),
      ),
    );
  }
}