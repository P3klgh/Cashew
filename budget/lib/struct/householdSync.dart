import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/struct/supabaseGlobal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

RealtimeChannel? _householdChannel;

String get _householdId => appStateSettings['householdId'] ?? '';

bool get _canSync =>
    isSupabaseConfigured && _householdId.isNotEmpty;

// ─── Push (local → Supabase) ─────────────────────────────────────────────────

Future<void> pushHouseholdData() async {
  if (!_canSync) return;
  try {
    final members = await database.watchAllHouseholdMembers().first;
    if (members.isNotEmpty) {
      await supabaseClient.from('household_members').upsert(
            members.map((m) => _memberToMap(m)).toList(),
          );
    }

    final lists = await database.watchGroceryLists().first;
    if (lists.isNotEmpty) {
      await supabaseClient.from('grocery_lists').upsert(
            lists.map((l) => _groceryListToMap(l)).toList(),
          );
    }

    final appliances = await database.watchAllAppliances().first;
    if (appliances.isNotEmpty) {
      await supabaseClient.from('appliances').upsert(
            appliances.map((a) => _applianceToMap(a)).toList(),
          );
    }
  } catch (e) {
    print('householdSync.pushHouseholdData error: $e');
  }
}

// ─── Pull (Supabase → local) ─────────────────────────────────────────────────

Future<void> pullHouseholdData() async {
  if (!_canSync) return;
  try {
    final membersRaw = await supabaseClient
        .from('household_members')
        .select()
        .eq('household_id', _householdId);
    for (final row in (membersRaw as List)) {
      await database.createOrUpdateHouseholdMember(
          _memberFromMap(row as Map<String, dynamic>));
    }

    final listsRaw = await supabaseClient
        .from('grocery_lists')
        .select()
        .eq('household_id', _householdId);
    for (final row in (listsRaw as List)) {
      await database.createOrUpdateGroceryList(
          _groceryListFromMap(row as Map<String, dynamic>));
    }

    final appliancesRaw = await supabaseClient
        .from('appliances')
        .select()
        .eq('household_id', _householdId);
    for (final row in (appliancesRaw as List)) {
      await database.createOrUpdateAppliance(
          _applianceFromMap(row as Map<String, dynamic>));
    }
  } catch (e) {
    print('householdSync.pullHouseholdData error: $e');
  }
}

// ─── Realtime subscription ────────────────────────────────────────────────────

void subscribeToHouseholdChanges() {
  if (!_canSync) return;
  _householdChannel = supabaseClient
      .channel('household:$_householdId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'household_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'household_id',
          value: _householdId,
        ),
        callback: (_) => pullHouseholdData(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'grocery_lists',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'household_id',
          value: _householdId,
        ),
        callback: (_) => pullHouseholdData(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'appliances',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'household_id',
          value: _householdId,
        ),
        callback: (_) => pullHouseholdData(),
      )
      .subscribe();
}

void unsubscribeFromHouseholdChanges() {
  _householdChannel?.unsubscribe();
  _householdChannel = null;
}

// ─── Serialization helpers ────────────────────────────────────────────────────

Map<String, dynamic> _memberToMap(HouseholdMember m) => {
      'member_pk': m.memberPk,
      'household_id': _householdId,
      'supabase_uid': m.supabaseUid,
      'display_name': m.displayName,
      'email': m.email,
      'colour': m.colour,
      'order': m.order,
      'date_created': m.dateCreated.toIso8601String(),
    };

HouseholdMembersCompanion _memberFromMap(Map<String, dynamic> row) =>
    HouseholdMembersCompanion(
      memberPk: Value(row['member_pk'] as String),
      supabaseUid: Value(row['supabase_uid'] as String),
      displayName: Value(row['display_name'] as String),
      email: Value(row['email'] as String),
      colour: Value(row['colour'] as String?),
      order: Value(row['order'] as int? ?? 0),
      dateCreated: Value(DateTime.parse(row['date_created'] as String)),
    );

Map<String, dynamic> _groceryListToMap(GroceryList l) => {
      'list_pk': l.listPk,
      'household_id': _householdId,
      'name': l.name,
      'colour': l.colour,
      'is_archived': l.isArchived,
      'order': l.order,
      'date_created': l.dateCreated.toIso8601String(),
    };

GroceryListsCompanion _groceryListFromMap(Map<String, dynamic> row) =>
    GroceryListsCompanion(
      listPk: Value(row['list_pk'] as String),
      name: Value(row['name'] as String),
      colour: Value(row['colour'] as String?),
      isArchived: Value(row['is_archived'] as bool? ?? false),
      order: Value(row['order'] as int? ?? 0),
      dateCreated: Value(DateTime.parse(row['date_created'] as String)),
    );

Map<String, dynamic> _applianceToMap(Appliance a) => {
      'appliance_pk': a.appliancePk,
      'household_id': _householdId,
      'name': a.name,
      'icon_name': a.iconName,
      'note': a.note,
      'order': a.order,
      'date_created': a.dateCreated.toIso8601String(),
    };

AppliancesCompanion _applianceFromMap(Map<String, dynamic> row) =>
    AppliancesCompanion(
      appliancePk: Value(row['appliance_pk'] as String),
      name: Value(row['name'] as String),
      iconName: Value(row['icon_name'] as String?),
      note: Value(row['note'] as String?),
      order: Value(row['order'] as int? ?? 0),
      dateCreated: Value(DateTime.parse(row['date_created'] as String)),
    );
