import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    controller.clear();
    await ref.read(campusProvider.notifier).sendMessage(widget.conversationId, text);
    if (!mounted || !scrollController.hasClients) return;
    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(campusProvider.select((state) => state.messages[widget.conversationId] ?? const []));
    final name = conversationNames[widget.conversationId] ?? widget.conversationId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: CampusColors.primary.withAlpha(22),
              child: Text(name.characters.first.toUpperCase(), style: const TextStyle(color: CampusColors.primary, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Text('Offline-ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
      ),
      body: ContentWidth(
        maxWidth: 820,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Align(
                    alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: message.isMine ? CampusColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(message.isMine ? 18 : 5),
                          bottomRight: Radius.circular(message.isMine ? 5 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(message.text, style: TextStyle(color: message.isMine ? Colors.white : null)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(message.sentAt),
                                style: TextStyle(fontSize: 10, color: message.isMine ? Colors.white70 : Theme.of(context).hintColor),
                              ),
                              if (message.isMine) ...[
                                const SizedBox(width: 4),
                                Icon(message.pending ? Icons.schedule_rounded : Icons.done_all_rounded, size: 13, color: Colors.white70),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline_rounded)),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 5,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(hintText: 'Type a message...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: send, icon: const Icon(Icons.send_rounded)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
