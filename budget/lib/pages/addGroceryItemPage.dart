import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

const List<String> _kCommonCategories = [
  'Produce',
  'Dairy',
  'Meat & Seafood',
  'Bakery',
  'Pantry',
  'Frozen',
  'Beverages',
  'Snacks',
  'Cleaning',
  'Personal Care',
  'Other',
];

class AddGroceryItemPage extends StatefulWidget {
  const AddGroceryItemPage({
    required this.listPk,
    this.existingItem,
    super.key,
  });

  final String listPk;
  final GroceryItem? existingItem;

  @override
  State<AddGroceryItemPage> createState() => _AddGroceryItemPageState();
}

class _AddGroceryItemPageState extends State<AddGroceryItemPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _unitCtrl;
  String? _category;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existingItem;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _quantityCtrl =
        TextEditingController(text: e != null ? '${e.quantity}' : '1');
    _unitCtrl = TextEditingController(text: e?.unit ?? '');
    _category = e?.category;
    _isRecurring = e?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final quantity = double.tryParse(_quantityCtrl.text) ?? 1.0;
    final unit = _unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim();

    final existing = widget.existingItem;
    if (existing != null) {
      await database.createOrUpdateGroceryItem(
        existing.toCompanion(true).copyWith(
              name: Value(name),
              category: Value(_category),
              quantity: Value(quantity),
              unit: Value(unit),
              isRecurring: Value(_isRecurring),
            ),
      );
    } else {
      final currentItems =
          await database.watchGroceryItemsForList(widget.listPk).first;
      await database.createOrUpdateGroceryItem(GroceryItemsCompanion(
        listFk: Value(widget.listPk),
        name: Value(name),
        category: Value(_category),
        quantity: Value(quantity),
        unit: Value(unit),
        isRecurring: Value(_isRecurring),
        order: Value(currentItems.length),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: Text(isEditing ? 'Edit Item' : 'Add Item',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: !isEditing,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Item name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _unitCtrl,
                  textCapitalization: TextCapitalization.none,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _kCommonCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _category = val),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _isRecurring,
            onChanged: (val) => setState(() => _isRecurring = val),
            title: const Text('Recurring item'),
            subtitle: const Text('Auto-add to new lists'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
