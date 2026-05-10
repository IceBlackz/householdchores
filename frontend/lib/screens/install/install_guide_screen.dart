import 'package:flutter/material.dart';

class InstallGuideScreen extends StatelessWidget {
  const InstallGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Install app')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.blueGrey.shade700],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.install_mobile, color: Colors.white, size: 34),
                const SizedBox(height: 12),
                Text(
                  'Put Household Chores on your home screen',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The easiest option is installing the web app from your browser. Android can also use a downloaded APK when your server provides one.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _GuideCard(
            icon: Icons.language,
            title: 'Best for most users: install the website',
            body:
                'Open /install.html on this server. If the button appears, tap Install web app. If it does not, use your browser menu and choose Install app or Add to Home Screen.',
          ),
          const _GuideCard(
            icon: Icons.android,
            title: 'Android APK',
            body:
                'If an APK has been published, open /downloads/householdchores-latest.apk from your Android phone. Android may ask you to allow installs from this browser.',
          ),
          const _GuideCard(
            icon: Icons.phone_iphone,
            title: 'iPhone and iPad',
            body:
                'Use Safari, open /install.html, tap the Share button, then choose Add to Home Screen. Direct .ipa downloads are not practical for normal household distribution.',
          ),
          const _GuideCard(
            icon: Icons.https,
            title: 'HTTPS recommended',
            body:
                'Install prompts work best over HTTPS. Localhost is usually allowed for testing, but phones on your network should use HTTPS for the smoothest install experience.',
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.teal.shade700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
