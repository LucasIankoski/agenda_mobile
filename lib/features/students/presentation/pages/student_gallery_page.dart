import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/ui/brand_widgets.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/student_gallery_model.dart';
import '../student_gallery_controller.dart';
import '../student_profile_controller.dart';

class StudentGalleryPage extends ConsumerStatefulWidget {
  final String studentId;

  const StudentGalleryPage({super.key, required this.studentId});

  @override
  ConsumerState<StudentGalleryPage> createState() => _StudentGalleryPageState();
}

class _StudentGalleryPageState extends ConsumerState<StudentGalleryPage> {
  static const double _galleryImageAspectRatio = 1.12;
  static const double _galleryTileTextHeight = 138;

  final ImagePicker _picker = ImagePicker();
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(studentDetailProvider(widget.studentId));
    final authSession = ref.watch(authControllerProvider).valueOrNull;
    final isParent = authSession?.isParent == true;
    final imageHeaders = _buildImageHeaders(authSession?.token);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Galeria')),
      body: studentAsync.when(
        data: (student) {
          final galleryAsync = ref.watch(studentGalleryByStudentProvider(widget.studentId));
          final photoCount = galleryAsync.valueOrNull?.length;
          final screenWidth = MediaQuery.sizeOf(context).width;
          final columnCount = _gridColumnsForWidth(screenWidth);
          final tileHeight = _galleryTileHeight(screenWidth, columnCount);

          return RefreshIndicator(
            onRefresh: _refreshGallery,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeading(
                      eyebrow: 'Galeria',
                      title: student.fullName,
                      subtitle: isParent
                          ? 'Veja as fotos publicadas pela escola para este aluno.'
                          : 'Publique fotos do aluno com upload otimizado para mobile e web.',
                      trailing: photoCount != null
                          ? StatusPill(
                              label: photoCount == 1 ? '1 foto' : '$photoCount fotos',
                              color: const Color(0xFF0E7C86),
                            )
                          : null,
                    ),
                  ),
                ),
                if (!isParent)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _isPublishing ? null : _publishPhotos,
                          icon: _isPublishing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(_isPublishing ? 'Enviando...' : 'Publicar fotos'),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: galleryAsync.when(
                    data: (photos) {
                      if (photos.isEmpty) {
                        return SliverToBoxAdapter(
                          child: EmptyStateCard(
                            icon: Icons.photo_library_outlined,
                            title: isParent ? 'Nenhuma foto publicada' : 'Nenhuma foto enviada',
                            subtitle: isParent
                                ? 'Quando a escola publicar imagens deste aluno, elas aparecerao aqui.'
                                : 'Publique fotos do aluno para manter a familia atualizada.',
                          ),
                        );
                      }

                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final photo = photos[index];
                            return _GalleryPhotoCard(
                              photo: photo,
                              imageHeaders: imageHeaders,
                              onTap: () => _openPhotoViewer(context, photo, imageHeaders),
                            );
                          },
                          childCount: photos.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: tileHeight,
                        ),
                      );
                    },
                    error: (e, _) => SliverToBoxAdapter(
                      child: EmptyStateCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Falha ao carregar a galeria',
                        subtitle: getFriendlyError(e),
                      ),
                    ),
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: 'Falha ao carregar aluno',
              subtitle: getFriendlyError(e),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _publishPhotos() async {
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxHeight: 2048,
      maxWidth: 2048,
    );
    if (files.isEmpty) return;

    if (!mounted) return;
    final caption = await _showCaptionDialog(context, files.length);
    if (!mounted || caption == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isPublishing = true);
    try {
      await ref.read(studentGalleryRepositoryProvider).create(
            widget.studentId,
            files: files,
            caption: caption,
          );
      await _refreshGallery();
      if (!mounted) return;

      final count = files.length;
      final label = count == 1 ? '1 foto publicada.' : '$count fotos publicadas.';
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(label)));
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(getFriendlyError(e))));
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  Future<String?> _showCaptionDialog(BuildContext context, int fileCount) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _GalleryPublishDialog(fileCount: fileCount),
    );
  }

  Future<void> _refreshGallery() async {
    ref.invalidate(studentGalleryByStudentProvider(widget.studentId));
    ref.invalidate(studentDetailProvider(widget.studentId));
  }

  void _openPhotoViewer(
    BuildContext context,
    StudentGalleryPhoto photo,
    Map<String, String>? imageHeaders,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0F1724),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Hero(
                  tag: 'gallery-photo-${photo.id}',
                  child: Image.network(
                    photo.imageUrl,
                    headers: imageHeaders,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nao foi possivel abrir a foto.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            if (photo.hasCaption || (photo.createdByName?.trim().isNotEmpty ?? false))
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (photo.hasCaption)
                        Text(
                          photo.caption!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (photo.createdByName?.trim().isNotEmpty ?? false) ...[
                        if (photo.hasCaption) const SizedBox(height: 8),
                        Text(
                          'Publicado por ${photo.createdByName!} em ${photo.createdAtLabel}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPhotoCard extends StatelessWidget {
  static const double _imageAspectRatio = _StudentGalleryPageState._galleryImageAspectRatio;

  final StudentGalleryPhoto photo;
  final Map<String, String>? imageHeaders;
  final VoidCallback onTap;

  const _GalleryPhotoCard({
    required this.photo,
    required this.imageHeaders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(0),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: Hero(
                  tag: 'gallery-photo-${photo.id}',
                  child: Image.network(
                    photo.thumbnailOrImageUrl,
                    headers: imageHeaders,
                    fit: BoxFit.cover,
                    cacheWidth: 900,
                    filterQuality: FilterQuality.low,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: const Color(0xFFF2F5FB),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF2F5FB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: Color(0xFF66748B)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.createdAtLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      photo.hasCaption ? photo.caption! : 'Foto publicada na galeria do aluno.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF66748B),
                          ),
                    ),
                    const Spacer(),
                    Text(
                      photo.createdByName?.trim().isNotEmpty == true ? photo.createdByName! : 'Equipe escolar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF0E7C86),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPublishDialog extends StatefulWidget {
  final int fileCount;

  const _GalleryPublishDialog({required this.fileCount});

  @override
  State<_GalleryPublishDialog> createState() => _GalleryPublishDialogState();
}

class _GalleryPublishDialogState extends State<_GalleryPublishDialog> {
  String _caption = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Publicar fotos'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileCount == 1 ? '1 arquivo selecionado.' : '${widget.fileCount} arquivos selecionados.',
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Legenda opcional',
                hintText: 'Ex.: Atividade de pintura no patio.',
              ),
              minLines: 2,
              maxLines: 4,
              maxLength: 240,
              textInputAction: TextInputAction.done,
              onChanged: (value) => _caption = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context, _caption.trim());
          },
          child: const Text('Publicar'),
        ),
      ],
    );
  }
}

int _gridColumnsForWidth(double width) {
  if (width >= 1320) return 5;
  if (width >= 960) return 4;
  if (width >= 680) return 3;
  return 2;
}

double _galleryTileHeight(double screenWidth, int columnCount) {
  const horizontalPadding = 32.0;
  const gridSpacing = 12.0;
  final availableWidth = screenWidth - horizontalPadding - (gridSpacing * (columnCount - 1));
  final tileWidth = availableWidth / columnCount;
  final imageHeight = tileWidth / _StudentGalleryPageState._galleryImageAspectRatio;
  return imageHeight + _StudentGalleryPageState._galleryTileTextHeight;
}

Map<String, String>? _buildImageHeaders(String? token) {
  final cleanToken = token?.trim();
  if (cleanToken == null || cleanToken.isEmpty) {
    return null;
  }

  return {'Authorization': 'Bearer $cleanToken'};
}
