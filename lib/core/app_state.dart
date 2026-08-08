import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/mock_data.dart';
import 'app_storage.dart';
import 'models.dart';

final appStorageProvider = Provider<AppStorage>((ref) {
  throw UnimplementedError('AppStorage must be overridden in main.dart');
});

final initialCampusStateProvider = Provider<CampusState>((ref) => CampusState.initial());

final campusProvider = NotifierProvider<CampusController, CampusState>(CampusController.new);

class CampusController extends Notifier<CampusState> {
  final _uuid = const Uuid();

  @override
  CampusState build() {
    final initial = ref.watch(initialCampusStateProvider);
    if (initial.messages.isNotEmpty) return initial;
    return initial.copyWith(
      messages: starterMessages.map((key, value) => MapEntry(key, List.of(value))),
    );
  }

  void toggleSaved(String id) {
    final next = Set<String>.of(state.savedIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(savedIds: next);
    unawaited(_persist());
  }

  void setSaved(String id, bool saved) {
    final next = Set<String>.of(state.savedIds);
    saved ? next.add(id) : next.remove(id);
    state = state.copyWith(savedIds: next);
    unawaited(_persist());
  }

  void setDarkMode(bool enabled) {
    state = state.copyWith(darkMode: enabled);
    unawaited(_persist());
  }

  void setUniversity(String university, {String? id}) {
    state = state.copyWith(university: university, universityId: id);
    unawaited(_persist());
  }

  void setInterests(Set<String> interests) {
    state = state.copyWith(interests: interests);
    unawaited(_persist());
  }

  void finishOnboarding() {
    state = state.copyWith(onboarded: true);
    unawaited(_persist());
  }

  void signOut() {
    state = state.copyWith(onboarded: false);
    unawaited(_persist());
  }

  void addListing(CampusListing listing) {
    state = state.copyWith(createdListings: [...state.createdListings, listing]);
    unawaited(_persist());
  }

  Future<ChatMessage?> queueMessage(String conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final message = ChatMessage(
      id: _uuid.v4(),
      text: trimmed,
      sentAt: DateTime.now(),
      isMine: true,
      pending: true,
    );

    final nextMessages = _cloneMessages();
    nextMessages.putIfAbsent(conversationId, () => <ChatMessage>[]).add(message);
    state = state.copyWith(messages: nextMessages);
    await _persist();
    return message;
  }

  Future<void> markMessageSynced(
    String conversationId,
    String localId,
    ChatMessage serverMessage,
  ) async {
    final next = _cloneMessages();
    final thread = next[conversationId];
    if (thread == null) return;
    next[conversationId] = thread
        .map(
          (message) => message.id == localId
              ? ChatMessage(
                  id: serverMessage.id,
                  text: serverMessage.text,
                  sentAt: serverMessage.sentAt,
                  isMine: true,
                  pending: false,
                )
              : message,
        )
        .toList();
    state = state.copyWith(messages: next);
    await _persist();
  }

  Future<void> mergeRemoteMessages(
    String conversationId,
    List<ChatMessage> remoteMessages,
  ) async {
    final next = _cloneMessages();
    final local = next[conversationId] ?? <ChatMessage>[];
    final byId = <String, ChatMessage>{
      for (final message in remoteMessages) message.id: message,
      for (final message in local)
        if (message.pending || !remoteMessages.any((remote) => remote.id == message.id))
          message.id: message,
    };
    final merged = byId.values.toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    next[conversationId] = merged;
    state = state.copyWith(messages: next);
    await _persist();
  }

  List<ChatMessage> pendingMessages(String conversationId) =>
      (state.messages[conversationId] ?? const []).where((message) => message.pending).toList();

  Map<String, List<ChatMessage>> _cloneMessages() => state.messages.map(
        (key, value) => MapEntry(key, List<ChatMessage>.of(value)),
      );

  Future<void> _persist() => ref.read(appStorageProvider).saveState(state);
}
