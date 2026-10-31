import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/models/ml_model.dart';
import 'package:ai_model_hub/providers/auth_provider.dart';
import 'package:ai_model_hub/providers/model_provider.dart';
import 'package:ai_model_hub/services/firebase_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Security Audit: BOLA / IDOR Authorization Defenses', () {
    test('Non-owner cannot modify or update a model owned by another user', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      final originalModel = MlModel(
        id: 'model-sec-101',
        name: 'Target Owner Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 95.0,
        latencyMs: 15,
        version: '1.0.0',
        description: 'Target description',
        datasetName: 'Target Dataset',
        imageUrl: 'https://example.com/target.jpg',
        creatorId: 'victim-uid-12345',
        creatorEmail: 'victim@broml.ai',
      );

      // Attempt update as attacker
      final success = await provider.updateModel(
        originalModel,
        name: 'Malicious Overwrite Attempt',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 99.0,
        latencyMs: 10,
        version: '2.0.0',
        description: 'Hacked description',
        datasetName: 'Hacked dataset',
        currentUserId: 'attacker-uid-67890',
        currentUserEmail: 'attacker@evil.com',
        isAdmin: false,
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('Access denied'));
    });

    test('Non-owner cannot delete a model owned by another user', () async {
      final provider = ModelProvider();

      // Add a model with a distinct victim owner
      await provider.createModel(
        name: 'Victim Protected Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 92.0,
        latencyMs: 20,
        version: '1.0.0',
        description: 'Should not be deletable by attacker',
        datasetName: 'Dataset A',
        creatorId: 'owner-uid-999',
        creatorEmail: 'owner@broml.ai',
      );

      final created = provider.models.firstWhere((m) => m.name == 'Victim Protected Model');

      // Attempt delete as attacker
      final deleted = await provider.deleteModel(
        created.id,
        currentUserId: 'attacker-uid-111',
        currentUserEmail: 'attacker@evil.com',
        isAdmin: false,
      );

      expect(deleted, isFalse);
      expect(provider.errorMessage, contains('Access denied'));
      // Verify model still exists in provider
      expect(provider.models.any((m) => m.id == created.id), isTrue);
    });

    test('Legitimate owner can update their own model', () {
      final provider = ModelProvider();

      final userModel = MlModel(
        id: 'model-owner-1',
        name: 'My Valid Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 94.0,
        latencyMs: 14,
        version: '1.0.0',
        description: 'User description',
        datasetName: 'COCO',
        imageUrl: 'https://example.com/pic.jpg',
        creatorId: 'legit-user-555',
        creatorEmail: 'legit@broml.ai',
      );

      final canModify = provider.canUserModifyModel(
        userModel,
        userId: 'legit-user-555',
        userEmail: 'legit@broml.ai',
        isAdmin: false,
      );

      expect(canModify, isTrue);
    });

    test('Admin user can manage any model regardless of creator', () {
      final provider = ModelProvider();

      final anyModel = MlModel(
        id: 'model-any-1',
        name: 'Any User Model',
        category: 'Natural Language Processing',
        framework: 'ONNX',
        accuracy: 90.0,
        latencyMs: 30,
        version: '1.0.0',
        description: 'Some model',
        datasetName: 'Corpus',
        imageUrl: 'https://example.com/pic.jpg',
        creatorId: 'other-user-123',
        creatorEmail: 'other@broml.ai',
      );

      final canAdminModify = provider.canUserModifyModel(
        anyModel,
        userId: 'admin-uid-000',
        userEmail: 'admin@broml.ai',
        isAdmin: true,
      );

      expect(canAdminModify, isTrue);
    });
  });

  group('Security Audit: Input Validation & Protocol Injection', () {
    test('Rejects dangerous URL protocols like javascript: in model creation', () async {
      final provider = ModelProvider();

      final result = await provider.createModel(
        name: 'XSS Injection Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 95.0,
        latencyMs: 10,
        version: '1.0.0',
        description: 'Testing URL sanitization',
        datasetName: 'Safe Dataset',
        githubUrl: 'javascript:alert(document.cookie)',
      );

      expect(result, isFalse);
      expect(provider.errorMessage, contains('valid secure URL starting with https://'));
    });

    test('Rejects out-of-range benchmark accuracy (> 100% or < 0%)', () async {
      final provider = ModelProvider();

      final resultOver = await provider.createModel(
        name: 'Over 100% Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 150.0,
        latencyMs: 10,
        version: '1.0.0',
        description: 'Invalid accuracy',
        datasetName: 'Dataset',
      );
      expect(resultOver, isFalse);
      expect(provider.errorMessage, contains('Accuracy must be between 0% and 100%'));

      final resultNegative = await provider.createModel(
        name: 'Negative Accuracy Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: -5.0,
        latencyMs: 10,
        version: '1.0.0',
        description: 'Negative accuracy',
        datasetName: 'Dataset',
      );
      expect(resultNegative, isFalse);
      expect(provider.errorMessage, contains('Accuracy must be between 0% and 100%'));
    });

    test('Rejects invalid latency values (negative or excessive)', () async {
      final provider = ModelProvider();

      final resultZero = await provider.createModel(
        name: 'Zero Latency Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 95.0,
        latencyMs: 0,
        version: '1.0.0',
        description: 'Invalid latency',
        datasetName: 'Dataset',
      );
      expect(resultZero, isFalse);
      expect(provider.errorMessage, contains('Latency must be between 1ms and 60,000ms'));
    });

    test('Rejects excessively long model names to prevent UI buffer abuse', () async {
      final provider = ModelProvider();
      final oversizedName = 'A' * 150;

      final result = await provider.createModel(
        name: oversizedName,
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 95.0,
        latencyMs: 12,
        version: '1.0.0',
        description: 'Oversized name test',
        datasetName: 'Dataset',
      );

      expect(result, isFalse);
      expect(provider.errorMessage, contains('Invalid model name'));
    });
  });

  group('Security Audit: File Upload & Storage Hardening', () {
    test('Allows safe image extensions and blocks dangerous executables and scripts', () {
      expect(FirebaseStorageService.isValidImageExtension('architecture.png'), isTrue);
      expect(FirebaseStorageService.isValidImageExtension('model_diagram.jpg'), isTrue);
      expect(FirebaseStorageService.isValidImageExtension('preview.webp'), isTrue);
      expect(FirebaseStorageService.isValidImageExtension('weights.jpeg'), isTrue);

      // Dangerous extensions must be blocked
      expect(FirebaseStorageService.isValidImageExtension('malware.exe'), isFalse);
      expect(FirebaseStorageService.isValidImageExtension('script.sh'), isFalse);
      expect(FirebaseStorageService.isValidImageExtension('exploit.js'), isFalse);
      expect(FirebaseStorageService.isValidImageExtension('index.html'), isFalse);
      expect(FirebaseStorageService.isValidImageExtension('payload.svg'), isFalse);
      expect(FirebaseStorageService.isValidImageExtension('config.php'), isFalse);
    });

    test('Enforces strict file size limit of 5MB', () {
      expect(FirebaseStorageService.isFileSizeAllowed(1024), isTrue); // 1 KB
      expect(FirebaseStorageService.isFileSizeAllowed(4 * 1024 * 1024), isTrue); // 4 MB
      expect(FirebaseStorageService.isFileSizeAllowed(5 * 1024 * 1024), isTrue); // Exactly 5 MB

      expect(FirebaseStorageService.isFileSizeAllowed(0), isFalse); // Empty file
      expect(FirebaseStorageService.isFileSizeAllowed(6 * 1024 * 1024), isFalse); // 6 MB exceeds limit
      expect(FirebaseStorageService.isFileSizeAllowed(100 * 1024 * 1024), isFalse); // 100 MB DoS attempt
    });

    test('Sanitizes filenames to neutralize path traversal sequences', () {
      expect(FirebaseStorageService.sanitizeFilename('../../etc/passwd'), 'passwd');
      expect(FirebaseStorageService.sanitizeFilename('..\\..\\windows\\system32\\cmd.exe'), 'cmd.exe');
      expect(FirebaseStorageService.sanitizeFilename('my image file #1!.png'), 'my_image_file__1_.png');
      expect(FirebaseStorageService.sanitizeFilename('model_diagram_v2.jpg'), 'model_diagram_v2.jpg');
    });

    test('Accurately maps MIME content types for uploaded images', () {
      expect(FirebaseStorageService.getMimeType('diagram.png'), 'image/png');
      expect(FirebaseStorageService.getMimeType('diagram.webp'), 'image/webp');
      expect(FirebaseStorageService.getMimeType('diagram.jpg'), 'image/jpeg');
      expect(FirebaseStorageService.getMimeType('diagram.jpeg'), 'image/jpeg');
    });
  });

  group('Security Audit: Authentication Security & Validation', () {
    test('Rejects passwords exceeding 128 characters to protect against hash DoS', () {
      final auth = AuthProvider();
      final overlyLongPass = 'P' * 150;
      expect(auth.isPasswordValid(overlyLongPass), isFalse);
      expect(auth.isPasswordValid('validPass123'), isTrue);
    });

    test('Rejects emails exceeding RFC 5321 length limits', () {
      final auth = AuthProvider();
      final longEmail = '${"a" * 250}@example.com';
      expect(auth.isEmailValid(longEmail), isFalse);
      expect(auth.isEmailValid('valid.engineer@broml.ai'), isTrue);
    });
  });
}

