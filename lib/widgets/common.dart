import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models.dart';
import '../core/theme.dart';

final _currency = NumberFormat.currency(locale: 'en_UG', symbol: 'UGX ', decimalDigits: 0);

String money(int? amount) => amount == null ? 'Free / Contact' : _currency.format(amount);

class CampusXMark extends StatelessWidget {
  const CampusXMark({super.key, this.size = 54, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: CampusColors.primary,
            borderRadius: BorderRadius.circular(size * .3),
          ),
          child: Icon(Icons.school_rounded, color: Colors.white, size: size * .56),
        ),
        if (showName) ...[
          const SizedBox(width: 12),
          Text(
            'CampusX',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
          ),
        ],
      ],
    );
  }
}

class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!),
          ),
      ],
    );
  }
}

class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.kind,
    required this.onTap,
    this.compact = false,
  });

  final ListingKind kind;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 18),
          child: compact
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(kind.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 8),
                    Text(
                      kind.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: CampusColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(kind.emoji, style: const TextStyle(fontSize: 25)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kind.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(_featureDescription(kind), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
        ),
      ),
    );
  }
}

String _featureDescription(ListingKind kind) => switch (kind) {
      ListingKind.marketplace => 'Buy and sell around campus',
      ListingKind.rental => 'Rooms, hostels and apartments',
      ListingKind.roommate => 'Find compatible roommates',
      ListingKind.tutor => 'Book trusted student tutors',
      ListingKind.internship => 'Discover career opportunities',
      ListingKind.event => 'Find events and get tickets',
      ListingKind.service => 'Book practical campus services',
      ListingKind.business => 'Discover nearby businesses',
      ListingKind.deal => 'Unlock verified student offers',
    };

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.saved,
    required this.onSaved,
    this.horizontal = false,
  });

  final CampusListing listing;
  final VoidCallback onTap;
  final bool saved;
  final VoidCallback onSaved;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final visual = Container(
      width: horizontal ? 108 : double.infinity,
      height: horizontal ? 110 : 138,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CampusColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(listing.emoji, style: TextStyle(fontSize: horizontal ? 46 : 58)),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                listing.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onSaved,
              icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            ),
          ],
        ),
        Text(
          listing.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (listing.price != null)
          Text(
            money(listing.price),
            style: const TextStyle(color: CampusColors.primary, fontWeight: FontWeight.w900),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 15),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                listing.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (listing.rating > 0) ...[
              const Icon(Icons.star_rounded, size: 16, color: CampusColors.accent),
              Text(listing.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ],
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: horizontal
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [visual, const SizedBox(width: 12), Expanded(child: details)],
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [visual, const SizedBox(height: 10), details]),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 58, color: CampusColors.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
