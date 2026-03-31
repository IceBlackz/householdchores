import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chore.dart';

class ChoreListTile extends StatelessWidget {
  const ChoreListTile({
    super.key,
    required this.chore,
    required this.dueDate,
    required this.maxDueDate,
    required this.currentUserId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
  });

  final Chore chore;
  final DateTime dueDate;
  final DateTime maxDueDate;
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
    final maxDay = DateTime(maxDueDate.year, maxDueDate.month, maxDueDate.day);
    final daysUntilDue = dueDay.difference(today).inDays;
    final daysUntilMax = maxDay.difference(today).inDays;

    final String dueText;
    final Color statusColor;
    final bool isCritical;

    // Sentinel dates (year < 2000) = never completed
    if (dueDate.year < 2000) {
      dueText = l10n.neverCompleted;
      statusColor = Colors.red.shade700;
      isCritical = false;
    } else if (daysUntilMax < 0) {
      // FIX: past the hard deadline — show critical state
      dueText = l10n.pastDeadline(daysUntilMax.abs());
      statusColor = Colors.red.shade900;
      isCritical = true;
    } else if (daysUntilDue < 0) {
      // Past desired interval but still within max — FIX: abs() so it shows "3" not "-3"
      dueText = l10n.overdue(daysUntilDue.abs());
      statusColor = Colors.orange.shade800;
      isCritical = false;
    } else if (daysUntilDue == 0) {
      dueText = l10n.dueToday;
      statusColor = Colors.orange.shade700;
      isCritical = false;
    } else {
      dueText = l10n.dueInDays(daysUntilDue);
      statusColor = Colors.green.shade700;
      isCritical = false;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Critical overrides the "assigned to me" teal tint
      color: isCritical
          ? Colors.red.shade50
          : (isAssignedToMe ? Colors.teal.shade50 : null),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onHistory,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    chore.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isCritical)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 18),
                  ),
              ],
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
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor,
                      width: isCritical ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    dueText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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