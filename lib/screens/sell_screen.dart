import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/app_state.dart';
import '../core/auth_state.dart';
import '../core/campus_api.dart';
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
  final locationController = TextEditingController(text: 'Near campus');
  final picker = ImagePicker();
  ListingKind kind = ListingKind.marketplace;
  List<XFile> photos = const [];
  bool publishing = false;
  double uploadProgress = 0;

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> pickPhotos() async {
    try {
      final selected = await picker.pickMultiImage(
        imageQuality: 82,
        limit: 6,
      );
      if (!mounted || selected.isEmpty) return;
      setState(() {
        final byPath = <String, XFile>{
          for (final photo in [...photos, ...selected]) photo.path: photo,
        };
        photos = byPath.values.take(6).toList();
      });
    } catch (error) {
      _message('CampusX could not open your photos: $error');
    }
  }

  Future<void> publish() async {
    if (publishing) return;
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final price = int.tryParse(priceController.text.replaceAll(',', '').trim());

    if (title.length < 2) {
      _message('Add a clear listing title first.');
      return;
    }
    if (description.length < 10) {
      _message('Add at least a short description so students know what you are offering.');
      return;
    }

    final state = ref.read(campusProvider);
    final auth = ref.read(authProvider);
    final localDraft = CampusListing(
      id: const Uuid().v4(),
      kind: kind,
      title: title,
      subtitle: 'Posted by you',
      description: description,
      emoji: kind.emoji,
      location: location.isEmpty ? state.university : location,
      price: price,
      badge: 'New',
      owner: auth.user?.name ?? 'You',
      ownerId: auth.user?.id,
      universityId: state.universityId,
    );

    if (!auth.authenticated) {
      ref.read(campusProvider.notifier).addListing(localDraft);
      _resetForm();
      _message('Saved locally. Sign in to publish this listing to the CampusX community.');
      return;
    }

    setState(() {
      publishing = true;
      uploadProgress = 0;
    });

    try {
      final api = ref.read(campusApiProvider);
      final imageUrls = <String>[];
      for (var index = 0; index < photos.length; index++) {
        final photo = photos[index];
        final bytes = await photo.readAsBytes();
        final url = await api.uploadFile(bytes, photo.name);
        imageUrls.add(url);
        if (mounted) {
          setState(
            () => uploadProgress = (index + 1) / (photos.isEmpty ? 1 : photos.length),
          );
        }
      }

      final published = await api.createListing(
        CampusListing(
          id: localDraft.id,
          kind: localDraft.kind,
          title: localDraft.title,
          subtitle: localDraft.subtitle,
          description: localDraft.description,
          emoji: localDraft.emoji,
          location: localDraft.location,
          price: localDraft.price,
          badge: localDraft.badge,
          owner: localDraft.owner,
          ownerId: localDraft.ownerId,
          universityId: localDraft.universityId,
          imageUrls: imageUrls,
        ),
      );

      ref.read(campusProvider.notifier).addListing(published);
      _resetForm();
      _message('Your listing is now live on CampusX.');
    } catch (error) {
      ref.read(campusProvider.notifier).addListing(localDraft);
      _resetForm();
      _message(
        'The server could not finish publishing, so CampusX kept a local copy. You can retry when you reconnect.\n$error',
      );
    } finally {
      if (mounted) {
        setState(() {
          publishing = false;
          uploadProgress = 0;
        });
      }
    }
  }

  void _resetForm() {
    titleController.clear();
    priceController.clear();
    descriptionController.clear();
    locationController.text = 'Near campus';
    if (mounted) setState(() => photos = const []);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
            Text(
              'Create a listing',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 6),
            const Text('Post an item, room, service or opportunity for your campus community.'),
            const SizedBox(height: 22),
            InkWell(
              onTap: publishing ? null : pickPhotos,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                constraints: const BoxConstraints(minHeight: 150),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: photos.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 18),
                          Icon(Icons.add_photo_alternate_outlined, size: 42),
                          SizedBox(height: 8),
                          Text('Add up to 6 photos'),
                          SizedBox(height: 18),
                        ],
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var index = 0; index < photos.length; index++)
                            _PhotoPreview(
                              file: photos[index],
                              onRemove: publishing
                                  ? null
                                  : () => setState(() {
                                        photos = [...photos]..removeAt(index);
                                      }),
                            ),
                          if (photos.length < 6)
                            SizedBox(
                              width: 104,
                              height: 104,
                              child: OutlinedButton(
                                onPressed: publishing ? null : pickPhotos,
                                child: const Icon(Icons.add_rounded),
                              ),
                            ),
                        ],
                      ),
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
              onChanged: publishing
                  ? null
                  : (value) {
                      if (value != null) setState(() => kind = value);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              enabled: !publishing,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              enabled: !publishing,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (optional)',
                prefixText: 'UGX ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              enabled: !publishing,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              enabled: !publishing,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            if (publishing && photos.isNotEmpty) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: uploadProgress == 0 ? null : uploadProgress),
              const SizedBox(height: 6),
              Text(
                uploadProgress < 1 ? 'Uploading photos…' : 'Publishing listing…',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: publishing ? null : publish,
              icon: publishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(publishing ? 'Publishing…' : 'Publish listing'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        return Stack(
          children: [
            Container(
              width: 104,
              height: 104,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: snapshot.hasData
                  ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            if (onRemove != null)
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
          ],
        );
      },
    );
  }
}
