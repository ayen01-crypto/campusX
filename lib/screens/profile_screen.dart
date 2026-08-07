import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ContentWidth(
        maxWidth: 760,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [CampusColors.primaryDark, CampusColors.primary]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text('AG', style: TextStyle(color: CampusColors.primary, fontSize: 23, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                  const Text('CampusX Student', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(state.university, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _VerifiedChip(label: 'Student verified'),
                      _VerifiedChip(label: 'Phone verified'),
                      _VerifiedChip(label: 'Email verified'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Saved', value: '${state.savedIds.length}')),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Listings', value: '${state.createdListings.length}')),
                const SizedBox(width: 10),
                const Expanded(child: _StatCard(label: 'Rating', value: '4.9')),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  _MenuTile(icon: Icons.inventory_2_outlined, title: 'My listings', subtitle: '${state.createdListings.length} live', onTap: () {}),
                  const Divider(height: 1),
                  _MenuTile(icon: Icons.bookmark_outline_rounded, title: 'Saved', subtitle: 'Items, rooms and opportunities', onTap: () => context.push('/saved')),
                  const Divider(height: 1),
                  _MenuTile(icon: Icons.notifications_none_rounded, title: 'Notifications', subtitle: 'Updates that matter', onTap: () => context.push('/notifications')),
                  const Divider(height: 1),
                  _MenuTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Account, theme and privacy', onTap: () => context.push('/settings')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withAlpha(28), borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Icon(icon, color: CampusColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      );
}
