import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final ids = state.messages.keys.toList();

    return ContentWidth(
      maxWidth: 820,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Search messages', prefixIcon: Icon(Icons.search_rounded)),
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: CampusColors.success.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt_outlined, color: CampusColors.success, size: 20),
                      SizedBox(width: 8),
                      Expanded(child: Text('Offline-ready: messages are saved locally and sync when delivery is available.')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: ids.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final id = ids[index];
                final messages = state.messages[id] ?? const [];
                final last = messages.isEmpty ? null : messages.last;
                final name = conversationNames[id] ?? id;
                return ListTile(
                  onTap: () => context.push('/chat/$id'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: CampusColors.primary.withAlpha(22),
                    child: Text(name.characters.first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: CampusColors.primary)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(last?.text ?? 'Start a conversation', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    last == null ? '' : DateFormat('HH:mm').format(last.sentAt),
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
