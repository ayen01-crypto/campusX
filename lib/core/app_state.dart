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
    _persist();
  }

  void setDarkMode(bool enabled) {
    state = state.copyWith(darkMode: enabled);
    _persist();
  }

  void setUniversity(String university) {
    state = state.copyWith(university: university);
    _persist();
  }

  void setInterests(Set<String> interests) {
    state = state.copyWith(interests: interests);
    _persist();
  }

  void finishOnboarding() {
    state = state.copyWith(onboarded: true);
    _persist();
  }

  void signOut() {
    state = state.copyWith(onboarded: false);
    _persist();
  }

  void addListing(CampusListing listing) {
    state = state.copyWith(createdListings: [...state.createdListings, listing]);
    _persist();
  }

  Future<void> sendMessage(String conversationId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

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

    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!ref.mounted) return;

    final synced = _cloneMessages();
    final thread = synced[conversationId];
    if (thread == null) return;
    synced[conversationId] = thread
        .map((item) => item.id == message.id ? item.copyWith(pending: false) : item)
        .toList();
    state = state.copyWith(messages: synced);
    await _persist();
  }

  Map<String, List<ChatMessage>> _cloneMessages() => state.messages.map(
        (key, value) => MapEntry(key, List<ChatMessage>.of(value)),
      );

  Future<void> _persist() => ref.read(appStorageProvider).saveState(state);
}
