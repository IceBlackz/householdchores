import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Appearance',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: Text(
                'Uses your phone or device theme by default. Switching here saves an override on this device.',
                style: textTheme.bodySmall,
              ),
            ),
            SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode(context)
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Dark mode'),
              subtitle: Text(
                themeProvider.followsSystem
                    ? 'Following device settings'
                    : 'Using a saved override',
              ),
              value: themeProvider.isDarkMode(context),
              onChanged: themeProvider.setDarkMode,
            ),
            if (!themeProvider.followsSystem)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: themeProvider.useSystemTheme,
                  icon: const Icon(Icons.phone_iphone_outlined),
                  label: const Text('Use device setting'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
