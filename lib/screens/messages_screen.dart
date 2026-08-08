import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/campus_api.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class _ConversationRow {
  const _ConversationRow({
    required this.id,
    required this.name,
    required this.preview,
    this.sentAt,
    this.unreadCount = 0,
    this.remote = false,
  });

  final String id;
  final String name;
  final String preview;
  final DateTime? sentAt;
  final int unreadCount;
  final bool remote;
}

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  bool loading = false;
  String? error;
  String query = '';
  List<_ConversationRow> remoteRows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null || loading) return;

    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final conversations = await ref.read(campusApiProvider).conversations();
      final rows = conversations.map((conversation) {
        final rawMembers = conversation['members'] as List<dynamic>? ?? const [];
        String name = 'CampusX member';
        for (final raw in rawMembers) {
          final member = Map<String, dynamic>.from(raw as Map);
          final rawUser = member['user'];
          if (rawUser is Map) {
            final other = Map<String, dynamic>.from(rawUser);
            if (other['id'] != user.id) {
              name = other['name'] as String? ?? name;
              break;
            }
          }
        }

        final rawMessages = conversation['messages'] as List<dynamic>? ?? const [];
        Map<String, dynamic>? last;
        if (rawMessages.isNotEmpty) {
          last = Map<String, dynamic>.from(rawMessages.first as Map);
        }
        final listing = conversation['listing'] is Map
            ? Map<String, dynamic>.from(conversation['listing'] as Map)
            : const <String, dynamic>{};

        return _ConversationRow(
          id: conversation['id'] as String,
          name: name,
          preview: last?['body'] as String? ??
              (listing['title'] == null ? 'Start a conversation' : 'About ${listing['title']}'),
          sentAt: DateTime.tryParse(last?['sentAt'] as String? ?? ''),
          unreadCount: (conversation['unreadCount'] as num?)?.toInt() ?? 0,
          remote: true,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        remoteRows = rows;
        loading = false;
      });
    } catch (loadError) {
      if (!mounted) return;
      setState(() {
        error = '$loadError';
        loading = false;
      });
    }
  }

  List<_ConversationRow> _rows() {
    final state = ref.read(campusProvider);
    final byId = <String, _ConversationRow>{for (final row in remoteRows) row.id: row};

    for (final entry in state.messages.entries) {
      final messages = entry.value;
      final last = messages.isEmpty ? null : messages.last;
      byId.putIfAbsent(
        entry.key,
        () => _ConversationRow(
          id: entry.key,
          name: conversationNames[entry.key] ?? 'CampusX chat',
          preview: last?.text ?? 'Start a conversation',
          sentAt: last?.sentAt,
        ),
      );
    }

    final needle = query.trim().toLowerCase();
    final rows = byId.values
        .where(
          (row) => needle.isEmpty ||
              row.name.toLowerCase().contains(needle) ||
              row.preview.toLowerCase().contains(needle),
        )
        .toList()
      ..sort((a, b) {
        final aTime = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(campusProvider);
    ref.watch(authProvider);
    final rows = _rows();

    return ContentWidth(
      maxWidth: 820,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Search messages',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Sync conversations',
                      onPressed: loading ? null : _load,
                      icon: const Icon(Icons.sync_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: CampusColors.success.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_bolt_outlined,
                        color: CampusColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Offline-ready: messages stay on this device until server delivery is available.',
                        ),
                      ),
                      if (loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Server conversations are unavailable; showing local chats.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: rows.isEmpty
                ? const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No conversations yet',
                    message: 'Open a marketplace, rental, roommate or business listing to start chatting.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return ListTile(
                        onTap: () => context.push('/chat/${row.id}'),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: CampusColors.primary.withAlpha(22),
                          child: Text(
                            row.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: CampusColors.primary,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (row.unreadCount > 0)
                              Badge(label: Text('${row.unreadCount}')),
                          ],
                        ),
                        subtitle: Text(
                          row.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          row.sentAt == null ? '' : DateFormat('HH:mm').format(row.sentAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
