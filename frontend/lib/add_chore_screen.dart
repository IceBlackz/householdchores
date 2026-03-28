import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'main.dart'; 

class AddChoreScreen extends StatefulWidget {
  final RecordModel? chore; // NEW: If provided, the screen acts as an "Edit" screen!

  const AddChoreScreen({super.key, this.chore});

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _desiredIntervalController = TextEditingController(text: '7');
  final _maxIntervalController = TextEditingController(text: '14');
  String _selectedSeason = 'All';
  
  List<RecordModel> _users = [];
  String? _selectedDefaultAssigneeId;
  String? _selectedOneTimeAssigneeId; // NEW: One-time override
  bool _isLoadingUsers = true;
  bool _isSaving = false;

  final List<String> _seasons = ['All', 'Spring', 'Summer', 'Autumn', 'Winter'];

  @override
  void initState() {
    super.initState();
    
    // NEW: If we are editing an existing chore, pre-fill all the data!
    if (widget.chore != null) {
      _titleController.text = widget.chore!.getStringValue('title');
      _descController.text = widget.chore!.getStringValue('description');
      _desiredIntervalController.text = widget.chore!.getIntValue('interval_desired_days').toString();
      _maxIntervalController.text = widget.chore!.getIntValue('interval_max_days').toString();
      
      _selectedSeason = widget.chore!.getStringValue('season');
      if (_selectedSeason.isEmpty) _selectedSeason = 'All';

      String defAssignee = widget.chore!.getStringValue('default_assignee');
      if (defAssignee.isNotEmpty) _selectedDefaultAssigneeId = defAssignee;

      String oneTimeAssignee = widget.chore!.getStringValue('onetimeonly_assignee');
      if (oneTimeAssignee.isNotEmpty) _selectedOneTimeAssigneeId = oneTimeAssignee;
    }

    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await pb.collection('users').getFullList(sort: 'name');
      if (mounted) {
        setState(() {
          _users = users;
          
          // Safety check: ensure selected IDs actually exist in the database
          if (_selectedDefaultAssigneeId != null && !_users.any((u) => u.id == _selectedDefaultAssigneeId)) {
            _selectedDefaultAssigneeId = null;
          }
          if (_selectedOneTimeAssigneeId != null && !_users.any((u) => u.id == _selectedOneTimeAssigneeId)) {
            _selectedOneTimeAssigneeId = null;
          }

          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _saveChore() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        "title": _titleController.text,
        "description": _descController.text,
        "interval_desired_days": int.parse(_desiredIntervalController.text),
        "interval_max_days": int.parse(_maxIntervalController.text),
        "season": _selectedSeason,
        "default_assignee": _selectedDefaultAssigneeId ?? "", 
        "onetimeonly_assignee": _selectedOneTimeAssigneeId ?? "", 
      };

      // NEW: If we have a chore, update it. Otherwise, create a new one!
      if (widget.chore == null) {
        await pb.collection('chores').create(body: body);
      } else {
        await pb.collection('chores').update(widget.chore!.id, body: body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.chore == null ? 'Chore added!' : 'Chore updated!'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.of(context).pop(true); 
      }
    } on ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.response['message'] ?? e}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chore == null ? 'Add New Chore' : 'Edit Chore')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Chore Title (e.g. Clean Toilet)'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
            ),
            const SizedBox(height: 16),
            
            if (_isLoadingUsers) const Center(child: LinearProgressIndicator()) else ...[
              DropdownButtonFormField<String?>(
                initialValue: _selectedDefaultAssigneeId,
                decoration: const InputDecoration(labelText: 'Default Assignee'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned (Anyone)')),
                  ..._users.map((user) {
                    String displayName = user.getStringValue('name');
                    if (displayName.isEmpty) displayName = user.getStringValue('email');
                    return DropdownMenuItem(value: user.id, child: Text(displayName));
                  }),
                ],
                onChanged: (String? newValue) => setState(() => _selectedDefaultAssigneeId = newValue),
              ),
              const SizedBox(height: 16),
              
              // NEW: One-Time Override Dropdown
              DropdownButtonFormField<String?>(
                initialValue: _selectedOneTimeAssigneeId,
                decoration: const InputDecoration(
                  labelText: 'One-Time Override (This cycle only)',
                  labelStyle: TextStyle(color: Colors.orange),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None (Use Default)')),
                  ..._users.map((user) {
                    String displayName = user.getStringValue('name');
                    if (displayName.isEmpty) displayName = user.getStringValue('email');
                    return DropdownMenuItem(value: user.id, child: Text(displayName));
                  }),
                ],
                onChanged: (String? newValue) => setState(() => _selectedOneTimeAssigneeId = newValue),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _desiredIntervalController,
                    decoration: const InputDecoration(labelText: 'Desired Interval (Days)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxIntervalController,
                    decoration: const InputDecoration(labelText: 'Max Deadline (Days)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSeason,
              decoration: const InputDecoration(labelText: 'Season'),
              items: _seasons.map((String season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() => _selectedSeason = newValue!);
              },
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveChore,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: Text(widget.chore == null ? 'Save Chore' : 'Update Chore', style: const TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}