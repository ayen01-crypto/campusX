import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/account_api.dart';
import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? remoteProfile;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null || loading) return;
    if (mounted) setState(() => loading = true);
    try {
      final profile = await ref.read(campusAccountApiProvider).profile(user.id);
      if (mounted) setState(() => remoteProfile = profile);
    } catch (_) {
      // The locally restored authenticated profile remains available offline.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campusProvider);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = user?.name ?? 'CampusX Student';
    final university = user?.universityName ?? state.university;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
    final reputation = remoteProfile?['reputation'] is Map
        ? Map<String, dynamic>.from(remoteProfile!['reputation'] as Map)
        : const <String, dynamic>{};
    final remoteListings = remoteProfile?['listings'] as List<dynamic>?;
    final listingCount = remoteListings?.length ?? state.createdListings.length;
    final rating = (reputation['rating'] as num?)?.toDouble();
    final reviewCount = (reputation['reviews'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: ContentWidth(
          maxWidth: 760,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CampusColors.primaryDark, CampusColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      foregroundImage: user?.avatarUrl == null ? null : NetworkImage(user!.avatarUrl!),
                      child: user?.avatarUrl == null
                          ? Text(
                              initials.isEmpty ? 'CX' : initials,
                              style: const TextStyle(
                                color: CampusColors.primary,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(university, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (user?.verified == true) const _VerifiedChip(label: 'CampusX verified'),
                        if (user != null) const _VerifiedChip(label: 'Email verified'),
                        if (!auth.authenticated) const _VerifiedChip(label: 'Offline profile'),
                      ],
                    ),
                    if (loading) ...[
                      const SizedBox(height: 12),
                      const SizedBox(
                        width: 110,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Saved', value: '${state.savedIds.length}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Listings', value: '$listingCount')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: reviewCount == 1 ? '1 review' : '$reviewCount reviews',
                      value: rating == null || reviewCount == 0 ? '—' : rating.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'My listings',
                      subtitle: '$listingCount visible',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved',
                      subtitle: 'Items, rooms and opportunities',
                      onTap: () => context.push('/saved'),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Updates that matter',
                      onTap: () => context.push('/notifications'),
                    ),
                    const Divider(height: 1),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Account, theme and privacy',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
        ),
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
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
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
