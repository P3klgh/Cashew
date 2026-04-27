import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

enum MaintenanceDueStatus { overdue, dueSoon, ok }

MaintenanceDueStatus getMaintenanceDueStatus(DateTime? nextDueDate) {
  if (nextDueDate == null) return MaintenanceDueStatus.ok;
  final now = DateTime.now();
  if (nextDueDate.isBefore(now)) return MaintenanceDueStatus.overdue;
  if (nextDueDate.difference(now).inDays <= 14)
    return MaintenanceDueStatus.dueSoon;
  return MaintenanceDueStatus.ok;
}

class MaintenanceDueBadge extends StatelessWidget {
  const MaintenanceDueBadge({required this.nextDueDate, super.key});

  final DateTime? nextDueDate;

  @override
  Widget build(BuildContext context) {
    final status = getMaintenanceDueStatus(nextDueDate);
    if (status == MaintenanceDueStatus.ok) return const SizedBox.shrink();

    final isOverdue = status == MaintenanceDueStatus.overdue;
    final color =
        isOverdue ? Theme.of(context).colorScheme.error : Colors.orange;
    final label = isOverdue ? 'Overdue' : 'Due soon';

    return Container(
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: TextFont(
        text: label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        textColor: color,
      ),
    );
  }
}
