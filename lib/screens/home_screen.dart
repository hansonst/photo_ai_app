import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';
import '../widgets/results_section.dart';
import '../widgets/controls_section.dart';
import '../widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  String _customPrompt = '';
  String? _selectedScene;
  List<String> _generatedImages = [];
  bool _isGenerating = false;
  String? _uploadedImageUrl;
  double _uploadProgress = 0.0;
  int _currentImageIndex = 0;
  
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _promptController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _generatedImages = [];
        _uploadProgress = 0.0;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadImage() {
  _downloadImageAsync();
}

Future<void> _downloadImageAsync() async {
  try {
    // Request permission
    final status = await Permission.photos.request();
    
    if (status.isGranted || status.isLimited) {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloading image...')),
        );
      }

      // Download the image from URL
      final dio = Dio();
      final response = await dio.get(
        _generatedImages[_currentImageIndex],
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = 'ai_photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      
      // Save to temporary file
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      // Save to gallery using gal
      await Gal.putImage(filePath);

      // Clean up temporary file
      await file.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Image saved to gallery!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // User permanently denied permission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable photo access in settings'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } else {
      // Permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot save image.'),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  Future<void> _generateImages() async {
  if (_selectedImage == null && _customPrompt.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please upload an image or enter a prompt')),
    );
    return;
  }

  setState(() {
    _isGenerating = true;
    _generatedImages = [];
    _uploadProgress = 0.1;  // ← CHANGE: Start at 0.1 instead of 0.0
  });

  final firebaseService = Provider.of<FirebaseService>(context, listen: false);

  try {
    // Upload image with progress
    if (_selectedImage != null && _uploadedImageUrl == null) {
      setState(() => _uploadProgress = 0.3);
      await Future.delayed(const Duration(milliseconds: 500));
      
      _uploadedImageUrl = await firebaseService.uploadImage(_selectedImage!);
      
      setState(() => _uploadProgress = 0.5);
      
      if (_uploadedImageUrl == null) {
        throw Exception('Failed to upload image');
      }
    }

      // Determine prompt - MUST have either image or prompt
String? promptToUse;
if (_customPrompt.isNotEmpty) {
  promptToUse = _customPrompt;
} else if (_selectedScene != null) {
  promptToUse = AppScenes.all.firstWhere((s) => s['id'] == _selectedScene)['prompt'];
} else if (_uploadedImageUrl != null) {
  // Image-only mode: Cloud Function will use default scenes
  promptToUse = null;
}

// Validate before calling
if (_uploadedImageUrl == null && promptToUse == null) {
  throw Exception('Either image or prompt is required');
}

setState(() => _uploadProgress = 0.6);

// Generate images
final generated = await firebaseService.generateAIImages(
  _uploadedImageUrl ?? '',
  prompt: promptToUse,
);

      setState(() => _uploadProgress = 1.0);

if (generated.isNotEmpty) {
  await firebaseService.saveGenerationResult(
    originalUrl: _uploadedImageUrl ?? '',
    generatedUrls: generated,
  );
  
  // Preload/cache images before showing them
  await Future.wait(
    generated.map((url) => precacheImage(NetworkImage(url), context))
  );
  
  // Update state with results
  setState(() {
    _generatedImages = generated;
    _isGenerating = false;
    _uploadProgress = 0.0;
  });
} else {
  // No images generated
  setState(() {
    _isGenerating = false;
    _uploadProgress = 0.0;
  });
}

      if (generated.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate images')),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _uploadProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _resetAll() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _customPrompt = '';
      _selectedScene = null;
      _generatedImages = [];
      _uploadProgress = 0.0;
      _currentImageIndex = 0;
      _promptController.clear();
    });
  }

  @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async => !_isGenerating, // Prevent back button during generation
    child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.borderLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
  return const AppHeader();
}

 Widget _buildContent() {
  // Show loading if generating (highest priority)
  if (_isGenerating) {
    return _buildLoadingSection();
  }
  
  // Show results if we have generated images
  if (_generatedImages.isNotEmpty) {
    return _buildResultsSection();
  }
  
  // Show controls if image is selected
  if (_selectedImage != null) {
    return _buildControlsSection();
  }
  
  // Default: show upload section
  return _buildUploadSection();
}

  Widget _buildUploadSection() {
    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(64),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload your photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to browse or take a photo',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildControlsSection() {
  return ControlsSection(
    selectedImage: _selectedImage!,
    promptController: _promptController,
    customPrompt: _customPrompt,
    selectedScene: _selectedScene,
    isGenerating: _isGenerating,
    onClose: _resetAll,
    onPromptChanged: (value) => setState(() => _customPrompt = value),
    onSceneSelected: (sceneId) => setState(() => _selectedScene = sceneId),
    onGenerate: _generateImages,
  );
}

 Widget _buildLoadingSection() {
  return Column(
    children: [
      const SizedBox(height: 40),
      
      // Animated progress indicator
      Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purpleLight,
            ),
          ),
          
          // Progress indicator
          SizedBox(
            width: 120,
            height: 120,
            child: _uploadProgress > 0
                ? CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.purpleLighter,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                  )
                : CircularProgressIndicator(
                    strokeWidth: 8,
                    backgroundColor: AppColors.purpleLighter,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                  ),
          ),
          
          // Icon and percentage
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 40),
              const SizedBox(height: 8),
              Text(
                _uploadProgress > 0 
                    ? '${(_uploadProgress * 100).toInt()}%'
                    : 'Starting...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
      
      const SizedBox(height: 32),
      
      // Status text
      const Text(
        'Creating magic...',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      
      const SizedBox(height: 12),
      
      // Dynamic status message
      Text(
        _uploadProgress == 0
            ? 'Preparing your photo...'
            : _uploadProgress < 0.4
                ? 'Uploading your photo...'
                : _uploadProgress < 0.7
                    ? 'AI is working its magic...'
                    : 'Almost there...',
        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
      
      const SizedBox(height: 24),
      
      // Time estimate
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.backgroundDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            const Text(
              'This may take 2-5 minutes',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 32),
      
      // Loading dots animation (optional)
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFA855F7).withOpacity(0.3 + (index * 0.2)),
            ),
          );
        }),
      ),
      
      const SizedBox(height: 40),
    ],
  );
}

  Widget _buildResultsSection() {
  return ResultsSection(
    selectedImage: _selectedImage!,
    generatedImages: _generatedImages,
    onRegenerate: () {
      setState(() => _generatedImages = []);
    },
    onDownload: _downloadImage,
    onUploadNew: _resetAll,
      );
    }
  }