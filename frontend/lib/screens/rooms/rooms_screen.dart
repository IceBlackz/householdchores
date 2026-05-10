import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/room.dart';
import '../../models/room_chore_suggestion.dart';
import '../../services/chore_service.dart';
import '../add_chore/add_chore_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rooms = await context.read<ChoreService>().fetchRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showRoomDialog({Room? room}) async {
    final service = context.read<ChoreService>();
    final nameController = TextEditingController(text: room?.name ?? '');
    final iconController = TextEditingController(text: room?.icon ?? '');
    final isEditing = room != null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit room' : 'Add room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Room name',
                hintText: 'Kitchen, Toilet, Bedroom...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(
                labelText: 'Icon label (optional)',
                hintText: 'kitchen, wc, bed...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    if (isEditing) {
      await service.updateRoom(
        room.id,
        name: name,
        icon: iconController.text.trim(),
      );
    } else {
      await service.createRoom(name: name, icon: iconController.text.trim());
    }
    await _loadRooms();
  }

  Future<void> _duplicateRoom(Room room) async {
    final service = context.read<ChoreService>();
    final controller = TextEditingController(text: '${room.name} copy');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate room and tasks'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New room name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;

    await service.duplicateRoomWithChores(room, controller.text.trim());
    await _loadRooms();
  }

  Future<void> _deleteRoom(Room room) async {
    final service = context.read<ChoreService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
          'Delete ${room.name}? Existing chores will stay, but no longer belong to this room.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.deleteRoom(room.id);
    await _loadRooms();
  }

  Future<void> _addSuggestions(Room room) async {
    final service = context.read<ChoreService>();
    final suggestions = RoomChoreSuggestions.forRoomName(room.name);
    final selectedIds = suggestions.map((s) => s.id).toSet();
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        final working = {...selectedIds};
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Suggested chores for ${room.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: suggestions
                    .map(
                      (suggestion) => CheckboxListTile(
                        title: Text(suggestion.prompt),
                        subtitle: Text(
                          '${suggestion.title} every ${suggestion.desiredInterval} ${suggestion.intervalUnit}',
                        ),
                        value: working.contains(suggestion.id),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              working.add(suggestion.id);
                            } else {
                              working.remove(suggestion.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(working),
                child: const Text('Add selected'),
              ),
            ],
          ),
        );
      },
    );

    if (chosen == null || chosen.isEmpty) return;
    for (final suggestion in suggestions.where((s) => chosen.contains(s.id))) {
      await service.createChore(suggestion.toChoreBody(room.id));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${chosen.length} suggested chores.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addChore(Room room) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddChoreScreen(initialRoomId: room.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms and focus zones'),
        actions: [
          IconButton(
            onPressed: () => _showRoomDialog(),
            icon: const Icon(Icons.add_home_work_outlined),
            tooltip: 'Add room',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRoomDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add room'),
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
                  FilledButton(
                    onPressed: _loadRooms,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _rooms.isEmpty
          ? _EmptyRooms(onAddRoom: () => _showRoomDialog())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  return Card(
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade50,
                        child: Icon(
                          _iconForRoom(room),
                          color: Colors.teal.shade700,
                        ),
                      ),
                      title: Text(room.name),
                      subtitle: const Text('Focus zone'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _addChore(room),
                              icon: const Icon(Icons.add_task),
                              label: const Text('Add chore here'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _addSuggestions(room),
                              icon: const Icon(Icons.lightbulb_outline),
                              label: const Text('Suggested chores'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _duplicateRoom(room),
                              icon: const Icon(Icons.copy_all_outlined),
                              label: const Text('Duplicate room'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _showRoomDialog(room: room),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteRoom(room),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                              ),
                              label: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade400),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  IconData _iconForRoom(Room room) {
    final value = '${room.icon} ${room.name}'.toLowerCase();
    if (value.contains('kitchen')) return Icons.kitchen;
    if (value.contains('toilet') || value.contains('wc')) return Icons.wc;
    if (value.contains('bath')) return Icons.bathtub;
    if (value.contains('bed')) return Icons.bed;
    if (value.contains('living')) return Icons.weekend;
    if (value.contains('garden')) return Icons.yard;
    return Icons.meeting_room_outlined;
  }
}

class _EmptyRooms extends StatelessWidget {
  const _EmptyRooms({required this.onAddRoom});

  final VoidCallback onAddRoom;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 52,
              color: Colors.teal.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first room',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rooms let you focus on one zone at a time and generate sensible chore suggestions.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAddRoom,
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('Add room'),
            ),
          ],
        ),
      ),
    );
  }
}
