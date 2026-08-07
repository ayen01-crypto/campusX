import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../widgets/common.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final kinds = ListingKind.values.where((kind) => kind.title.toLowerCase().contains(query.toLowerCase())).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explore CampusX', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Everything useful around your university, without the noise of another social feed.'),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(hintText: 'Search categories', prefixIcon: Icon(Icons.search_rounded)),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 760 ? 3 : constraints.maxWidth >= 520 ? 2 : 1;
                final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final kind in kinds)
                      SizedBox(
                        width: width,
                        height: 104,
                        child: FeatureTile(kind: kind, onTap: () => context.push('/catalog/${kind.name}')),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
