import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/account_api.dart';
import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/campus_api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  List<CampusListing> remoteSaved = const [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    if (!ref.read(authProvider).authenticated || loading) return;
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final items = await ref.read(campusApiProvider).savedListings();
      final controller = ref.read(campusProvider.notifier);
      for (final item in items) {
        controller.setSaved(item.id, true);
      }
      if (mounted) setState(() => remoteSaved = items);
    } catch (loadError) {
      if (mounted) setState(() => error = '$loadError');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _remove(CampusListing item) async {
    ref.read(campusProvider.notifier).setSaved(item.id, false);
    setState(() => remoteSaved = remoteSaved.where((value) => value.id != item.id).toList());
    if (!ref.read(authProvider).authenticated) return;
    try {
      final saved = await ref.read(campusApiProvider).toggleSaved(item.id);
      ref.read(campusProvider.notifier).setSaved(item.id, saved);
    } catch (_) {
      // Local state stays useful offline.
    }
  }

  List<CampusListing> _items(CampusState state) {
    final all = <CampusListing>[
      ...remoteSaved,
      ...state.createdListings,
      ...campusListings,
    ];
    final byId = <String, CampusListing>{for (final item in all) item.id: item};
    return byId.values.where((item) => state.savedIds.contains(item.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campusProvider);
    final saved = _items(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        actions: [
          IconButton(
            tooltip: 'Sync saved items',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Showing saved items available on this device.')),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            Expanded(
              child: saved.isEmpty
                  ? const EmptyState(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Nothing saved yet',
                      message: 'Bookmark useful listings, rooms, tutors, events and deals to keep them here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = saved[index];
                        return ListingCard(
                          listing: item,
                          horizontal: true,
                          saved: true,
                          onSaved: () => _remove(item),
                          onTap: () => context.push('/listing/${item.id}', extra: item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = const [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    if (!ref.read(authProvider).authenticated || loading) return;
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final items = await ref.read(campusAccountApiProvider).notifications();
      if (mounted) setState(() => notifications = items);
    } catch (loadError) {
      if (mounted) setState(() => error = '$loadError');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['readAt'] != null) return;
    final id = item['id'] as String?;
    if (id == null) return;
    try {
      await ref.read(campusAccountApiProvider).markNotificationRead(id);
      if (!mounted) return;
      setState(() {
        notifications = notifications
            .map(
              (entry) => entry['id'] == id
                  ? {...entry, 'readAt': DateTime.now().toIso8601String()}
                  : entry,
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(campusAccountApiProvider).markAllNotificationsRead();
      if (!mounted) return;
      final now = DateTime.now().toIso8601String();
      setState(() {
        notifications = notifications.map((item) => {...item, 'readAt': now}).toList();
      });
    } catch (loadError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$loadError')));
      }
    }
  }

  String _emoji(String? type) => switch (type) {
        'MESSAGE' => '💬',
        'LISTING' => '🛍️',
        'BOOKING' => '📅',
        'PAYMENT' => '💳',
        'TICKET' => '🎟️',
        'APPLICATION' => '💼',
        'DEAL' => '🏷️',
        _ => '🔔',
      };

  String _relativeTime(String? raw) {
    final time = DateTime.tryParse(raw ?? '')?.toLocal();
    if (time == null) return '';
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((item) => item['readAt'] == null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markAllRead, child: const Text('Read all')),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        maxWidth: 760,
        child: Column(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Notifications could not sync. Pull them again when CampusX reconnects.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: notifications.isEmpty && !loading
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'You are all caught up',
                      message: 'Messages, bookings, payments, applications and deal updates will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        final read = item['readAt'] != null;
                        return ListTile(
                          onTap: () => _markRead(item),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: CampusColors.primary.withAlpha(read ? 10 : 24),
                            child: Text(_emoji(item['type'] as String?)),
                          ),
                          title: Text(
                            item['title'] as String? ?? 'CampusX update',
                            style: TextStyle(fontWeight: read ? FontWeight.w600 : FontWeight.w900),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['body'] as String? ?? ''),
                              const SizedBox(height: 3),
                              Text(
                                _relativeTime(item['createdAt'] as String?),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: read
                              ? null
                              : const Icon(Icons.circle, size: 9, color: CampusColors.primary),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ContentWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(auth.user?.email ?? 'Offline account'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.shield_outlined),
                    title: Text('Privacy & safety', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Blocked users, reports and visibility'),
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: state.darkMode,
                    onChanged: (value) => ref.read(campusProvider.notifier).setDarkMode(value),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark mode', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Use a darker CampusX appearance'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('University', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(state.university),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/university'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.language_rounded),
                    title: Text('Language', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('English'),
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline_rounded),
                    title: Text('About CampusX', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Version 0.2.0'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                ref.read(campusProvider.notifier).signOut();
                if (context.mounted) context.go('/welcome');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
