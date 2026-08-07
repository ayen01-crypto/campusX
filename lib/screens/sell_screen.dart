import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../widgets/common.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  ListingKind kind = ListingKind.marketplace;

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void publish() {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title first.')));
      return;
    }
    final price = int.tryParse(priceController.text.replaceAll(',', '').trim());
    final listing = CampusListing(
      id: const Uuid().v4(),
      kind: kind,
      title: titleController.text.trim(),
      subtitle: 'Posted by you',
      description: descriptionController.text.trim().isEmpty
          ? 'A new CampusX listing.'
          : descriptionController.text.trim(),
      emoji: kind.emoji,
      location: 'Near campus',
      price: price,
      badge: 'New',
      owner: 'You',
    );
    ref.read(campusProvider.notifier).addListing(listing);
    titleController.clear();
    priceController.clear();
    descriptionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your listing is now live on CampusX.')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ContentWidth(
        maxWidth: 720,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a listing', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Post an item, room, service or opportunity for your campus community.'),
            const SizedBox(height: 22),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 42),
                  SizedBox(height: 8),
                  Text('Photos will connect to device media in the native phase'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ListingKind>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final item in ListingKind.values)
                  DropdownMenuItem(value: item, child: Text('${item.emoji}  ${item.title}')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => kind = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (UGX)', prefixText: 'UGX '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(onPressed: publish, icon: const Icon(Icons.publish_rounded), label: const Text('Publish listing')),
          ],
        ),
      ),
    );
  }
}
