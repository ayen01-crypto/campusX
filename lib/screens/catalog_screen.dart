import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key, required this.kind});

  final ListingKind kind;

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campusProvider);
    final listings = [...state.createdListings, ...campusListings]
        .where((item) => item.kind == widget.kind)
        .where((item) {
          final needle = query.toLowerCase();
          return item.title.toLowerCase().contains(needle) ||
              item.subtitle.toLowerCase().contains(needle) ||
              item.location.toLowerCase().contains(needle);
        })
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.kind.emoji} ${widget.kind.title}')),
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.kind.title.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
                  ),
                ),
              ),
            ),
            if (listings.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing found',
                  message: 'Try a different search or create the first listing in this category.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 900 ? 3 : constraints.crossAxisExtent >= 600 ? 2 : 1;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 1.48 : .82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = listings[index];
                          return ListingCard(
                            listing: item,
                            horizontal: columns == 1,
                            saved: state.savedIds.contains(item.id),
                            onSaved: () => ref.read(campusProvider.notifier).toggleSaved(item.id),
                            onTap: () => context.push('/listing/${item.id}'),
                          );
                        },
                        childCount: listings.length,
                      ),
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
