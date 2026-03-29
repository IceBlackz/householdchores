import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chore.dart';
import '../../models/chore_log.dart';
import '../../services/chore_service.dart';
import '../../services/pocketbase_service.dart';

class ChoreHistoryScreen extends StatefulWidget {
  const ChoreHistoryScreen({super.key, required this.chore});

  final Chore chore;

  @override
  State<ChoreHistoryScreen> createState() => _ChoreHistoryScreenState();
}

class _ChoreHistoryScreenState extends State<ChoreHistoryScreen> {
  List<ChoreLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final logs = await context.read<ChoreService>().fetchLogs(widget.chore.id);
      if (mounted) setState(() { _logs = logs; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToLoadHistory(e.toString()))),
        );
      }
    }
  }

  String _photoUrl(ChoreLog log, String filename) =>
      PocketBaseService().fileUrl(log.collectionId ?? '', log.id, filename);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.history(widget.chore.title))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text(l10n.noHistoryYet))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final completedOn = _formatDate(log.created);
                    final completedBy = log.completedByName ?? l10n.unknownUser;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  completedOn,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                completedBy,
                                style: TextStyle(color: Colors.teal.shade700),
                              ),
                            ],
                          ),
                          if (log.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(log.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                          if (log.photoBeforeFilename != null || log.photoAfterFilename != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (log.photoBeforeFilename != null)
                                  _PhotoThumb(url: _photoUrl(log, log.photoBeforeFilename!), label: 'Before'),
                                if (log.photoBeforeFilename != null && log.photoAfterFilename != null)
                                  const SizedBox(width: 8),
                                if (log.photoAfterFilename != null)
                                  _PhotoThumb(url: _photoUrl(log, log.photoAfterFilename!), label: 'After'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day} ${_monthName(d.month)} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) => const [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
