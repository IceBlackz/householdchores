import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chore.dart';
import '../../providers/chore_provider.dart';
import '../../services/auth_service.dart';

class CompleteChoreScreen extends StatefulWidget {
  const CompleteChoreScreen({super.key, required this.chore});

  final Chore chore;

  @override
  State<CompleteChoreScreen> createState() => _CompleteChoreScreenState();
}

class _CompleteChoreScreenState extends State<CompleteChoreScreen> {
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _beforePhoto;
  XFile? _afterPhoto;
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBefore) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
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
    final l10n = AppLocalizations.of(context)!;
    try {
      final currentUserId = context.read<AuthService>().currentUserId ?? '';
      await context.read<ChoreProvider>().completeChore(
            widget.chore.id,
            currentUserId,
            photoBefore: _beforePhoto,
            photoAfter: _afterPhoto,
            notes: _notesController.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSubmit(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.completeChore(widget.chore.title))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.markingTaskAsDone,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _pickImage(true),
            icon: const Icon(Icons.camera_alt),
            label: Text(_beforePhoto == null ? l10n.attachBeforePhoto : l10n.beforePhotoSelected),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(false),
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(_afterPhoto == null ? l10n.attachAfterPhoto : l10n.afterPhotoSelected),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: l10n.notes,
              hintText: l10n.notesHint,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitLog,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: Text(l10n.submitCompletion, style: const TextStyle(fontSize: 18)),
                ),
        ],
      ),
    );
  }
}
