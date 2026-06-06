import 'chore.dart';
import 'chore_log.dart';

class ChoreHistoryEntry {
  const ChoreHistoryEntry({required this.log, this.chore});

  final ChoreLog log;
  final Chore? chore;
}
