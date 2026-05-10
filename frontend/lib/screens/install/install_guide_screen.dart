import 'package:flutter/material.dart';
import '../../services/web_navigation.dart';

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
                  'Install the web app from your browser, download the Android APK if your server provides one, or open the dedicated install page.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: canOpenWebLinks
                          ? () => openWebPath('/install.html')
                          : null,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open install page'),
                    ),
                    OutlinedButton.icon(
                      onPressed: canOpenWebLinks
                          ? () => openWebPath(
                              '/downloads/householdchores-latest.apk',
                            )
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      icon: const Icon(Icons.android),
                      label: const Text('Download APK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.install_mobile,
            title: 'Install from this browser',
            body:
                'Open the install page for a real install button when your browser supports it. On iOS, it also shows the Safari Add to Home Screen steps.',
            buttonLabel: 'Open install page',
            url: absoluteWebUrl('/install.html'),
            onPressed: canOpenWebLinks
                ? () => openWebPath('/install.html')
                : null,
          ),
          _ActionCard(
            icon: Icons.android,
            title: 'Download Android APK',
            body:
                'If an APK has been published to this server, this downloads it directly. If it returns 404, use the web-app install instead.',
            buttonLabel: 'Download APK',
            url: absoluteWebUrl('/downloads/householdchores-latest.apk'),
            onPressed: canOpenWebLinks
                ? () => openWebPath('/downloads/householdchores-latest.apk')
                : null,
          ),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.url,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final String url;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.open_in_new),
              label: Text(buttonLabel),
            ),
          ],
        ),
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
