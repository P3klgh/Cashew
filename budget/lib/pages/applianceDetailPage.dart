import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addMaintenanceTaskPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/maintenanceNotifications.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/maintenanceDueBadge.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApplianceDetailPage extends StatelessWidget {
  const ApplianceDetailPage({required this.appliance, super.key});

  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FAB(
        tooltip: 'Add task',
        onTap: () => pushRoute(
          context,
          AddMaintenanceTaskPage(appliancePk: appliance.appliancePk),
        ),
        openPage: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: Text(appliance.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (appliance.note != null && appliance.note!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
                child: Text(appliance.note!,
                    style: TextStyle(
                        color: getColor(context, 'textLight'), fontSize: 13)),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
              child: TextFont(
                text: 'Maintenance Tasks',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                textColor: getColor(context, 'textLight'),
              ),
            ),
          ),
          StreamBuilder<List<MaintenanceTask>>(
            stream: database.watchMaintenanceTasksForAppliance(
                appliance.appliancePk),
            builder: (context, snap) {
              final tasks = snap.data ?? [];
              if (tasks.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.build_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No tasks yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) =>
                        _MaintenanceTaskCard(task: tasks[i]),
                    childCount: tasks.length,
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

class _MaintenanceTaskCard extends StatelessWidget {
  const _MaintenanceTaskCard({required this.task});

  final MaintenanceTask task;

  Future<void> _markMaintained(BuildContext context) async {
    final now = DateTime.now();
    final val = task.intervalValue;
    final unit = task.intervalUnit;
    final nextDue = calculateNextDueDate(now, val, unit);

    await database.createOrUpdateMaintenanceTask(
      task.toCompanion(true).copyWith(
            lastMaintainedDate: Value(now),
            nextDueDate: Value(nextDue),
          ),
    );
    await scheduleMaintenanceNotifications();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Marked as maintained. Next due: ${DateFormat("MMM d, y").format(nextDue)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = getMaintenanceDueStatus(task.nextDueDate);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFont(
                        text: task.taskName,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                  MaintenanceDueBadge(nextDueDate: task.nextDueDate),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'edit') {
                        pushRoute(
                          context,
                          AddMaintenanceTaskPage(
                            appliancePk: task.applianceFk,
                            existingTask: task,
                          ),
                        );
                      } else if (val == 'delete') {
                        await database
                            .deleteMaintenanceTask(task.taskPk);
                        await scheduleMaintenanceNotifications();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style:
                                  TextStyle(color: Colors.red))),
                    ],
                    child: const Icon(Icons.more_vert_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Every ${task.intervalValue} '
                '${task.intervalUnit.name}',
                style: TextStyle(
                    fontSize: 12,
                    color: getColor(context, 'textLight')),
              ),
              if (task.lastMaintainedDate != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Last: ${DateFormat("MMM d, y").format(task.lastMaintainedDate!)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: getColor(context, 'textLight')),
                ),
              ],
              if (task.nextDueDate != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Next: ${DateFormat("MMM d, y").format(task.nextDueDate!)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: status == MaintenanceDueStatus.overdue
                          ? Theme.of(context).colorScheme.error
                          : getColor(context, 'textLight')),
                ),
              ],
              if (task.note != null && task.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.note!,
                    style: TextStyle(
                        fontSize: 12,
                        color: getColor(context, 'textLight'))),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _markMaintained(context),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Mark as maintained'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
