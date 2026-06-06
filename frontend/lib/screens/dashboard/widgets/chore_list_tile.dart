import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/chore.dart';
import '../../../utils/room_icons.dart';

class ChoreListTile extends StatelessWidget {
  const ChoreListTile({
    super.key,
    required this.chore,
    required this.dueDate,
    required this.maxDueDate,
    required this.currentUserId,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onHistory,
    this.onQuickComplete,
  });

  final Chore chore;
  final DateTime dueDate;
  final DateTime maxDueDate;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHistory;
  final VoidCallback? onQuickComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkTheme = theme.brightness == Brightness.dark;
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
      statusColor = isDarkTheme ? Colors.red.shade300 : Colors.red.shade700;
      isCritical = false;
    } else if (daysUntilMax < 0) {
      // FIX: past the hard deadline — show critical state
      dueText = l10n.pastDeadline(daysUntilMax.abs());
      statusColor = isDarkTheme ? Colors.red.shade200 : Colors.red.shade900;
      isCritical = true;
    } else if (daysUntilDue < 0) {
      // Past desired interval but still within max — FIX: abs() so it shows "3" not "-3"
      dueText = l10n.overdue(daysUntilDue.abs());
      statusColor = isDarkTheme
          ? Colors.orange.shade300
          : Colors.orange.shade800;
      isCritical = false;
    } else if (daysUntilDue == 0) {
      dueText = l10n.dueToday;
      statusColor = isDarkTheme
          ? Colors.orange.shade300
          : Colors.orange.shade700;
      isCritical = false;
    } else {
      dueText = l10n.dueInDays(daysUntilDue);
      statusColor = isDarkTheme ? Colors.green.shade300 : Colors.green.shade700;
      isCritical = false;
    }

    final actionButtons = <Widget>[
      if (onQuickComplete != null)
        IconButton(
          icon: Icon(Icons.check_circle_outline, color: Colors.green.shade700),
          tooltip: 'Quick complete',
          onPressed: onQuickComplete,
        ),
      if (onHistory != null)
        IconButton(
          icon: const Icon(Icons.history, color: Colors.grey),
          tooltip: l10n.viewHistory,
          onPressed: onHistory,
        ),
      if (onEdit != null)
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.grey),
          tooltip: l10n.editChoreTooltip,
          onPressed: onEdit,
        ),
      if (onDelete != null)
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
          tooltip: l10n.deleteChoreTooltip,
          onPressed: onDelete,
        ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Critical overrides the "assigned to me" teal tint
      color: isCritical
          ? colorScheme.errorContainer.withValues(
              alpha: isDarkTheme ? 0.36 : 0.58,
            )
          : (isAssignedToMe
                ? colorScheme.primaryContainer.withValues(
                    alpha: isDarkTheme ? 0.32 : 0.58,
                  )
                : null),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onHistory,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      chore.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isCritical)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 1),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _StatusPill(
                    text: dueText,
                    color: statusColor,
                    isCritical: isCritical,
                  ),
                ],
              ),
              if (chore.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(chore.description),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MetaChip(
                    icon: isOneTime ? Icons.swap_horiz : Icons.person,
                    iconColor: isOneTime
                        ? Colors.orange
                        : (assigneeName == AppConstants.unassignedLabel
                              ? Colors.grey
                              : Colors.teal),
                    label: isOneTime
                        ? l10n.covering(assigneeName)
                        : assigneeName,
                    labelColor: isOneTime
                        ? Colors.orange.shade700
                        : (assigneeName == AppConstants.unassignedLabel
                              ? Colors.grey
                              : Colors.teal),
                  ),
                  if (chore.season != 'All')
                    _MetaChip(
                      icon: Icons.eco,
                      iconColor: Colors.grey.shade500,
                      label: chore.season,
                      labelColor: Colors.grey.shade600,
                    ),
                  if (chore.cleanerEnabled)
                    _MetaChip(
                      icon: Icons.cleaning_services_outlined,
                      iconColor: Colors.blueGrey.shade500,
                      label: 'Cleaner',
                      labelColor: Colors.blueGrey.shade600,
                    ),
                  if (chore.room != null)
                    _MetaChip(
                      icon: iconForRoom(chore.room!),
                      iconColor: Colors.blueGrey.shade500,
                      label: chore.room!.name,
                      labelColor: Colors.blueGrey.shade600,
                    ),
                ],
              ),
              if (actionButtons.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: actionButtons,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.color,
    required this.isCritical,
  });

  final String text;
  final Color color;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: isCritical ? 2 : 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
