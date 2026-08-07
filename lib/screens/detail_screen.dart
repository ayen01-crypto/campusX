import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});

  final String id;

  CampusListing? _find(List<CampusListing> created) {
    for (final item in [...created, ...campusListings]) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final listing = _find(state.createdListings);
    if (listing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CampusX')),
        body: const EmptyState(icon: Icons.error_outline_rounded, title: 'Listing unavailable', message: 'This CampusX listing could not be found.'),
      );
    }
    final saved = state.savedIds.contains(listing.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.kind.title),
        actions: [
          IconButton(
            onPressed: () => ref.read(campusProvider.notifier).toggleSaved(listing.id),
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ContentWidth(
        maxWidth: 860,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Container(
              height: 280,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CampusColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(listing.emoji, style: const TextStyle(fontSize: 112)),
            ),
            const SizedBox(height: 20),
            if (listing.badge != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(label: Text(listing.badge!), avatar: const Icon(Icons.verified_rounded, size: 17)),
              ),
            const SizedBox(height: 8),
            Text(listing.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(listing.subtitle, style: Theme.of(context).textTheme.titleMedium),
            if (listing.price != null) ...[
              const SizedBox(height: 14),
              Text(money(listing.price), style: const TextStyle(color: CampusColors.primary, fontWeight: FontWeight.w900, fontSize: 22)),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(listing.location)),
                if (listing.rating > 0) ...[
                  const Icon(Icons.star_rounded, color: CampusColors.accent),
                  Text('${listing.rating.toStringAsFixed(1)} rating'),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(listing.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
            if (listing.details.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: listing.details.entries
                      .map(
                        (entry) => ListTile(
                          title: Text(entry.key),
                          trailing: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: CampusColors.primary.withAlpha(20),
                  child: Text(listing.owner.characters.first.toUpperCase(), style: const TextStyle(color: CampusColors.primary, fontWeight: FontWeight.w900)),
                ),
                title: Text(listing.owner, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Verified CampusX member'),
                trailing: const Icon(Icons.verified_rounded, color: CampusColors.primary),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: FilledButton.icon(
          onPressed: () => _performAction(context, listing),
          icon: Icon(_actionIcon(listing.kind)),
          label: Text(listing.kind.actionLabel),
        ),
      ),
    );
  }

  IconData _actionIcon(ListingKind kind) => switch (kind) {
        ListingKind.marketplace || ListingKind.rental || ListingKind.roommate || ListingKind.business => Icons.chat_bubble_outline_rounded,
        ListingKind.tutor || ListingKind.service => Icons.calendar_month_outlined,
        ListingKind.internship => Icons.send_rounded,
        ListingKind.event => Icons.confirmation_number_outlined,
        ListingKind.deal => Icons.local_offer_outlined,
      };

  void _performAction(BuildContext context, CampusListing listing) {
    final chatKinds = {ListingKind.marketplace, ListingKind.rental, ListingKind.roommate, ListingKind.business};
    if (chatKinds.contains(listing.kind)) {
      final conversation = switch (listing.kind) {
        ListingKind.rental => 'martin',
        ListingKind.business => 'campus-bites',
        ListingKind.roommate => 'john',
        _ => 'sarah',
      };
      context.push('/chat/$conversation');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.kind.actionLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('CampusX has prepared this ${listing.kind.title.toLowerCase()} action for ${listing.title}. Payment/API processing will plug into this exact flow.'),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${listing.kind.actionLabel} request saved.')));
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
