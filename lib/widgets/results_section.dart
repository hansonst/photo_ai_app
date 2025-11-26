import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultsSection extends StatefulWidget {
  final File selectedImage;
  final List<String> generatedImages;
  final VoidCallback onRegenerate;
  final VoidCallback onDownload;
  final VoidCallback onUploadNew;

  const ResultsSection({
    Key? key,
    required this.selectedImage,
    required this.generatedImages,
    required this.onRegenerate,
    required this.onDownload,
    required this.onUploadNew,
  }) : super(key: key);

  @override
  State<ResultsSection> createState() => _ResultsSectionState();
}

class _ResultsSectionState extends State<ResultsSection> {
  double _sliderValue = 1.0;
  int _currentImageIndex = 0;
  bool _isDownloading = false;

  void _showImageZoomDialog(BuildContext context, {required bool isOriginal}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: ImageZoomViewer(
            isOriginal: isOriginal,
            originalImage: widget.selectedImage,
            generatedImageUrl: widget.generatedImages[_currentImageIndex],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Before/After Slider Image
        GestureDetector(
          onTap: () => _showImageZoomDialog(context, isOriginal: _sliderValue < 0.5),
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Original Image (Background)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    widget.selectedImage,
                    width: double.infinity,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                ),
                // AI Generated Image (Overlay with clip)
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: _sliderValue,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.generatedImages[_currentImageIndex],
                        width: double.infinity,
                        height: 400,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Labels
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Original',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'AI Generated',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                // Tap to zoom hint
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Tap to zoom',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Slider
        Row(
          children: [
            const Icon(Icons.photo, color: AppColors.textSecondary, size: 20),
            Expanded(
              child: Slider(
                value: _sliderValue,
                onChanged: (value) {
                  setState(() => _sliderValue = value);
                },
                activeColor: AppColors.primary,
                inactiveColor: AppColors.borderLight,
              ),
            ),
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 24),

        // Generated Images Gallery
        if (widget.generatedImages.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Variations',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              Text(
                '${_currentImageIndex + 1}/${widget.generatedImages.length}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.generatedImages.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentImageIndex = index);
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderLight,
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.generatedImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onRegenerate,
                icon: const Icon(Icons.refresh),
                label: const Text('Regenerate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
  child: Builder(
    builder: (context) {
      print('🔍 Building download button - isDownloading: $_isDownloading');
      return ElevatedButton.icon(
        onPressed: _isDownloading ? null : () {
          print('✅ Download button PRESSED');
          setState(() {
            _isDownloading = true;
            print('⏳ Set _isDownloading = true');
          });
          
          widget.onDownload();
          print('📥 Called widget.onDownload()');
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              print('⏰ 3 seconds passed, resetting state');
              setState(() {
                _isDownloading = false;
                print('✅ Set _isDownloading = false');
              });
            } else {
              print('❌ Widget not mounted, cannot reset state');
            }
          });
        },
        icon: _isDownloading 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.download),
        label: Text(_isDownloading ? 'Downloading...' : 'Download'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      );
    },
  ),
),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: widget.onUploadNew,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Upload New Photo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// Image Zoom Viewer Widget
class ImageZoomViewer extends StatefulWidget {
  final bool isOriginal;
  final File originalImage;
  final String generatedImageUrl;

  const ImageZoomViewer({
    Key? key,
    required this.isOriginal,
    required this.originalImage,
    required this.generatedImageUrl,
  }) : super(key: key);

  @override
  State<ImageZoomViewer> createState() => _ImageZoomViewerState();
}

class _ImageZoomViewerState extends State<ImageZoomViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Reset zoom
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in to 2x at the tap position
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 1, -position.dy * 1)
        ..scale(2.0);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Zoomable Image
        Center(
          child: GestureDetector(
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              child: widget.isOriginal
                  ? Image.file(
                      widget.originalImage,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      widget.generatedImageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),

        // Close Button
        Positioned(
          top: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // Image Type Label
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isOriginal
                  ? Colors.black.withValues(alpha: 0.6)
                  : AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.isOriginal ? 'Original Photo' : 'AI Generated',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Zoom Instructions
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Pinch to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.touch_app, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Double tap to zoom',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}