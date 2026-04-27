import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/supabaseGlobal.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HouseholdMembersPage extends StatefulWidget {
  const HouseholdMembersPage({super.key});

  @override
  State<HouseholdMembersPage> createState() => _HouseholdMembersPageState();
}

class _HouseholdMembersPageState extends State<HouseholdMembersPage> {
  bool _signingIn = false;

  Future<void> _addCurrentUser() async {
    if (!isSupabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supabase is not configured.')),
      );
      return;
    }

    setState(() => _signingIn = true);
    try {
      User? user = currentSupabaseUser;
      if (user == null) {
        // Trigger OAuth 2.1 PKCE sign-in with Google
        await signInWithOAuth(OAuthProvider.google);
        user = currentSupabaseUser;
      }
      if (user == null) return;

      final existing = await database.watchAllHouseholdMembers().first;
      if (existing.any((m) => m.supabaseUid == user!.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are already a member.')),
          );
        }
        return;
      }

      await database.createOrUpdateHouseholdMember(
        HouseholdMembersCompanion(
          supabaseUid: Value(user.id),
          displayName: Value(
              user.userMetadata?['full_name'] as String? ??
                  user.email ??
                  'Member'),
          email: Value(user.email ?? ''),
          order: Value(existing.length),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _inviteByEmail() async {
    if (!isSupabaseConfigured) return;
    final emailCtrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Member'),
        content: TextField(
          controller: emailCtrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration:
              const InputDecoration(hintText: 'Email address'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, emailCtrl.text.trim()),
              child: const Text('Invite')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;

    try {
      await signInWithMagicLink(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Magic link sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Household Members',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded),
            tooltip: 'Invite by email',
            onPressed: _inviteByEmail,
          ),
        ],
      ),
      body: StreamBuilder<List<HouseholdMember>>(
        stream: database.watchAllHouseholdMembers(),
        builder: (context, snap) {
          final members = snap.data ?? [];
          return Column(
            children: [
              Expanded(
                child: members.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No members yet',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: members.length,
                        itemBuilder: (context, index) =>
                            _MemberTile(member: members[index]),
                      ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signingIn ? null : _addCurrentUser,
                    icon: _signingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add_rounded),
                    label: const Text('Sign in & add me'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final HouseholdMember member;

  @override
  Widget build(BuildContext context) {
    Color avatarColor = Theme.of(context).colorScheme.primary;
    if (member.colour != null && member.colour!.isNotEmpty) {
      try {
        avatarColor =
            Color(int.parse('FF${member.colour}', radix: 16));
      } catch (_) {}
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor.withOpacity(0.2),
        child: Text(
          member.displayName.isNotEmpty
              ? member.displayName[0].toUpperCase()
              : '?',
          style: TextStyle(
              color: avatarColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(member.displayName),
      subtitle: Text(member.email,
          style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
        onPressed: () =>
            database.deleteHouseholdMember(member.memberPk),
      ),
    );
  }
}
