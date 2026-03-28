import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'main.dart'; // To access the 'pb' variable

class AddChoreScreen extends StatefulWidget {
  const AddChoreScreen({super.key});

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
  bool _isSaving = false;

  final List<String> _seasons = ['All', 'Spring', 'Summer', 'Autumn', 'Winter'];

  Future<void> _saveChore() async {
    // Validate the form fields first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Create the record in PocketBase
      final body = <String, dynamic>{
        "title": _titleController.text,
        "description": _descController.text,
        "interval_desired_days": int.parse(_desiredIntervalController.text),
        "interval_max_days": int.parse(_maxIntervalController.text),
        "season": _selectedSeason,
        // We will add the default_assignee later when we build the user picker!
      };

      await pb.collection('chores').create(body: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chore added successfully!'), backgroundColor: Colors.green),
        );
        // Go back to the dashboard
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
      appBar: AppBar(title: const Text('Add New Chore')),
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
                setState(() {
                  _selectedSeason = newValue!;
                });
              },
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveChore,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: const Text('Save Chore', style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}