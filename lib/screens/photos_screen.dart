import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../core/db/app_database.dart';
import '../core/repo/content_repo.dart';

/// Photo album screen for elder to browse photos of family and memories.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final ContentRepo _repo = ContentRepo(appDatabase);
  List<_PhotoItem> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final people = await _repo.getPeople();
    final List<_PhotoItem> items = [];

    for (final p in people) {
      items.add(
        _PhotoItem(
          id: p.id,
          title: p.name,
          subtitle: p.relationship,
          imagePath: p.photoPath,
          memoryPrompt: p.memoryPrompt,
        ),
      );
    }

    if (items.isEmpty) {
      try {
        final raw = await rootBundle.loadString('assets/mock_content/mock_content.json');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final mockPeople = (data['people'] as List<dynamic>?) ?? [];
        for (final p in mockPeople) {
          items.add(
            _PhotoItem(
              id: p['id'] as String,
              title: p['name'] as String,
              subtitle: p['relationship'] as String,
              imagePath: p['photoPath'] as String? ?? '',
              memoryPrompt: p['memoryPrompt'] as String?,
            ),
          );
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _photos = items;
        _loading = false;
      });
    }
  }

  void _openSlideshow(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SlideshowViewer(
          photos: _photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.indigo),
                    )
                  : _photos.isEmpty
                      ? _buildEmpty()
                      : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.raisedSurface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.indigo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.indigo, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '🖼️  Photos & Memories',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const Spacer(),
          if (_photos.isNotEmpty)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.slideshow_rounded),
              label: const Text('Slideshow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () => _openSlideshow(0),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🖼️', style: TextStyle(fontSize: 72)),
          SizedBox(height: 16),
          Text(
            'No photos available yet.',
            style: TextStyle(fontSize: 22, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final item = _photos[index];
        final hasFile = item.imagePath.isNotEmpty && File(item.imagePath).existsSync();

        return GestureDetector(
          onTap: () => _openSlideshow(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: hasFile
                        ? Image.file(
                            File(item.imagePath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: _placeholderColor(item.title),
                            child: Center(
                              child: Text(
                                item.title.isNotEmpty ? item.title[0].toUpperCase() : '📷',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _placeholderColor(String seed) {
    final colors = [
      AppColors.indigo,
      AppColors.terracotta,
      AppColors.marigold,
      AppColors.leafGreen,
    ];
    final idx = seed.isNotEmpty ? seed.codeUnitAt(0) % colors.length : 0;
    return colors[idx];
  }
}

class _PhotoItem {
  const _PhotoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.memoryPrompt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final String? memoryPrompt;
}

class _SlideshowViewer extends StatefulWidget {
  const _SlideshowViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<_PhotoItem> photos;
  final int initialIndex;

  @override
  State<_SlideshowViewer> createState() => _SlideshowViewerState();
}

class _SlideshowViewerState extends State<_SlideshowViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final hasFile = photo.imagePath.isNotEmpty && File(photo.imagePath).existsSync();

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasFile)
                      InteractiveViewer(
                        child: Image.file(
                          File(photo.imagePath),
                          fit: BoxFit.contain,
                        ),
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.indigo.withValues(alpha: 0.5),
                              ),
                              child: Center(
                                child: Text(
                                  photo.title.isNotEmpty ? photo.title[0].toUpperCase() : '📷',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            // Bottom overlay caption
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.photos[_currentIndex].title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.photos[_currentIndex].subtitle,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (widget.photos[_currentIndex].memoryPrompt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.photos[_currentIndex].memoryPrompt!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Top close button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
