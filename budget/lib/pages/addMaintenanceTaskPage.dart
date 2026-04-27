import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/maintenanceNotifications.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddMaintenanceTaskPage extends StatefulWidget {
  const AddMaintenanceTaskPage({
    required this.appliancePk,
    this.existingTask,
    super.key,
  });

  final String appliancePk;
  final MaintenanceTask? existingTask;

  @override
  State<AddMaintenanceTaskPage> createState() =>
      _AddMaintenanceTaskPageState();
}

class _AddMaintenanceTaskPageState extends State<AddMaintenanceTaskPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _intervalValueCtrl;
  late MaintenanceIntervalUnit _intervalUnit;
  DateTime? _lastMaintained;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existingTask;
    _nameCtrl = TextEditingController(text: e?.taskName ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _intervalValueCtrl =
        TextEditingController(text: '${e?.intervalValue ?? 3}');
    _intervalUnit = e != null
        ? MaintenanceIntervalUnit.values[e.intervalUnit.index]
        : MaintenanceIntervalUnit.months;
    _lastMaintained = e?.lastMaintainedDate;
    _notificationsEnabled = e?.notificationsEnabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _intervalValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLastMaintained() async {
    final picked =
        await showCustomDatePicker(context, _lastMaintained ?? DateTime.now());
    if (picked != null) setState(() => _lastMaintained = picked);
  }

  DateTime? _computeNextDue() {
    if (_lastMaintained == null) return null;
    final val = int.tryParse(_intervalValueCtrl.text) ?? 1;
    return calculateNextDueDate(_lastMaintained!, val, _intervalUnit);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final val = int.tryParse(_intervalValueCtrl.text) ?? 1;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final nextDue = _computeNextDue();

    final e = widget.existingTask;
    if (e != null) {
      await database.createOrUpdateMaintenanceTask(
        e.toCompanion(true).copyWith(
              taskName: Value(name),
              note: Value(note),
              intervalValue: Value(val),
              intervalUnit: Value(_intervalUnit),
              lastMaintainedDate: Value(_lastMaintained),
              nextDueDate: Value(nextDue),
              notificationsEnabled: Value(_notificationsEnabled),
            ),
      );
    } else {
      final current = await database
          .watchMaintenanceTasksForAppliance(widget.appliancePk)
          .first;
      await database.createOrUpdateMaintenanceTask(
        MaintenanceTasksCompanion(
          applianceFk: Value(widget.appliancePk),
          taskName: Value(name),
          note: Value(note),
          intervalValue: Value(val),
          intervalUnit: Value(_intervalUnit),
          lastMaintainedDate: Value(_lastMaintained),
          nextDueDate: Value(nextDue),
          notificationsEnabled: Value(_notificationsEnabled),
          order: Value(current.length),
        ),
      );
    }
    await scheduleMaintenanceNotifications();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;
    final nextDue = _computeNextDue();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(isEditing ? 'Edit Task' : 'New Task',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
              onPressed: _save,
              child: Text(isEditing ? 'Save' : 'Add')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Task name',
              hintText: 'e.g. Replace filter',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _intervalValueCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Every',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<MaintenanceIntervalUnit>(
                  value: _intervalUnit,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()),
                  onChanged: (v) =>
                      setState(() => _intervalUnit = v!),
                  items: const [
                    DropdownMenuItem(
                        value: MaintenanceIntervalUnit.days,
                        child: Text('Days')),
                    DropdownMenuItem(
                        value: MaintenanceIntervalUnit.weeks,
                        child: Text('Weeks')),
                    DropdownMenuItem(
                        value: MaintenanceIntervalUnit.months,
                        child: Text('Months')),
                    DropdownMenuItem(
                        value: MaintenanceIntervalUnit.years,
                        child: Text('Years')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_available_rounded),
            title: Text(_lastMaintained == null
                ? 'Last maintained: not set'
                : 'Last maintained: ${DateFormat('MMM d, y').format(_lastMaintained!)}'),
            trailing: const Icon(Icons.edit_calendar_rounded),
            onTap: _pickLastMaintained,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
          if (nextDue != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: Text(
                'Next due: ${DateFormat('MMM d, y').format(nextDue)}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13),
              ),
            ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) =>
                setState(() => _notificationsEnabled = v),
            title: const Text('Maintenance reminders'),
            subtitle: const Text('Notify when task is due'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
