import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'main.dart'; // This lets us access the 'pb' variable we created earlier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<RecordModel> _chores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChores();
  }

  // Fetch the list of chores from PocketBase
  Future<void> _fetchChores() async {
    try {
      // getFullList fetches all records. We sort by newest first.
      final records = await pb.collection('chores').getFullList(
            sort: '-created',
          );
      
      setState(() {
        _chores = records;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chores: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // A simple logout function to clear the token and go back to login
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chores.isEmpty
              ? const Center(child: Text('No chores found! Time to relax?'))
              : ListView.builder(
                  itemCount: _chores.length,
                  itemBuilder: (context, index) {
                    final chore = _chores[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(chore.data['title'] ?? 'Unknown Task'),
                        subtitle: Text(chore.data['description'] ?? 'No description'),
                        trailing: Text('Every ${chore.data['interval_desired_days']} days'),
                        onTap: () {
                          // We will add the "Complete Task" logic here later!
                        },
                      ),
                    );
                  },
                ),
    );
  }
}