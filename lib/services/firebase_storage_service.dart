import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseStorageService {
  final ImagePicker _picker = ImagePicker();

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB maximum
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  static bool isValidImageExtension(String filename) {
    final lower = filename.toLowerCase();
    return allowedExtensions.any((ext) => lower.endsWith(ext));
  }

  static bool isFileSizeAllowed(int byteLength) {
    return byteLength > 0 && byteLength <= maxFileSizeBytes;
  }

  static String sanitizeFilename(String filename) {
    // Strip path elements and path traversal sequences
    final base = filename.split(RegExp(r'[/\\]')).last;
    final sanitized = base.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return sanitized.isEmpty ? 'upload.jpg' : sanitized;
  }

  static String getMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null && !isValidImageExtension(image.name)) {
        debugPrint('Rejected image with invalid extension: ${image.name}');
        return null;
      }
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<String?> uploadModelImage(XFile xFile, {String? userId}) async {
    // 1. Validate file extension
    if (!isValidImageExtension(xFile.name)) {
      debugPrint('Security rejection: Disallowed image extension in ${xFile.name}');
      return null;
    }

    try {
      final bytes = await xFile.readAsBytes();

      // 2. Validate file size (max 5MB)
      if (!isFileSizeAllowed(bytes.length)) {
        debugPrint('Security rejection: Image size (${bytes.length} bytes) exceeds 5MB limit.');
        return null;
      }

      if (Firebase.apps.isNotEmpty) {
        final safeName = sanitizeFilename(xFile.name);
        final userPrefix = (userId != null && userId.isNotEmpty) ? '$userId/' : '';
        final fileName = 'models/$userPrefix${DateTime.now().millisecondsSinceEpoch}_$safeName';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);
        final mimeType = getMimeType(safeName);

        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        );

        final uploadTask = storageRef.putData(bytes, metadata);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400';
      }
    } catch (e) {
      debugPrint('Firebase storage upload fallback: $e');
      return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400';
    }
  }
}
