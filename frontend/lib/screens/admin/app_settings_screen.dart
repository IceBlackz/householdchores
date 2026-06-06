import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_settings.dart';
import '../../services/settings_service.dart';
import '../../widgets/appearance_settings_section.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _haWebhookController = TextEditingController();
  NotificationSettings _settings = const NotificationSettings();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _haWebhookController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final settings = await context
          .read<SettingsService>()
          .fetchNotificationSettings();
      if (mounted) {
        _haWebhookController.text = settings.homeAssistantWebhookUrl;
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<SettingsService>().saveNotificationSettings(_settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickReminderTime() async {
    final initial = _timeOfDay(_settings.reminderTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      _settings = _settings.copyWith(reminderTime: _formatTime(picked));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App settings'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppearanceSettingsSection(),
                _SettingsSection(
                  title: 'Mobile reminders',
                  subtitle:
                      'Schedules local Android/iOS notifications whenever the app syncs chores.',
                  children: [
                    SwitchListTile(
                      title: const Text('Enable mobile notifications'),
                      subtitle: const Text(
                        'Works without Home Assistant. The app must sync periodically to keep schedules fresh.',
                      ),
                      value: _settings.mobileNotificationsEnabled,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          mobileNotificationsEnabled: value,
                        );
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Only notify assigned person'),
                      value: _settings.notifyOnlyMine,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(notifyOnlyMine: value);
                      }),
                    ),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Daily reminder time'),
                      subtitle: Text(_settings.reminderTime),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickReminderTime,
                    ),
                    SwitchListTile(
                      title: const Text('Show Complete action'),
                      subtitle: const Text(
                        'When supported, the notification can complete the chore after opening the app.',
                      ),
                      value: _settings.actionButtonsEnabled,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          actionButtonsEnabled: value,
                        );
                      }),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'What should trigger reminders',
                  children: [
                    CheckboxListTile(
                      title: const Text('Due today'),
                      value: _settings.includeDueToday,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          includeDueToday: value ?? true,
                        );
                      }),
                    ),
                    CheckboxListTile(
                      title: const Text('Overdue or never completed'),
                      value: _settings.includeOverdue,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          includeOverdue: value ?? true,
                        );
                      }),
                    ),
                    CheckboxListTile(
                      title: const Text('Past hard deadline'),
                      value: _settings.includeCritical,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          includeCritical: value ?? true,
                        );
                      }),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Escalation and quiet hours',
                  children: [
                    SwitchListTile(
                      title: const Text('Quiet hours'),
                      subtitle: Text(
                        '${_settings.quietHoursStart} - ${_settings.quietHoursEnd}',
                      ),
                      value: _settings.quietHoursEnabled,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          quietHoursEnabled: value,
                        );
                      }),
                    ),
                    StepperControl(
                      label: 'Escalate after overdue days',
                      value: _settings.escalationDays,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(escalationDays: value);
                      }),
                    ),
                  ],
                ),
                _SettingsSection(
                  title: 'Home Assistant and server push',
                  subtitle:
                      'Home Assistant is available now. True server push for closed apps will need FCM/APNs credentials and device registration.',
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Home Assistant due digest'),
                      value: _settings.homeAssistantDueRemindersEnabled,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          homeAssistantDueRemindersEnabled: value,
                        );
                      }),
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Home Assistant due webhook URL',
                        prefixIcon: Icon(Icons.cloud_outlined),
                      ),
                      controller: _haWebhookController,
                      onChanged: (value) {
                        _settings = _settings.copyWith(
                          homeAssistantWebhookUrl: value.trim(),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Server push notifications'),
                      subtitle: const Text(
                        'Planned channel for FCM/APNs. Settings are stored now, delivery backend comes next.',
                      ),
                      value: _settings.serverPushEnabled,
                      onChanged: (value) => setState(() {
                        _settings = _settings.copyWith(
                          serverPushEnabled: value,
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  TimeOfDay _timeOfDay(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }
}

class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final control = SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('0')),
        ButtonSegment(value: 1, label: Text('1')),
        ButtonSegment(value: 2, label: Text('2')),
        ButtonSegment(value: 3, label: Text('3')),
      ],
      selected: {value.clamp(0, 3)},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                control,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: Text(label)),
              const SizedBox(width: 12),
              control,
            ],
          );
        },
      ),
    );
  }
}
