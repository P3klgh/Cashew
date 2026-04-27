import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addAppliancePage.dart';
import 'package:budget/pages/applianceDetailPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/maintenanceNotifications.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/maintenanceDueBadge.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppliancesPage extends StatefulWidget {
  const AppliancesPage({super.key});

  @override
  State<AppliancesPage> createState() => _AppliancesPageState();
}

class _AppliancesPageState extends State<AppliancesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FAB(
        tooltip: 'Add appliance',
        onTap: () => pushRoute(context, const AddAppliancePage()),
        openPage: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: const Text('Appliances',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<List<Appliance>>(
            stream: database.watchAllAppliances(),
            builder: (context, snap) {
              final appliances = snap.data ?? [];
              if (appliances.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.devices_other_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No appliances yet',
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
                    (context, index) =>
                        _ApplianceCard(appliance: appliances[index]),
                    childCount: appliances.length,
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

class _ApplianceCard extends StatelessWidget {
  const _ApplianceCard({required this.appliance});

  final Appliance appliance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Tappable(
        borderRadius: 16,
        color: Theme.of(context).colorScheme.surfaceVariant,
        onTap: () => pushRoute(
            context, ApplianceDetailPage(appliance: appliance)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF5C6BC0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.build_rounded,
                    color: Color(0xFF5C6BC0), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: StreamBuilder<List<MaintenanceTask>>(
                  stream: database.watchMaintenanceTasksForAppliance(
                      appliance.appliancePk),
                  builder: (context, snap) {
                    final tasks = snap.data ?? [];
                    final overdue = tasks.where((t) =>
                        getMaintenanceDueStatus(t.nextDueDate) ==
                        MaintenanceDueStatus.overdue).toList();
                    final dueSoon = tasks.where((t) =>
                        getMaintenanceDueStatus(t.nextDueDate) ==
                        MaintenanceDueStatus.dueSoon).toList();

                    final nextDueTask = tasks
                        .where((t) => t.nextDueDate != null)
                        .toList()
                      ..sort((a, b) =>
                          a.nextDueDate!.compareTo(b.nextDueDate!));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFont(
                            text: appliance.name,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                        const SizedBox(height: 3),
                        if (overdue.isNotEmpty)
                          Text(
                            '${overdue.length} task${overdue.length > 1 ? "s" : ""} overdue',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.error),
                          )
                        else if (nextDueTask.isNotEmpty)
                          Text(
                            'Next: ${DateFormat("MMM d").format(nextDueTask.first.nextDueDate!)} — ${nextDueTask.first.taskName}',
                            style: TextStyle(
                                fontSize: 12,
                                color: getColor(context, 'textLight')),
                          )
                        else if (tasks.isEmpty)
                          Text(
                            'No tasks',
                            style: TextStyle(
                                fontSize: 12,
                                color: getColor(context, 'textLight')),
                          ),
                      ],
                    );
                  },
                ),
              ),
              StreamBuilder<List<MaintenanceTask>>(
                stream: database.watchMaintenanceTasksForAppliance(
                    appliance.appliancePk),
                builder: (context, snap) {
                  final tasks = snap.data ?? [];
                  final worst = tasks.fold<MaintenanceDueStatus>(
                    MaintenanceDueStatus.ok,
                    (prev, t) {
                      final s = getMaintenanceDueStatus(t.nextDueDate);
                      if (s == MaintenanceDueStatus.overdue)
                        return MaintenanceDueStatus.overdue;
                      if (prev != MaintenanceDueStatus.overdue &&
                          s == MaintenanceDueStatus.dueSoon)
                        return MaintenanceDueStatus.dueSoon;
                      return prev;
                    },
                  );
                  if (worst == MaintenanceDueStatus.ok)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: MaintenanceDueBadge(
                        nextDueDate: worst == MaintenanceDueStatus.overdue
                            ? DateTime.now().subtract(const Duration(days: 1))
                            : DateTime.now()
                                .add(const Duration(days: 7))),
                  );
                },
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'edit') {
                    pushRoute(
                      context,
                      AddAppliancePage(existingAppliance: appliance),
                    );
                  } else if (val == 'delete') {
                    await database.deleteMaintenanceTasksForAppliance(
                        appliance.appliancePk);
                    await database.deleteAppliance(appliance.appliancePk);
                    await scheduleMaintenanceNotifications();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
                child: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
