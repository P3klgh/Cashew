import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/groceryListDetailPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/maintenanceDueBadge.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GroceryListsPage extends StatefulWidget {
  const GroceryListsPage({super.key});

  @override
  State<GroceryListsPage> createState() => _GroceryListsPageState();
}

class _GroceryListsPageState extends State<GroceryListsPage> {
  Future<void> _createList() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'List name'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final currentOrder = await database.watchGroceryLists().first;
    await database.createOrUpdateGroceryList(GroceryListsCompanion(
      name: Value(name),
      order: Value(currentOrder.length),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      floatingActionButton: FAB(
        tooltip: 'New list',
        onTap: _createList,
        openPage: const SizedBox.shrink(),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: const Text('Grocery Lists',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<List<GroceryList>>(
            stream: database.watchGroceryLists(),
            builder: (context, snap) {
              final lists = snap.data ?? [];
              if (lists.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No grocery lists yet',
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
                        _GroceryListCard(list: lists[index]),
                    childCount: lists.length,
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

class _GroceryListCard extends StatelessWidget {
  const _GroceryListCard({required this.list});

  final GroceryList list;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 10),
      child: Tappable(
        borderRadius: 16,
        color: Theme.of(context).colorScheme.surfaceVariant,
        onTap: () => pushRoute(
            context, GroceryListDetailPage(groceryList: list)),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_cart_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                        text: list.name,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                    StreamBuilder<List<GroceryItem>>(
                      stream:
                          database.watchGroceryItemsForList(list.listPk),
                      builder: (ctx, snap) {
                        final items = snap.data ?? [];
                        final remaining = items
                            .where((i) => !i.isPurchased)
                            .length;
                        return TextFont(
                          text: items.isEmpty
                              ? 'Empty'
                              : '$remaining of ${items.length} remaining',
                          fontSize: 12,
                          textColor: getColor(context, 'textLight'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) async {
                  if (val == 'archive') {
                    await database.createOrUpdateGroceryList(
                      list.toCompanion(true).copyWith(
                            isArchived: const Value(true),
                          ),
                    );
                  } else if (val == 'delete') {
                    await database.deleteGroceryList(list.listPk);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'archive', child: Text('Archive')),
                  const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red))),
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
