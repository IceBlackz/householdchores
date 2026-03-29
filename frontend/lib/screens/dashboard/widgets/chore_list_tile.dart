import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chore.dart';

class ChoreListTile extends StatelessWidget {
  const ChoreListTile({
    super.key,
    required this.chore,
    required this.dueDate,
    required this.currentUserId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
  });

  final Chore chore;
  final DateTime dueDate;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAssignedToMe = chore.activeAssigneeId == currentUserId;
    final isOneTime = chore.hasOneTimeOverride;
    final assigneeName = chore.activeAssigneeName;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDay.difference(today).inDays;

    final String dueText;
    final Color statusColor;

    // Sentinel dates (year < 2000) mean the chore has never been completed
    if (dueDate.year < 2000) {
      dueText = l10n.neverCompleted;
      statusColor = Colors.red.shade700;
    } else if (daysUntilDue < 0) {
      dueText = l10n.overdue(daysUntilDue);
      statusColor = Colors.red.shade700;
    } else if (daysUntilDue == 0) {
      dueText = l10n.dueToday;
      statusColor = Colors.orange.shade700;
    } else {
      dueText = l10n.dueInDays(daysUntilDue);
      statusColor = Colors.green.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isAssignedToMe ? Colors.teal.shade50 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onHistory,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              chore.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chore.description.isNotEmpty) ...[
                  Text(chore.description),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(
                      isOneTime ? Icons.swap_horiz : Icons.person,
                      size: 16,
                      color: isOneTime
                          ? Colors.orange
                          : (assigneeName == AppConstants.unassignedLabel
                              ? Colors.grey
                              : Colors.teal),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOneTime ? l10n.covering(assigneeName) : assigneeName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOneTime
                            ? Colors.orange.shade700
                            : (assigneeName == AppConstants.unassignedLabel
                                ? Colors.grey
                                : Colors.teal),
                      ),
                    ),
                    if (chore.season != 'All') ...[
                      const SizedBox(width: 8),
                      Icon(Icons.eco, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        chore.season,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.grey),
                  tooltip: l10n.viewHistory,
                  onPressed: onHistory,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  tooltip: l10n.editChoreTooltip,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                  tooltip: l10n.deleteChoreTooltip,
                  onPressed: onDelete,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    dueText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
