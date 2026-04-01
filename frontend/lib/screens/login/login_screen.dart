import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/house_provider.dart';
import '../../services/auth_service.dart';
import '../../services/version_service.dart';
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
  VersionCheckResult? _versionResult;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _versionResult = null; });
    final l10n = AppLocalizations.of(context)!;
    final url = context.read<HouseProvider>().activeHouseUrl;

    final versionResult = await VersionService.checkCompatibility(url);
    if (!mounted) return;

    if (versionResult.isBlocking) {
      setState(() { _isLoading = false; _versionResult = versionResult; });
      return;
    }

    if (versionResult.status == VersionStatus.endpointNotFound ||
        versionResult.status == VersionStatus.checkFailed) {
      final proceed = await _showVersionWarningDialog(versionResult);
      if (!mounted) return;
      if (!proceed) { setState(() => _isLoading = false); return; }
    }

    try {
      await context.read<AuthService>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      final name = context.read<AuthService>().currentUserName ?? 'User';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.welcomeBack(name)),
        backgroundColor: Colors.green,
      ));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: Colors.red.shade700,
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

  Future<bool> _showVersionWarningDialog(VersionCheckResult result) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text(l10n.versionWarningTitle),
        ]),
        content: Text(result.status == VersionStatus.endpointNotFound
            ? l10n.versionEndpointNotFound
            : l10n.versionCheckFailed),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.continueAnyway),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildVersionBanner(AppLocalizations l10n) {
    final result = _versionResult;
    if (result == null || !result.isBlocking) return const SizedBox.shrink();
    final isAppOld = result.status == VersionStatus.appTooOld;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAppOld ? l10n.appTooOld : l10n.serverTooOld,
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: Colors.red.shade800),
              ),
              const SizedBox(height: 2),
              Text(
                isAppOld
                    ? l10n.appTooOldDetail(
                        AppConfig.appVersion, result.serverVersion ?? '?')
                    : l10n.serverTooOldDetail(
                        result.serverVersion ?? '?', AppConfig.appVersion),
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ],
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final houseProvider = context.watch<HouseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdLogin),
        actions: [
          PopupMenuButton<String>(
            onSelected: (houseId) async {
              await context.read<HouseProvider>().switchHouse(houseId);
              setState(() => _versionResult = null);
            },
            itemBuilder: (_) => houseProvider.houses.map((house) =>
              PopupMenuItem(
                value: house.id,
                child: Row(children: [
                  Icon(Icons.home,
                    color: house.id == houseProvider.activeHouseId
                        ? Colors.teal : Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(house.name)),
                ]),
              ),
            ).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.houseConfiguration,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConfigurationScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FIX: single underscore for unused Consumer parameters
            Consumer<HouseProvider>(
              builder: (_, hp, _) => Text(
                hp.activeHouse?.name ?? l10n.householdChores,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Text(houseProvider.activeHouseUrl,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            _buildVersionBanner(l10n),
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
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text(l10n.login),
                    ),
                  ),
            const SizedBox(height: 12),
            Text('${l10n.appVersionLabel} ${AppConfig.appVersion}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}