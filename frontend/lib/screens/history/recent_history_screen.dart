import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chore_history_entry.dart';
import '../../models/chore_log.dart';
import '../../services/chore_service.dart';
import '../../services/pocketbase_service.dart';
import 'chore_history_screen.dart';

class RecentHistoryScreen extends StatefulWidget {
  const RecentHistoryScreen({super.key});

  @override
  State<RecentHistoryScreen> createState() => _RecentHistoryScreenState();
}

class _RecentHistoryScreenState extends State<RecentHistoryScreen> {
  List<ChoreHistoryEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries = await context.read<ChoreService>().fetchRecentHistory();
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  String _photoUrl(ChoreLog log, String filename) =>
      PocketBaseService().fileUrl(log.collectionId ?? '', log.id, filename);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task history')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _entries.isEmpty
          ? const Center(child: Text('No completed tasks yet.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: _entries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final log = entry.log;
                  final chore = entry.chore;
                  final title = chore?.title ?? 'Deleted task';
                  final completedBy = log.completedByName ?? 'Unknown user';

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: chore == null
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChoreHistoryScreen(chore: chore),
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_formatDate(log.created)} by $completedBy',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (chore != null)
                                  const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                            if (log.notes.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(log.notes),
                            ],
                            if (log.photoBeforeFilename != null ||
                                log.photoAfterFilename != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (log.photoBeforeFilename != null)
                                    _HistoryPhotoThumb(
                                      url: _photoUrl(
                                        log,
                                        log.photoBeforeFilename!,
                                      ),
                                      label: 'Before',
                                    ),
                                  if (log.photoAfterFilename != null)
                                    _HistoryPhotoThumb(
                                      url: _photoUrl(
                                        log,
                                        log.photoAfterFilename!,
                                      ),
                                      label: 'After',
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day} ${_monthName(d.month)} ${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) => const [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m];
}

class _HistoryPhotoThumb extends StatelessWidget {
  const _HistoryPhotoThumb({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 76,
            height: 76,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 76,
              height: 76,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
