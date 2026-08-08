import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/campus_api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({
    super.key,
    required this.id,
    this.initialListing,
  });

  final String id;
  final CampusListing? initialListing;

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  CampusListing? listing;
  bool loading = false;
  bool actionBusy = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    listing = widget.initialListing ?? _findLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_refresh()));
  }

  CampusListing? _findLocal() {
    final created = ref.read(campusProvider).createdListings;
    for (final item in [...created, ...campusListings]) {
      if (item.id == widget.id) return item;
    }
    return null;
  }

  Future<void> _refresh() async {
    if (loading) return;
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }

    try {
      final remote = await ref.read(campusApiProvider).listing(widget.id);
      if (!mounted) return;
      setState(() => listing = remote);
    } catch (error) {
      if (mounted && listing == null) setState(() => loadError = '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleSaved() async {
    final item = listing;
    if (item == null) return;
    final controller = ref.read(campusProvider.notifier);
    controller.toggleSaved(item.id);

    if (!ref.read(authProvider).authenticated) return;
    try {
      final saved = await ref.read(campusApiProvider).toggleSaved(item.id);
      controller.setSaved(item.id, saved);
    } catch (_) {
      // Keep the local bookmark when offline; it remains useful on this device.
    }
  }

  Future<void> _performAction() async {
    final item = listing;
    if (item == null || actionBusy) return;

    final auth = ref.read(authProvider);
    if (!auth.authenticated) {
      if (mounted) context.go('/auth');
      return;
    }

    final chatKinds = {
      ListingKind.marketplace,
      ListingKind.rental,
      ListingKind.roommate,
      ListingKind.business,
    };

    if (chatKinds.contains(item.kind)) {
      if (item.ownerId == null) {
        _message('This offline listing has no server owner yet. Publish or refresh it first.');
        return;
      }
      if (item.ownerId == auth.user!.id) {
        _message('This is your own listing.');
        return;
      }

      setState(() => actionBusy = true);
      try {
        final conversationId = await ref.read(campusApiProvider).startConversation(
              participantId: item.ownerId!,
              listingId: item.id,
            );
        if (mounted) context.push('/chat/$conversationId');
      } catch (error) {
        _message('$error');
      } finally {
        if (mounted) setState(() => actionBusy = false);
      }
      return;
    }

    setState(() => actionBusy = true);
    try {
      final result = await ref.read(campusApiProvider).performListingAction(item.kind, item.id);
      if (!mounted) return;

      if (item.kind == ListingKind.event && result['paymentRequired'] == true) {
        final payment = result['payment'];
        if (payment is Map && payment['id'] is String) {
          await _showPaymentSheet(Map<String, dynamic>.from(payment));
        } else {
          _message('CampusX created the ticket payment request, but its payment reference is missing.');
        }
        return;
      }

      final successMessage = switch (item.kind) {
        ListingKind.tutor => 'Tutor booking request sent.',
        ListingKind.service => 'Service booking request sent.',
        ListingKind.internship => 'Internship application submitted.',
        ListingKind.event => 'Your ticket is ready.',
        ListingKind.deal => 'Student deal claimed. Your claim code is ready.',
        _ => '${item.kind.actionLabel} completed.',
      };
      _message(successMessage);
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  Future<void> _showPaymentSheet(Map<String, dynamic> payment) async {
    const allowMock = bool.fromEnvironment('ENABLE_MOCK_PAYMENTS', defaultValue: false);
    final paymentId = payment['id'] as String;
    final amount = (payment['amount'] as num?)?.toInt();
    final currency = payment['currency'] as String? ?? 'UGX';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete ticket payment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                amount == null
                    ? 'Payment reference: $paymentId'
                    : '$currency ${amount.toString()} • Reference $paymentId',
              ),
              const SizedBox(height: 14),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone_android_rounded),
                title: Text('MTN MoMo / Airtel Money'),
                subtitle: Text(
                  'The backend adapters are reserved for real provider credentials. CampusX will not fake a production payment.',
                ),
              ),
              if (allowMock) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(campusApiProvider).initiatePayment(
                            paymentId,
                            provider: 'MOCK',
                          );
                      await ref.read(campusApiProvider).confirmMockPayment(paymentId);
                      if (!mounted) return;
                      Navigator.of(sheetContext).pop();
                      _message('Development payment confirmed and ticket issued.');
                    } catch (error) {
                      _message('$error');
                    }
                  },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Complete development mock payment'),
                ),
              ] else ...[
                const SizedBox(height: 10),
                const Text(
                  'For local payment testing, run Flutter with --dart-define=ENABLE_MOCK_PAYMENTS=true.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final item = listing;
    final state = ref.watch(campusProvider);

    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('CampusX')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Listing unavailable',
                message: loadError ?? 'This CampusX listing could not be found.',
              ),
      );
    }

    final saved = state.savedIds.contains(item.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.kind.title),
        actions: [
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            onPressed: _toggleSaved,
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
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
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CampusColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(28),
              ),
              child: item.imageUrls.isEmpty
                  ? Text(item.emoji, style: const TextStyle(fontSize: 112))
                  : Image.network(
                      item.imageUrls.first,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 112),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (item.badge != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(item.badge!),
                  avatar: const Icon(Icons.verified_rounded, size: 17),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(item.subtitle, style: Theme.of(context).textTheme.titleMedium),
            if (item.price != null) ...[
              const SizedBox(height: 14),
              Text(
                money(item.price),
                style: const TextStyle(
                  color: CampusColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(item.location)),
                if (item.rating > 0) ...[
                  const Icon(Icons.star_rounded, color: CampusColors.accent),
                  Text('${item.rating.toStringAsFixed(1)} rating'),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            if (item.details.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: item.details.entries
                      .map(
                        (entry) => ListTile(
                          title: Text(entry.key),
                          trailing: Text(
                            entry.value,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
                  child: Text(
                    item.owner.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: CampusColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(item.owner, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(item.badge == 'Verified' ? 'Verified CampusX member' : 'CampusX member'),
                trailing: item.badge == 'Verified'
                    ? const Icon(Icons.verified_rounded, color: CampusColors.primary)
                    : null,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: FilledButton.icon(
          onPressed: actionBusy ? null : _performAction,
          icon: actionBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_actionIcon(item.kind)),
          label: Text(actionBusy ? 'Working…' : item.kind.actionLabel),
        ),
      ),
    );
  }

  IconData _actionIcon(ListingKind kind) => switch (kind) {
        ListingKind.marketplace ||
        ListingKind.rental ||
        ListingKind.roommate ||
        ListingKind.business =>
          Icons.chat_bubble_outline_rounded,
        ListingKind.tutor || ListingKind.service => Icons.calendar_month_outlined,
        ListingKind.internship => Icons.send_rounded,
        ListingKind.event => Icons.confirmation_number_outlined,
        ListingKind.deal => Icons.local_offer_outlined,
      };
}
