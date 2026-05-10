import 'package:flutter/material.dart';
import '../../models/dashboard_preferences.dart';
import '../../services/dashboard_preferences_service.dart';

class DashboardPreferencesScreen extends StatefulWidget {
  const DashboardPreferencesScreen({super.key});

  @override
  State<DashboardPreferencesScreen> createState() =>
      _DashboardPreferencesScreenState();
}

class _DashboardPreferencesScreenState
    extends State<DashboardPreferencesScreen> {
  final _service = DashboardPreferencesService();
  DashboardPreferences _preferences = const DashboardPreferences();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await _service.load();
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _service.save(_preferences);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dashboard preferences saved.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case DashboardPreferences.defaultFilterMine:
        return 'Mine';
      case DashboardPreferences.defaultFilterAttention:
        return 'Attention';
      case DashboardPreferences.defaultFilterCritical:
        return 'Critical';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard preferences'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _isLoading || _isSaving ? null : _save,
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Faster check-ins',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Show quick-complete buttons'),
                          subtitle: const Text(
                            'Adds a check button on each chore for one-tap completion as you.',
                          ),
                          value: _preferences.quickCompleteEnabled,
                          onChanged: (value) => setState(() {
                            _preferences = _preferences.copyWith(
                              quickCompleteEnabled: value,
                            );
                          }),
                        ),
                        SwitchListTile(
                          title: const Text('Micro-celebrations'),
                          subtitle: const Text(
                            'Shows a warmer success message and haptic tap after completion.',
                          ),
                          value: _preferences.celebrationsEnabled,
                          onChanged: (value) => setState(() {
                            _preferences = _preferences.copyWith(
                              celebrationsEnabled: value,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Default focus',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Text(
                            'Choose the dashboard filter you want to start on.',
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: SegmentedButton<String>(
                            segments: DashboardPreferences.defaultFilters
                                .map(
                                  (filter) => ButtonSegment(
                                    value: filter,
                                    label: Text(_filterLabel(filter)),
                                  ),
                                )
                                .toList(),
                            selected: {_preferences.defaultFilter},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _preferences = _preferences.copyWith(
                                  defaultFilter: selection.first,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
