import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final all = [...state.createdListings, ...campusListings];
    final saved = all.where((item) => state.savedIds.contains(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ContentWidth(
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
                    onSaved: () => ref.read(campusProvider.notifier).toggleSaved(item.id),
                    onTap: () => context.push('/listing/${item.id}'),
                  );
                },
              ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const notifications = [
      ('💬', 'Sarah sent you a message', '2 min ago'),
      ('🏠', 'New room matching your budget', '15 min ago'),
      ('👀', 'Your listing is getting views', '25 min ago'),
      ('🤝', 'John saved your marketplace listing', '1 hr ago'),
      ('🏷️', 'Campus Bites posted a student deal', '2 hrs ago'),
      ('✅', 'Your listing was approved', 'Yesterday'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ContentWidth(
        maxWidth: 760,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = notifications[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: CampusColors.primary.withAlpha(18),
                child: Text(item.$1),
              ),
              title: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(item.$3),
            );
          },
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
                  const ListTile(
                    leading: Icon(Icons.person_outline_rounded),
                    title: Text('Account', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Profile, email and phone'),
                    trailing: Icon(Icons.chevron_right_rounded),
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
                    subtitle: Text('Version 0.1.0'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(campusProvider.notifier).signOut();
                context.go('/welcome');
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
