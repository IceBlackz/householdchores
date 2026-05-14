import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/chore.dart';
import '../../models/room.dart';
import '../../services/chore_service.dart';

class AddChoreScreen extends StatefulWidget {
  const AddChoreScreen({super.key, this.chore, this.initialRoomId});

  /// If provided, the screen operates in edit mode.
  final Chore? chore;
  final String? initialRoomId;

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _ChoreTemplate {
  const _ChoreTemplate({
    required this.name,
    required this.title,
    required this.description,
    required this.desiredInterval,
    required this.maxInterval,
    required this.intervalUnit,
  });

  final String name;
  final String title;
  final String description;
  final int desiredInterval;
  final int maxInterval;
  final String intervalUnit;
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  static const _templates = [
    _ChoreTemplate(
      name: 'Kitchen reset',
      title: 'Reset the kitchen',
      description: 'Clear counters, load dishes, wipe sink and stovetop.',
      desiredInterval: 1,
      maxInterval: 2,
      intervalUnit: IntervalUnits.days,
    ),
    _ChoreTemplate(
      name: 'Bathroom clean',
      title: 'Clean bathroom',
      description: 'Clean toilet, sink, mirror, and high-touch surfaces.',
      desiredInterval: 7,
      maxInterval: 14,
      intervalUnit: IntervalUnits.days,
    ),
    _ChoreTemplate(
      name: 'Laundry cycle',
      title: 'Run laundry',
      description: 'Wash, dry, fold, and put away household laundry.',
      desiredInterval: 3,
      maxInterval: 7,
      intervalUnit: IntervalUnits.days,
    ),
    _ChoreTemplate(
      name: 'Bins and recycling',
      title: 'Take out bins and recycling',
      description: 'Empty indoor bins and put outside containers ready.',
      desiredInterval: 1,
      maxInterval: 1,
      intervalUnit: IntervalUnits.weeks,
    ),
    _ChoreTemplate(
      name: 'Guest arrival reset',
      title: 'Guest arrival reset',
      description: 'Tidy entry, bathroom, kitchen, and visible clutter.',
      desiredInterval: 1,
      maxInterval: 2,
      intervalUnit: IntervalUnits.days,
    ),
  ];

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
  String? _selectedTemplateName;

  List<AppUser> _users = [];
  List<Room> _rooms = [];
  String? _selectedDefaultAssigneeId;
  String? _selectedOneTimeAssigneeId;
  final Set<String> _selectedRoomIds = {};
  bool _cleanerEnabled = false;
  bool _isLoadingUsers = true;
  bool _isLoadingRooms = true;
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
      _selectedSeason = chore.season.isNotEmpty
          ? chore.season
          : AppConstants.seasons.first;
      _selectedIntervalUnit = chore.intervalUnit;
      _selectedDefaultAssigneeId = chore.defaultAssignee?.id;
      _selectedOneTimeAssigneeId = chore.onetimeOnlyAssignee?.id;
      _cleanerEnabled = chore.cleanerEnabled;
      if (chore.room != null) _selectedRoomIds.add(chore.room!.id);
      _springOverrideController.text = (chore.seasonSpringOverride ?? 0)
          .toString();
      _summerOverrideController.text = (chore.seasonSummerOverride ?? 0)
          .toString();
      _autumnOverrideController.text = (chore.seasonAutumnOverride ?? 0)
          .toString();
      _winterOverrideController.text = (chore.seasonWinterOverride ?? 0)
          .toString();
    } else if (widget.initialRoomId != null) {
      _selectedRoomIds.add(widget.initialRoomId!);
    }
    _fetchUsers();
    _fetchRooms();
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

  Future<void> _fetchRooms() async {
    try {
      final rooms = await context.read<ChoreService>().fetchRooms();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _selectedRoomIds.removeWhere(
            (roomId) => !_rooms.any((room) => room.id == roomId),
          );
          _isLoadingRooms = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRooms = false);
    }
  }

  int _parseOverride(TextEditingController c) => int.tryParse(c.text) ?? 0;

  List<String> _orderedSelectedRoomIds() {
    final roomIds = _selectedRoomIds.toList();
    final currentRoomId = widget.chore?.room?.id;
    if (currentRoomId != null && roomIds.remove(currentRoomId)) {
      return [currentRoomId, ...roomIds];
    }
    return roomIds;
  }

  void _applyTemplate(String? templateName) {
    _ChoreTemplate? template;
    for (final candidate in _templates) {
      if (candidate.name == templateName) {
        template = candidate;
        break;
      }
    }
    final selectedTemplate = template;
    if (selectedTemplate == null) return;

    setState(() {
      _selectedTemplateName = selectedTemplate.name;
      _titleController.text = selectedTemplate.title;
      _descController.text = selectedTemplate.description;
      _desiredIntervalController.text = selectedTemplate.desiredInterval
          .toString();
      _maxIntervalController.text = selectedTemplate.maxInterval.toString();
      _selectedIntervalUnit = selectedTemplate.intervalUnit;
      _selectedSeason = AppConstants.seasons.first;
    });
  }

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
        'cleaner_enabled': _cleanerEnabled,
        'season_spring_override': _parseOverride(_springOverrideController),
        'season_summer_override': _parseOverride(_summerOverrideController),
        'season_autumn_override': _parseOverride(_autumnOverrideController),
        'season_winter_override': _parseOverride(_winterOverrideController),
        'room': _selectedRoomIds.isEmpty ? '' : _orderedSelectedRoomIds().first,
      };

      final service = context.read<ChoreService>();
      final roomIds = _orderedSelectedRoomIds();
      if (widget.chore == null) {
        if (roomIds.length <= 1) {
          await service.createChore(body);
        } else {
          for (final roomId in roomIds) {
            await service.createChore({...body, 'room': roomId});
          }
        }
      } else {
        await service.updateChore(widget.chore!.id, body);
        for (final roomId in roomIds.skip(1)) {
          await service.createChore({...body, 'room': roomId});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.chore == null ? l10n.choreAdded : l10n.choreUpdated,
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.failedToSave(
                e.response['message']?.toString() ?? e.toString(),
              ),
            ),
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
      case 'Spring':
        return l10n.spring;
      case 'Summer':
        return l10n.summer;
      case 'Autumn':
        return l10n.autumn;
      case 'Winter':
        return l10n.winter;
      default:
        return season;
    }
  }

  String _localizedUnit(AppLocalizations l10n, String unit) {
    switch (unit) {
      case IntervalUnits.weeks:
        return l10n.intervalWeeks;
      case IntervalUnits.months:
        return l10n.intervalMonths;
      case IntervalUnits.quarters:
        return l10n.intervalQuarters;
      case IntervalUnits.years:
        return l10n.intervalYears;
      default:
        return l10n.intervalDays;
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
            if (widget.chore == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start from a template',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTemplateName,
                        decoration: const InputDecoration(
                          labelText: 'Common chore templates',
                        ),
                        items: _templates
                            .map(
                              (template) => DropdownMenuItem(
                                value: template.name,
                                child: Text(template.name),
                              ),
                            )
                            .toList(),
                        onChanged: _applyTemplate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.choreTitle),
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.titleRequired : null,
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
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.unassignedAnyone),
                  ),
                  ..._users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.displayName),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _selectedDefaultAssigneeId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedOneTimeAssigneeId,
                decoration: InputDecoration(
                  labelText: l10n.oneTimeOverride,
                  labelStyle: const TextStyle(color: Colors.orange),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.noneUseDefault),
                  ),
                  ..._users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.displayName),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _selectedOneTimeAssigneeId = v),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Show in cleaner list'),
                subtitle: const Text(
                  'Cleaner users can view and complete this chore.',
                ),
                value: _cleanerEnabled,
                onChanged: (value) => setState(() => _cleanerEnabled = value),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingRooms)
              const Center(child: LinearProgressIndicator())
            else
              _RoomSelector(
                rooms: _rooms,
                selectedRoomIds: _selectedRoomIds,
                isEditing: widget.chore != null,
                onChanged: (roomIds) {
                  setState(() {
                    _selectedRoomIds
                      ..clear()
                      ..addAll(roomIds);
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _desiredIntervalController,
                    decoration: InputDecoration(
                      labelText: l10n.desiredInterval,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.required : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedIntervalUnit,
                    decoration: InputDecoration(labelText: l10n.unitLabel),
                    items: IntervalUnits.all
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(_localizedUnit(l10n, u)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedIntervalUnit = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _maxIntervalController,
                    decoration: InputDecoration(labelText: l10n.maxDeadline),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l10n.required : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSeason,
              decoration: InputDecoration(labelText: l10n.season),
              items: AppConstants.seasons
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(_localizedSeasonName(l10n, s)),
                    ),
                  )
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
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

class _RoomSelector extends StatelessWidget {
  const _RoomSelector({
    required this.rooms,
    required this.selectedRoomIds,
    required this.isEditing,
    required this.onChanged,
  });

  final List<Room> rooms;
  final Set<String> selectedRoomIds;
  final bool isEditing;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No rooms yet. You can add rooms from the app menu later.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign to rooms',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              isEditing
                  ? 'Selecting multiple rooms updates this chore and creates independent copies for the extra rooms.'
                  : 'Selecting multiple rooms creates independent chore copies.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('No room'),
                  selected: selectedRoomIds.isEmpty,
                  onSelected: (_) => onChanged({}),
                ),
                ...rooms.map((room) {
                  final selected = selectedRoomIds.contains(room.id);
                  return FilterChip(
                    label: Text(room.name),
                    selected: selected,
                    onSelected: (value) {
                      final next = {...selectedRoomIds};
                      if (value) {
                        next.add(room.id);
                      } else {
                        next.remove(room.id);
                      }
                      onChanged(next);
                    },
                  );
                }),
              ],
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
      decoration: InputDecoration(labelText: '$label ($unit)', hintText: hint),
      keyboardType: TextInputType.number,
    );
  }
}
