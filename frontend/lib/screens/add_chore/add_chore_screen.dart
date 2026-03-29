import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/chore.dart';
import '../../services/chore_service.dart';

class AddChoreScreen extends StatefulWidget {
  const AddChoreScreen({super.key, this.chore});

  /// If provided, the screen operates in edit mode.
  final Chore? chore;

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _desiredIntervalController = TextEditingController(
    text: AppConstants.defaultDesiredIntervalDays.toString(),
  );
  final _maxIntervalController = TextEditingController(
    text: AppConstants.defaultMaxIntervalDays.toString(),
  );
  final _springOverrideController = TextEditingController(text: '0');
  final _summerOverrideController = TextEditingController(text: '0');
  final _autumnOverrideController = TextEditingController(text: '0');
  final _winterOverrideController = TextEditingController(text: '0');

  String _selectedSeason = AppConstants.seasons.first;
  String _selectedIntervalUnit = IntervalUnits.days;

  List<AppUser> _users = [];
  String? _selectedDefaultAssigneeId;
  String? _selectedOneTimeAssigneeId;
  bool _isLoadingUsers = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _desiredIntervalController.dispose();
    _maxIntervalController.dispose();
    _springOverrideController.dispose();
    _summerOverrideController.dispose();
    _autumnOverrideController.dispose();
    _winterOverrideController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final chore = widget.chore;
    if (chore != null) {
      _titleController.text = chore.title;
      _descController.text = chore.description;
      _desiredIntervalController.text = chore.intervalDesiredDays.toString();
      _maxIntervalController.text = chore.intervalMaxDays.toString();
      _selectedSeason = chore.season.isNotEmpty ? chore.season : AppConstants.seasons.first;
      _selectedIntervalUnit = chore.intervalUnit;
      _selectedDefaultAssigneeId = chore.defaultAssignee?.id;
      _selectedOneTimeAssigneeId = chore.onetimeOnlyAssignee?.id;
      _springOverrideController.text = (chore.seasonSpringOverride ?? 0).toString();
      _summerOverrideController.text = (chore.seasonSummerOverride ?? 0).toString();
      _autumnOverrideController.text = (chore.seasonAutumnOverride ?? 0).toString();
      _winterOverrideController.text = (chore.seasonWinterOverride ?? 0).toString();
    }
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await context.read<ChoreService>().fetchUsers();
      if (mounted) {
        setState(() {
          _users = users;
          if (_selectedDefaultAssigneeId != null &&
              !_users.any((u) => u.id == _selectedDefaultAssigneeId)) {
            _selectedDefaultAssigneeId = null;
          }
          if (_selectedOneTimeAssigneeId != null &&
              !_users.any((u) => u.id == _selectedOneTimeAssigneeId)) {
            _selectedOneTimeAssigneeId = null;
          }
          _isLoadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  int _parseOverride(TextEditingController c) => int.tryParse(c.text) ?? 0;

  Future<void> _saveChore() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final body = <String, dynamic>{
        'title': _titleController.text,
        'description': _descController.text,
        'interval_desired_days': int.parse(_desiredIntervalController.text),
        'interval_max_days': int.parse(_maxIntervalController.text),
        'interval_unit': _selectedIntervalUnit,
        'season': _selectedSeason,
        'default_assignee': _selectedDefaultAssigneeId ?? '',
        'onetimeonly_assignee': _selectedOneTimeAssigneeId ?? '',
        'season_spring_override': _parseOverride(_springOverrideController),
        'season_summer_override': _parseOverride(_summerOverrideController),
        'season_autumn_override': _parseOverride(_autumnOverrideController),
        'season_winter_override': _parseOverride(_winterOverrideController),
      };

      final service = context.read<ChoreService>();
      if (widget.chore == null) {
        await service.createChore(body);
      } else {
        await service.updateChore(widget.chore!.id, body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.chore == null ? l10n.choreAdded : l10n.choreUpdated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSave(e.response['message']?.toString() ?? e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _localizedSeasonName(AppLocalizations l10n, String season) {
    switch (season) {
      case 'Spring': return l10n.spring;
      case 'Summer': return l10n.summer;
      case 'Autumn': return l10n.autumn;
      case 'Winter': return l10n.winter;
      default: return season;
    }
  }

  String _localizedUnit(AppLocalizations l10n, String unit) {
    switch (unit) {
      case IntervalUnits.weeks:    return l10n.intervalWeeks;
      case IntervalUnits.months:   return l10n.intervalMonths;
      case IntervalUnits.quarters: return l10n.intervalQuarters;
      case IntervalUnits.years:    return l10n.intervalYears;
      default:                     return l10n.intervalDays;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chore == null ? l10n.addNewChore : l10n.editChore),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.choreTitle),
              validator: (v) => (v == null || v.isEmpty) ? l10n.titleRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: 16),
            if (_isLoadingUsers)
              const Center(child: LinearProgressIndicator())
            else ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedDefaultAssigneeId,
                decoration: InputDecoration(labelText: l10n.defaultAssignee),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.unassignedAnyone)),
                  ..._users.map(
                    (u) => DropdownMenuItem(value: u.id, child: Text(u.displayName)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedDefaultAssigneeId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedOneTimeAssigneeId,
                decoration: InputDecoration(
                  labelText: l10n.oneTimeOverride,
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.noneUseDefault)),
                  ..._users.map(
                    (u) => DropdownMenuItem(value: u.id, child: Text(u.displayName)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedOneTimeAssigneeId = v),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _desiredIntervalController,
                    decoration: InputDecoration(labelText: l10n.desiredInterval),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedIntervalUnit,
                    decoration: InputDecoration(labelText: l10n.unitLabel),
                    items: IntervalUnits.all
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(_localizedUnit(l10n, u)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedIntervalUnit = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _maxIntervalController,
                    decoration: InputDecoration(labelText: l10n.maxDeadline),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSeason,
              decoration: InputDecoration(labelText: l10n.season),
              items: AppConstants.seasons
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_localizedSeasonName(l10n, s)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSeason = v!),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: Text(l10n.seasonOverrides),
              subtitle: Text(
                l10n.seasonOverridesSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      _SeasonOverrideField(
                        label: l10n.spring,
                        hint: l10n.seasonFieldHint,
                        controller: _springOverrideController,
                        unit: _localizedUnit(l10n, _selectedIntervalUnit),
                      ),
                      const SizedBox(height: 8),
                      _SeasonOverrideField(
                        label: l10n.summer,
                        hint: l10n.seasonFieldHint,
                        controller: _summerOverrideController,
                        unit: _localizedUnit(l10n, _selectedIntervalUnit),
                      ),
                      const SizedBox(height: 8),
                      _SeasonOverrideField(
                        label: l10n.autumn,
                        hint: l10n.seasonFieldHint,
                        controller: _autumnOverrideController,
                        unit: _localizedUnit(l10n, _selectedIntervalUnit),
                      ),
                      const SizedBox(height: 8),
                      _SeasonOverrideField(
                        label: l10n.winter,
                        hint: l10n.seasonFieldHint,
                        controller: _winterOverrideController,
                        unit: _localizedUnit(l10n, _selectedIntervalUnit),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveChore,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: Text(
                      widget.chore == null ? l10n.saveChore : l10n.updateChore,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SeasonOverrideField extends StatelessWidget {
  const _SeasonOverrideField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.unit,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label ($unit)',
        hintText: hint,
      ),
      keyboardType: TextInputType.number,
    );
  }
}
