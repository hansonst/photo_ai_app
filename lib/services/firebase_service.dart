import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // FIXED: Set the correct region for your Cloud Function
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'asia-southeast2');
  
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Compress image before upload to reduce storage costs
  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Good balance between quality and size
        minWidth: 1920, // Max width for social media
        minHeight: 1920,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      if (kDebugMode) print('Compression error: $e');
      return file; // Return original if compression fails
    }
  }
  
  /// Upload original image to Firebase Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      _setLoading(true);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      // Compress image first
      final compressedFile = await _compressImage(imageFile);
      if (compressedFile == null) throw Exception('Failed to compress image');
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/originals/$fileName');
      
      if (kDebugMode) print('Uploading image to Firebase Storage...');
      await ref.putFile(compressedFile);
      final downloadUrl = await ref.getDownloadURL();
      
      if (kDebugMode) print('Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _setError('Failed to upload image: $e');
      if (kDebugMode) print('Upload error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Call Cloud Function to generate AI images
  Future<List<String>> generateAIImages(String originalImageUrl, {String? prompt}) async {
    try {
      _setLoading(true);
      
      if (kDebugMode) {
        print('Calling generateImages function...');
        print('Image URL: $originalImageUrl');
        print('Prompt: $prompt');
      }
      
      final callable = _functions.httpsCallable('generateImages');
      final result = await callable.call({
        'imageUrl': originalImageUrl,
        'prompt': prompt,
      });
      
      if (kDebugMode) print('Function response: ${result.data}');
      
      final data = result.data as Map<String, dynamic>;
      final generatedUrls = List<String>.from(data['generatedImages'] ?? []);
      
      if (kDebugMode) print('Generated ${generatedUrls.length} images');
      return generatedUrls;
    } catch (e) {
      _setError('Failed to generate AI images: $e');
      if (kDebugMode) print('Generation error: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Save generation result to Firestore
  Future<void> saveGenerationResult({
    required String originalUrl,
    required List<String> generatedUrls,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      
      await _firestore.collection('users').doc(userId).collection('generations').add({
        'originalImageUrl': originalUrl,
        'generatedImages': generatedUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) print('Generation result saved to Firestore');
    } catch (e) {
      _setError('Failed to save result: $e');
      if (kDebugMode) print('Save error: $e');
    }
  }
  
  /// Get user's generation history
  Stream<QuerySnapshot> getUserGenerations() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('generations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}