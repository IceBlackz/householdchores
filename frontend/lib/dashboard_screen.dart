import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'main.dart'; 
import 'add_chore_screen.dart';
import 'complete_chore_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<RecordModel> _chores = [];
  Map<String, DateTime> _dueDates = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChores();
  }

  Future<void> _fetchChores() async {
    try {
      // Fetch chores and expand BOTH user fields
      final records = await pb.collection('chores').getFullList(
        expand: 'default_assignee,onetimeonly_assignee',
      );
      
      Map<String, DateTime> newDueDates = {};

      for (var chore in records) {
        final logList = await pb.collection('chore_logs').getList(
          page: 1,
          perPage: 1,
          filter: 'chore="${chore.id}"',
          sort: '-created',
        );
        
        if (logList.items.isNotEmpty) {
          final latestLog = logList.items.first;
          DateTime lastCompleted = DateTime.parse(latestLog.getStringValue('created'));
          int desiredInterval = chore.data['interval_desired_days'] ?? 7;
          newDueDates[chore.id] = lastCompleted.add(Duration(days: desiredInterval));
        } else {
          newDueDates[chore.id] = DateTime.now().subtract(const Duration(days: 999));
        }
      }

      // NEW SMART SORTING: Your tasks first, then by Due Date!
      final myUserId = pb.authStore.record?.id;
      
      records.sort((a, b) {
        // Helper to find out who is actively assigned right now
        String getActiveAssigneeId(RecordModel r) {
          String oto = r.getStringValue('onetimeonly_assignee');
          return oto.isNotEmpty ? oto : r.getStringValue('default_assignee');
        }

        bool aIsMine = getActiveAssigneeId(a) == myUserId;
        bool bIsMine = getActiveAssigneeId(b) == myUserId;

        // If 'a' is mine and 'b' is not, 'a' goes to the top
        if (aIsMine && !bIsMine) return -1;
        if (!aIsMine && bIsMine) return 1;

        // If both are mine (or neither are mine), fall back to sorting by urgency
        return newDueDates[a.id]!.compareTo(newDueDates[b.id]!);
      });

      if (mounted) {
        setState(() {
          _chores = records;
          _dueDates = newDueDates;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chores: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() {
    pb.authStore.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Chores'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddChoreScreen()),
          );
          if (result == true) {
            setState(() => _isLoading = true);
            _fetchChores();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chores.isEmpty
              ? const Center(child: Text('No chores found! Time to relax?'))
              : ListView.builder(
                  itemCount: _chores.length,
                  itemBuilder: (context, index) {
                    final chore = _chores[index];
                    final dueDate = _dueDates[chore.id]!;
                    
                    // NEW: Determine which name to show (One-Time overrides Default)
                    String assigneeName = 'Unassigned';
                    bool isOneTime = false;
                    
                    try {
                      final otoAssignee = chore.get<RecordModel?>('expand.onetimeonly_assignee');
                      if (otoAssignee != null) {
                        assigneeName = otoAssignee.getStringValue('name');
                        if (assigneeName.isEmpty) assigneeName = otoAssignee.getStringValue('email');
                        isOneTime = true;
                      } else {
                        final defAssignee = chore.get<RecordModel?>('expand.default_assignee');
                        if (defAssignee != null) {
                          assigneeName = defAssignee.getStringValue('name');
                          if (assigneeName.isEmpty) assigneeName = defAssignee.getStringValue('email');
                        }
                      }
                    } catch (_) {}
                    
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
                    final daysUntilDue = dueDay.difference(today).inDays;
                    
                    String dueText;
                    Color statusColor;
                    
                    if (dueDate.year < 2000) {
                      dueText = 'Never completed';
                      statusColor = Colors.red.shade700;
                    } else if (daysUntilDue < 0) {
                      dueText = 'Overdue ($daysUntilDue days)';
                      statusColor = Colors.red.shade700;
                    } else if (daysUntilDue == 0) {
                      dueText = 'Due today';
                      statusColor = Colors.orange.shade700;
                    } else {
                      dueText = 'Due in $daysUntilDue d';
                      statusColor = Colors.green.shade700;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // If it's assigned to you, give the card a subtle teal tint so it stands out!
                      color: (chore.getStringValue('onetimeonly_assignee').isNotEmpty ? chore.getStringValue('onetimeonly_assignee') : chore.getStringValue('default_assignee')) == pb.authStore.record?.id 
                          ? Colors.teal.shade50 
                          : null,
                      child: ListTile(
                        title: Text(chore.getStringValue('title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chore.getStringValue('description')),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isOneTime ? Icons.swap_horiz : Icons.person, 
                                  size: 16, 
                                  color: isOneTime ? Colors.orange : (assigneeName == 'Unassigned' ? Colors.grey : Colors.teal)
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOneTime ? '$assigneeName (Covering)' : assigneeName, 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    color: isOneTime ? Colors.orange.shade700 : (assigneeName == 'Unassigned' ? Colors.grey : Colors.teal)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // NEW: Added the Edit Pencil next to the Due Date
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.grey),
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => AddChoreScreen(chore: chore)),
                                );
                                if (result == true) {
                                  setState(() => _isLoading = true);
                                  _fetchChores();
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                dueText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CompleteChoreScreen(chore: chore),
                            ),
                          );
                          
                          if (result == true) {
                            setState(() => _isLoading = true);
                            _fetchChores();
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Awesome! Task completed.'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}