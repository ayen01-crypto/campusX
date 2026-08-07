import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campusProvider);
    final allListings = [...state.createdListings, ...campusListings];
    final marketplace = allListings.where((item) => item.kind == ListingKind.marketplace).take(3).toList();
    final rentals = allListings.where((item) => item.kind == ListingKind.rental).take(2).toList();
    final deals = allListings.where((item) => item.kind == ListingKind.deal).take(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning 👋', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              state.university,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            TextField(
              readOnly: true,
              onTap: () => context.push('/catalog/marketplace'),
              decoration: const InputDecoration(
                hintText: 'Search CampusX',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Everything campus'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 820 ? 6 : constraints.maxWidth >= 520 ? 4 : 3;
                final width = (constraints.maxWidth - ((columns - 1) * 10)) / columns;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final kind in ListingKind.values)
                      SizedBox(
                        width: width,
                        height: 112,
                        child: FeatureTile(
                          kind: kind,
                          compact: true,
                          onTap: () => context.push('/catalog/${kind.name}'),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Marketplace picks',
              action: 'See all',
              onAction: () => context.push('/catalog/marketplace'),
            ),
            const SizedBox(height: 12),
            for (final item in marketplace) ...[
              ListingCard(
                listing: item,
                horizontal: true,
                saved: state.savedIds.contains(item.id),
                onSaved: () => ref.read(campusProvider.notifier).toggleSaved(item.id),
                onTap: () => context.push('/listing/${item.id}'),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Rooms near campus',
              action: 'Explore',
              onAction: () => context.push('/catalog/rental'),
            ),
            const SizedBox(height: 12),
            for (final item in rentals) ...[
              ListingCard(
                listing: item,
                horizontal: true,
                saved: state.savedIds.contains(item.id),
                onSaved: () => ref.read(campusProvider.notifier).toggleSaved(item.id),
                onTap: () => context.push('/listing/${item.id}'),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 18),
            SectionHeader(
              title: 'Student deals',
              action: 'View deals',
              onAction: () => context.push('/catalog/deal'),
            ),
            const SizedBox(height: 12),
            for (final item in deals) ...[
              ListingCard(
                listing: item,
                horizontal: true,
                saved: state.savedIds.contains(item.id),
                onSaved: () => ref.read(campusProvider.notifier).toggleSaved(item.id),
                onTap: () => context.push('/listing/${item.id}'),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
