import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/util/showDatePicker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddCookingAssignmentPage extends StatefulWidget {
  const AddCookingAssignmentPage({
    this.initialDate,
    this.existingAssignment,
    super.key,
  });

  final DateTime? initialDate;
  final CookingAssignment? existingAssignment;

  @override
  State<AddCookingAssignmentPage> createState() =>
      _AddCookingAssignmentPageState();
}

class _AddCookingAssignmentPageState
    extends State<AddCookingAssignmentPage> {
  late DateTime _date;
  late final TextEditingController _mealNameCtrl;
  late final TextEditingController _mealTypeCtrl;
  late final TextEditingController _noteCtrl;
  String? _selectedMemberPk;
  HouseholdRecurrence _recurrence = HouseholdRecurrence.none;

  @override
  void initState() {
    super.initState();
    final e = widget.existingAssignment;
    _date = e?.assignedDate ?? widget.initialDate ?? DateTime.now();
    _mealNameCtrl = TextEditingController(text: e?.mealName ?? '');
    _mealTypeCtrl = TextEditingController(text: e?.mealType ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedMemberPk = e?.memberFk;
    _recurrence = e != null
        ? HouseholdRecurrence.values[e.recurrence.index]
        : HouseholdRecurrence.none;
  }

  @override
  void dispose() {
    _mealNameCtrl.dispose();
    _mealTypeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showCustomDatePicker(context, _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final name = _mealNameCtrl.text.trim();
    if (name.isEmpty || _selectedMemberPk == null) return;

    final e = widget.existingAssignment;
    if (e != null) {
      await database.createOrUpdateCookingAssignment(
        e.toCompanion(true).copyWith(
              memberFk: Value(_selectedMemberPk!),
              mealName: Value(name),
              mealType: Value(_mealTypeCtrl.text.trim().isEmpty
                  ? null
                  : _mealTypeCtrl.text.trim()),
              note: Value(_noteCtrl.text.trim().isEmpty
                  ? null
                  : _noteCtrl.text.trim()),
              assignedDate: Value(_date),
              recurrence: Value(_recurrence),
            ),
      );
    } else {
      await database.createOrUpdateCookingAssignment(
        CookingAssignmentsCompanion(
          memberFk: Value(_selectedMemberPk!),
          mealName: Value(name),
          mealType: Value(_mealTypeCtrl.text.trim().isEmpty
              ? null
              : _mealTypeCtrl.text.trim()),
          note: Value(_noteCtrl.text.trim().isEmpty
              ? null
              : _noteCtrl.text.trim()),
          assignedDate: Value(_date),
          recurrence: Value(_recurrence),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAssignment != null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(isEditing ? 'Edit Assignment' : 'New Assignment',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
              onPressed: _save,
              child: Text(isEditing ? 'Save' : 'Add')),
        ],
      ),
      body: StreamBuilder<List<HouseholdMember>>(
        stream: database.watchAllHouseholdMembers(),
        builder: (context, snap) {
          final members = snap.data ?? [];
          return ListView(
            padding: const EdgeInsetsDirectional.all(16),
            children: [
              // Date picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: Text(DateFormat('EEEE, MMMM d, y').format(_date)),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              const SizedBox(height: 14),
              // Member picker
              DropdownButtonFormField<String>(
                value: _selectedMemberPk,
                decoration: const InputDecoration(
                  labelText: 'Cook',
                  border: OutlineInputBorder(),
                ),
                items: members
                    .map((m) => DropdownMenuItem(
                        value: m.memberPk, child: Text(m.displayName)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedMemberPk = v),
                hint: members.isEmpty
                    ? const Text('No members — add some first')
                    : const Text('Select member'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _mealNameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Meal name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _mealTypeCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Meal type (optional, e.g. Breakfast)',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 14),
              DropdownButtonFormField<HouseholdRecurrence>(
                value: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Repeat',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: HouseholdRecurrence.none,
                      child: Text('No repeat')),
                  DropdownMenuItem(
                      value: HouseholdRecurrence.daily,
                      child: Text('Daily')),
                  DropdownMenuItem(
                      value: HouseholdRecurrence.weekly,
                      child: Text('Weekly')),
                  DropdownMenuItem(
                      value: HouseholdRecurrence.monthly,
                      child: Text('Monthly')),
                ],
                onChanged: (v) =>
                    setState(() => _recurrence = v!),
              ),
            ],
          );
        },
      ),
    );
  }
}
