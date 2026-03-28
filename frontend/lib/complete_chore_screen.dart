import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

class CompleteChoreScreen extends StatefulWidget {
  final RecordModel chore;

  const CompleteChoreScreen({super.key, required this.chore});

  @override
  State<CompleteChoreScreen> createState() => _CompleteChoreScreenState();
}

class _CompleteChoreScreenState extends State<CompleteChoreScreen> {
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _beforePhoto;
  XFile? _afterPhoto;
  bool _isSaving = false;

  Future<void> _pickImage(bool isBefore) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isBefore) {
          _beforePhoto = image;
        } else {
          _afterPhoto = image;
        }
      });
    }
  }

  Future<void> _submitLog() async {
    setState(() => _isSaving = true);

    try {
      final body = <String, dynamic>{
        "chore": widget.chore.id,
        "completed_by": pb.authStore.record?.id, 
        "notes": _notesController.text,
      };

      final List<http.MultipartFile> files = [];
      
      if (_beforePhoto != null) {
        final beforeBytes = await _beforePhoto!.readAsBytes();
        files.add(http.MultipartFile.fromBytes('photo_before', beforeBytes, filename: _beforePhoto!.name));
      }
      
      if (_afterPhoto != null) {
        final afterBytes = await _afterPhoto!.readAsBytes();
        files.add(http.MultipartFile.fromBytes('photo_after', afterBytes, filename: _afterPhoto!.name));
      }

      // 1. Create the completion log
      await pb.collection('chore_logs').create(body: body, files: files);

      // 2. NEW: If this task had a one-time assignee, clear it out so it resets to the default person!
      if (widget.chore.getStringValue('onetimeonly_assignee').isNotEmpty) {
        await pb.collection('chores').update(widget.chore.id, body: {
          "onetimeonly_assignee": "" 
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete: ${widget.chore.getStringValue('title')}')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Marking this task as done! Feel free to add proof.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          
          OutlinedButton.icon(
            onPressed: () => _pickImage(true),
            icon: const Icon(Icons.camera_alt),
            label: Text(_beforePhoto == null ? 'Attach "Before" Photo' : 'Before Photo Selected!'),
          ),
          const SizedBox(height: 12),
          
          OutlinedButton.icon(
            onPressed: () => _pickImage(false),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_afterPhoto == null ? 'Attach "After" Photo' : 'After Photo Selected!'),
          ),
          
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'e.g. Ran out of soap!',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitLog,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Submit Completion', style: TextStyle(fontSize: 18)),
                ),
        ],
      ),
    );
  }
}