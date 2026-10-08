import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseStorageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<String?> uploadModelImage(XFile xFile) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        final fileName = 'models/${DateTime.now().millisecondsSinceEpoch}_${xFile.name}';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await xFile.readAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else {
          final file = File(xFile.path);
          uploadTask = storageRef.putFile(file);
        }

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
