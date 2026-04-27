import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addGroceryItemPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

class GroceryListDetailPage extends StatefulWidget {
  const GroceryListDetailPage({required this.groceryList, super.key});

  final GroceryList groceryList;

  @override
  State<GroceryListDetailPage> createState() => _GroceryListDetailPageState();
}

class _GroceryListDetailPageState extends State<GroceryListDetailPage> {
  Future<void> _clearPurchased() async {
    await database.clearPurchasedItems(widget.groceryList.listPk);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FAB(
        tooltip: 'Add item',
        onTap: () => pushRoute(
            context,
            AddGroceryItemPage(
                listPk: widget.groceryList.listPk)),
        openPage: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: Text(widget.groceryList.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                onPressed: _clearPurchased,
                icon: const Icon(Icons.playlist_remove_rounded),
                tooltip: 'Clear purchased',
              ),
            ],
          ),
          StreamBuilder<List<GroceryItem>>(
            stream: database
                .watchGroceryItemsForList(widget.groceryList.listPk),
            builder: (context, snap) {
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_shopping_cart_rounded,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No items yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              // Group by category
              final Map<String, List<GroceryItem>> grouped = {};
              for (final item in items) {
                final cat = item.category ?? 'Other';
                grouped.putIfAbsent(cat, () => []).add(item);
              }
              final categories = grouped.keys.toList()..sort();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, sectionIndex) {
                    final cat = categories[sectionIndex];
                    final catItems = grouped[cat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16, 16, 16, 4),
                          child: TextFont(
                            text: cat,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            textColor: getColor(context, 'textLight'),
                          ),
                        ),
                        ...catItems.map((item) =>
                            _GroceryItemTile(item: item)),
                      ],
                    );
                  },
                  childCount: categories.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GroceryItemTile extends StatelessWidget {
  const _GroceryItemTile({required this.item});

  final GroceryItem item;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.itemPk),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => database.deleteGroceryItem(item.itemPk),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (val) => database.createOrUpdateGroceryItem(
            item.toCompanion(true).copyWith(
                  isPurchased: Value(val ?? false),
                ),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration:
                item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : null,
          ),
        ),
        subtitle: item.quantity != 1.0 || item.unit != null
            ? Text(
                '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}'
                '${item.unit != null ? " ${item.unit}" : ""}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: item.isRecurring
            ? const Icon(Icons.repeat_rounded, size: 16, color: Colors.grey)
            : null,
        onTap: () => pushRoute(
          context,
          AddGroceryItemPage(
            listPk: item.listFk,
            existingItem: item,
          ),
        ),
      ),
    );
  }
}
