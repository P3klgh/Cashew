import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CookingCalendarWeekView extends StatelessWidget {
  const CookingCalendarWeekView({
    required this.assignments,
    required this.members,
    required this.weekStart,
    required this.onDayTap,
    super.key,
  });

  final List<CookingAssignment> assignments;
  final List<HouseholdMember> members;
  final DateTime weekStart;

  /// Called with the tapped date so parent can open the add-assignment page.
  final void Function(DateTime date) onDayTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = weekStart.add(Duration(days: index));
          final dayAssignments = assignments.where((a) {
            final d = a.assignedDate;
            return d.year == date.year &&
                d.month == date.month &&
                d.day == date.day;
          }).toList();

          final isToday = _isSameDay(date, DateTime.now());

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Tappable(
              onTap: () => onDayTap(date),
              borderRadius: 14,
              color: isToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : Theme.of(context).colorScheme.surfaceVariant,
              child: Container(
                width: 62,
                padding: const EdgeInsetsDirectional.symmetric(
                    vertical: 8, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextFont(
                      text: DateFormat('E').format(date),
                      fontSize: 11,
                      textColor: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    TextFont(
                      text: date.day.toString(),
                      fontSize: 15,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      textColor: isToday
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    if (dayAssignments.isNotEmpty)
                      _MemberDots(
                          assignments: dayAssignments, members: members)
                    else
                      const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MemberDots extends StatelessWidget {
  const _MemberDots({required this.assignments, required this.members});

  final List<CookingAssignment> assignments;
  final List<HouseholdMember> members;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      children: assignments.take(3).map((a) {
        final member = members.firstWhere(
          (m) => m.memberPk == a.memberFk,
          orElse: () => members.isNotEmpty
              ? members.first
              : HouseholdMember(
                  memberPk: '',
                  supabaseUid: '',
                  displayName: '?',
                  email: '',
                  colour: null,
                  order: 0,
                  dateCreated: DateTime.now(),
                ),
        );
        final colorHex = member.colour;
        Color dotColor = Theme.of(context).colorScheme.primary;
        if (colorHex != null && colorHex.isNotEmpty) {
          try {
            dotColor = Color(int.parse('FF$colorHex', radix: 16));
          } catch (_) {}
        }
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
