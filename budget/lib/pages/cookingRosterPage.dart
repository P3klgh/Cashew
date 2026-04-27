import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addCookingAssignmentPage.dart';
import 'package:budget/pages/householdMembersPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/cookingCalendarWeekView.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CookingRosterPage extends StatefulWidget {
  const CookingRosterPage({super.key});

  @override
  State<CookingRosterPage> createState() => _CookingRosterPageState();
}

class _CookingRosterPageState extends State<CookingRosterPage> {
  DateTime _weekStart = _startOfWeek(DateTime.now());

  static DateTime _startOfWeek(DateTime d) {
    final day = d.weekday; // 1=Mon
    return DateTime(d.year, d.month, d.day - (day - 1));
  }

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FAB(
        tooltip: 'Add assignment',
        onTap: () => pushRoute(context, const AddCookingAssignmentPage()),
        openPage: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: const Text('Cooking Roster',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.people_outline_rounded),
                tooltip: 'Manage members',
                onPressed: () =>
                    pushRoute(context, const HouseholdMembersPage()),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _prevWeek,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  TextFont(
                    text:
                        '${DateFormat('MMM d').format(_weekStart)} – ${DateFormat('MMM d, y').format(weekEnd)}',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  IconButton(
                    onPressed: _nextWeek,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<HouseholdMember>>(
            stream: database.watchAllHouseholdMembers(),
            builder: (context, memberSnap) {
              final members = memberSnap.data ?? [];
              return StreamBuilder<List<CookingAssignment>>(
                stream: database.watchCookingAssignments(
                    from: _weekStart, to: weekEnd),
                builder: (context, assignSnap) {
                  final assignments = assignSnap.data ?? [];
                  return SliverToBoxAdapter(
                    child: CookingCalendarWeekView(
                      assignments: assignments,
                      members: members,
                      weekStart: _weekStart,
                      onDayTap: (date) => pushRoute(
                        context,
                        AddCookingAssignmentPage(initialDate: date),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          StreamBuilder<List<CookingAssignment>>(
            stream: database.watchCookingAssignments(
                from: _weekStart, to: weekEnd),
            builder: (context, snap) {
              final assignments = snap.data ?? [];
              if (assignments.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsetsDirectional.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restaurant_menu_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No cooking assignments this week',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _AssignmentTile(
                        assignment: assignments[index]),
                    childCount: assignments.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment});

  final CookingAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final isPending =
        assignment.status == CookingAssignmentStatus.pending;
    final isCooked =
        assignment.status == CookingAssignmentStatus.cooked;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        tileColor: Theme.of(context).colorScheme.surfaceVariant,
        leading: Icon(
          isCooked
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isCooked
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(
          assignment.mealName,
          style: TextStyle(
            decoration: isCooked ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          DateFormat('EEE, MMM d').format(assignment.assignedDate),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            CookingAssignmentStatus status;
            switch (val) {
              case 'cooked':
                status = CookingAssignmentStatus.cooked;
                break;
              case 'skipped':
                status = CookingAssignmentStatus.skipped;
                break;
              default:
                status = CookingAssignmentStatus.pending;
            }
            if (val == 'delete') {
              await database.deleteCookingAssignment(
                  assignment.assignmentPk);
            } else {
              await database.createOrUpdateCookingAssignment(
                assignment
                    .toCompanion(true)
                    .copyWith(status: Value(status)),
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
                value: 'cooked', child: Text('Mark as cooked')),
            const PopupMenuItem(
                value: 'skipped', child: Text('Mark as skipped')),
            const PopupMenuItem(
                value: 'pending', child: Text('Mark as pending')),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: TextStyle(color: Colors.red))),
          ],
          child: const Icon(Icons.more_vert_rounded),
        ),
        onTap: () => pushRoute(
          context,
          AddCookingAssignmentPage(existingAssignment: assignment),
        ),
      ),
    );
  }
}
