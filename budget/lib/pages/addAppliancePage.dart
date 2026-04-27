import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

class AddAppliancePage extends StatefulWidget {
  const AddAppliancePage({this.existingAppliance, super.key});

  final Appliance? existingAppliance;

  @override
  State<AddAppliancePage> createState() => _AddAppliancePageState();
}

class _AddAppliancePageState extends State<AddAppliancePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existingAppliance;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    final e = widget.existingAppliance;
    if (e != null) {
      await database.createOrUpdateAppliance(
        e.toCompanion(true).copyWith(
              name: Value(name),
              note: Value(note),
            ),
      );
    } else {
      final current = await database.watchAllAppliances().first;
      await database.createOrUpdateAppliance(AppliancesCompanion(
        name: Value(name),
        note: Value(note),
        order: Value(current.length),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAppliance != null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(isEditing ? 'Edit Appliance' : 'New Appliance',
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
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Appliance name',
              hintText: 'e.g. Washing Machine',
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
              hintText: 'Model number, location, etc.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
