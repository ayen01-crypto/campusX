import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/campus_api.dart';
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
  bool loading = true;
  String? loadError;
  List<CampusListing> remoteListings = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      remoteListings = const [];
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final state = ref.read(campusProvider);
      final items = await ref.read(campusApiProvider).listings(
            widget.kind,
            universityId: state.universityId,
          );
      if (!mounted) return;
      setState(() {
        remoteListings = items;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = '$error';
        loading = false;
      });
    }
  }

  Future<void> _toggleSaved(CampusListing item) async {
    final controller = ref.read(campusProvider.notifier);
    controller.toggleSaved(item.id);

    if (!ref.read(authProvider).authenticated) return;
    try {
      final saved = await ref.read(campusApiProvider).toggleSaved(item.id);
      controller.setSaved(item.id, saved);
    } catch (_) {
      // The optimistic local state remains useful offline and can be reconciled later.
    }
  }

  List<CampusListing> _visibleListings() {
    final state = ref.read(campusProvider);
    final fallback = campusListings.where((item) => item.kind == widget.kind);
    final candidates = <CampusListing>[
      ...state.createdListings.where((item) => item.kind == widget.kind),
      if (remoteListings.isNotEmpty) ...remoteListings else ...fallback,
    ];

    final deduped = <String, CampusListing>{};
    for (final item in candidates) {
      deduped[item.id] = item;
    }

    final needle = query.trim().toLowerCase();
    return deduped.values.where((item) {
      if (needle.isEmpty) return true;
      return item.title.toLowerCase().contains(needle) ||
          item.subtitle.toLowerCase().contains(needle) ||
          item.location.toLowerCase().contains(needle) ||
          item.description.toLowerCase().contains(needle);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campusProvider);
    final listings = _visibleListings();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kind.emoji} ${widget.kind.title}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.kind.title.toLowerCase()}',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ),
                    if (loading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    if (loadError != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.cloud_off_rounded),
                          title: const Text('Offline catalog'),
                          subtitle: const Text(
                            'CampusX is showing locally available results until the server reconnects.',
                          ),
                          trailing: TextButton(onPressed: _load, child: const Text('Retry')),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (listings.isEmpty && !loading)
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
                    final columns = constraints.crossAxisExtent >= 900
                        ? 3
                        : constraints.crossAxisExtent >= 600
                            ? 2
                            : 1;
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
                            onSaved: () => _toggleSaved(item),
                            onTap: () => context.push('/listing/${item.id}', extra: item),
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
