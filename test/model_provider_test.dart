import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_model_hub/providers/model_provider.dart';
import 'package:ai_model_hub/services/github_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ModelProvider Functional & State Management Tests', () {
    test('Initializes with default categories and empty search query', () async {
      final provider = ModelProvider();
      await provider.loadModels();
      expect(provider.categories, contains('All'));
      expect(provider.categories, contains('Saved'));
      expect(provider.categories, contains('Computer Vision'));
      expect(provider.categories, contains('Natural Language Processing'));
      expect(provider.categories, contains('Audio & Speech'));
      expect(provider.categories, contains('Reinforcement Learning'));
      expect(provider.categories, contains('Tabular ML'));
      expect(provider.selectedCategory, 'All');
      expect(provider.searchQuery, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('Loads seed and integrated GitHub models successfully across all categories', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      expect(provider.models, isNotEmpty);
      expect(provider.models.length, greaterThanOrEqualTo(30));
      expect(provider.models.any((m) => m.name.contains('YOLO')), isTrue);
      expect(provider.models.any((m) => m.name.contains('ResNet')), isTrue);
      expect(provider.models.any((m) => m.name.contains('LLaMA') || m.name.contains('Llama')), isTrue);
      expect(provider.models.any((m) => m.name.contains('Whisper')), isTrue);
      expect(provider.models.any((m) => m.name.contains('DeepSeek')), isTrue);
      expect(provider.models.any((m) => m.name.contains('FLUX')), isTrue);
      expect(provider.models.any((m) => m.name.contains('XGBoost')), isTrue);
      expect(provider.models.any((m) => m.name.contains('Stable Baselines')), isTrue);
    });

    test('Filters models by Category correctly across all 5 ML domains', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      provider.setSelectedCategory('Computer Vision');
      expect(provider.selectedCategory, 'Computer Vision');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.category, 'Computer Vision');
      }

      provider.setSelectedCategory('Natural Language Processing');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.category, 'Natural Language Processing');
      }

      provider.setSelectedCategory('Audio & Speech');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.category, 'Audio & Speech');
      }

      provider.setSelectedCategory('Reinforcement Learning');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.category, 'Reinforcement Learning');
      }

      provider.setSelectedCategory('Tabular ML');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.category, 'Tabular ML');
      }
    });

    test('Filters models by Search Query across name, description, and framework', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      // Search by Framework
      provider.setSearchQuery('TensorFlow');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(
          m.framework.toLowerCase().contains('tensorflow') ||
          m.name.toLowerCase().contains('tensorflow') ||
          m.description.toLowerCase().contains('tensorflow'),
          isTrue,
        );
      }

      // Search for specific GitHub model
      provider.setSearchQuery('DeepSeek');
      expect(provider.models, isNotEmpty);
      expect(provider.models.any((m) => m.name.contains('DeepSeek')), isTrue);

      // Search for whisper audio model
      provider.setSearchQuery('Whisper');
      expect(provider.models, isNotEmpty);
      expect(provider.models.any((m) => m.name.contains('Whisper')), isTrue);
    });

    test('Filters by Source (GitHub Zoo vs Custom Models)', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      provider.setSelectedSource('GitHub Zoo');
      expect(provider.selectedSource, 'GitHub Zoo');
      expect(provider.models, isNotEmpty);
      for (final m in provider.models) {
        expect(m.githubUrl, isNotEmpty);
      }

      provider.setSelectedSource('All');
      expect(provider.models.length, greaterThan(provider.githubModelsCount - 5));
    });

    test('Bookmark / Save to profile functionality toggles and persists', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      final target = provider.models.first;
      expect(provider.isModelSaved(target), isFalse);

      final added = await provider.toggleSaveModel(target);
      expect(added, isTrue);
      expect(provider.isModelSaved(target), isTrue);
      expect(provider.savedModels.any((m) => m.name == target.name), isTrue);

      // Toggle off
      final removed = await provider.toggleSaveModel(target);
      expect(removed, isFalse);
      expect(provider.isModelSaved(target), isFalse);
    });

    test('Creates a valid model and inserts it at top of model zoo', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      final initialCount = provider.models.length;

      final success = await provider.createModel(
        name: 'Custom Mobile Vision V1',
        category: 'Computer Vision',
        framework: 'TensorFlow',
        accuracy: 93.8,
        latencyMs: 14,
        version: '1.0.0',
        description: 'Edge TPU model for automated inspection on factory belts.',
        datasetName: 'Industrial Inspection Dataset',
        creatorId: 'author-uid-1',
        creatorEmail: 'author@broml.ai',
      );

      expect(success, isTrue);
      expect(provider.models.length, initialCount + 1);
      expect(provider.models.first.name, 'Custom Mobile Vision V1');
      expect(provider.models.first.creatorEmail, 'author@broml.ai');
    });

    test('Batch imports GitHub repositories into the Hub', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      final newRepo = GithubRepo(
        id: 'gh-test-999',
        name: 'New-Novel-Architecture',
        fullName: 'research/novel-architecture',
        description: 'New deep learning model for audio synthesis',
        htmlUrl: 'https://github.com/research/novel-architecture',
        stars: 5400,
        forks: 620,
        language: 'Python',
        topics: ['audio', 'tts'],
        ownerName: 'research',
        ownerAvatarUrl: '',
      );

      final count = await provider.importGithubRepos(
        [newRepo],
        creatorId: 'tester-uid',
        creatorEmail: 'tester@broml.ai',
      );

      expect(count, 1);
      expect(provider.models.any((m) => m.name.contains('New Novel Architecture')), isTrue);
    });

    test('Updates an existing model when authorized', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      await provider.createModel(
        name: 'Model To Update',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 90.0,
        latencyMs: 25,
        version: '1.0.0',
        description: 'Initial model description',
        datasetName: 'Dataset A',
        creatorId: 'author-uid-1',
        creatorEmail: 'author@broml.ai',
      );

      final created = provider.models.firstWhere((m) => m.name == 'Model To Update');

      final updateSuccess = await provider.updateModel(
        created,
        name: 'Updated Model Name V2',
        category: 'Computer Vision',
        framework: 'ONNX',
        accuracy: 94.5,
        latencyMs: 18,
        version: '2.0.0',
        description: 'Optimized ONNX export description',
        datasetName: 'Dataset A Extended',
        currentUserId: 'author-uid-1',
        currentUserEmail: 'author@broml.ai',
      );

      expect(updateSuccess, isTrue);
      final updated = provider.models.firstWhere((m) => m.id == created.id);
      expect(updated.name, 'Updated Model Name V2');
      expect(updated.framework, 'ONNX');
      expect(updated.accuracy, 94.5);
      expect(updated.version, '2.0.0');
    });

    test('Integrates GitHub AI/ML foundation models across all 5 ML categories', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      // Check total models count includes canonical verified models
      expect(provider.totalModelsCount, greaterThanOrEqualTo(25));
      expect(provider.githubModelsCount, greaterThanOrEqualTo(10));

      // 1. Computer Vision
      provider.setSelectedCategory('Computer Vision');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('yolo')), isTrue);
      expect(provider.models.any((m) => m.category == 'Computer Vision'), isTrue);

      // 2. Natural Language Processing
      provider.setSelectedCategory('Natural Language Processing');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('deepseek')), isTrue);
      expect(provider.models.any((m) => m.name.toLowerCase().contains('llama')), isTrue);
      expect(provider.models.any((m) => m.category == 'Natural Language Processing'), isTrue);

      // 3. Audio & Speech
      provider.setSelectedCategory('Audio & Speech');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('whisper')), isTrue);
      expect(provider.models.any((m) => m.category == 'Audio & Speech'), isTrue);

      // 4. Reinforcement Learning
      provider.setSelectedCategory('Reinforcement Learning');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('stable baselines') || m.name.toLowerCase().contains('cleanrl')), isTrue);
      expect(provider.models.any((m) => m.category == 'Reinforcement Learning'), isTrue);

      // 5. Tabular ML
      provider.setSelectedCategory('Tabular ML');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('xgboost') || m.name.toLowerCase().contains('lightgbm')), isTrue);
      expect(provider.models.any((m) => m.category == 'Tabular ML'), isTrue);

      // 6. Source Filtering: GitHub Zoo vs Hugging Face Hub vs Custom Models
      provider.setSelectedCategory('All');
      provider.setSelectedSource('GitHub Zoo');
      expect(provider.models.every((m) => m.githubUrl.isNotEmpty), isTrue);

      provider.setSelectedSource('Hugging Face Hub');
      expect(provider.models.every((m) => m.id.startsWith('hf-') || m.githubUrl.contains('huggingface.co')), isTrue);

      // 7. Search query normalization (hyphen, spaces, case insensitivity)
      provider.setSelectedSource('All');
      provider.setSearchQuery('deepseek');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('deepseek')), isTrue);

      provider.setSearchQuery('xgboost');
      expect(provider.models.any((m) => m.name.toLowerCase().contains('xgboost')), isTrue);
    });

    test('Properly categorizes User Models, My Models, and ML Domain categories', () async {
      final provider = ModelProvider();
      await provider.loadModels();

      // Verify domain categories contain only actual ML categories (no 'Saved' or 'All')
      expect(provider.domainCategories, contains('Computer Vision'));
      expect(provider.domainCategories, contains('Natural Language Processing'));
      expect(provider.domainCategories, contains('Audio & Speech'));
      expect(provider.domainCategories, contains('Reinforcement Learning'));
      expect(provider.domainCategories, contains('Tabular ML'));
      expect(provider.domainCategories.contains('All'), isFalse);
      expect(provider.domainCategories.contains('Saved'), isFalse);
      expect(provider.domainCategories.contains('My Models'), isFalse);

      // Verify sources include user models and external sources
      expect(provider.displaySources, contains('All'));
      expect(provider.displaySources, contains('My Models'));
      expect(provider.displaySources, contains('User Models'));
      expect(provider.displaySources, contains('Hugging Face Hub'));
      expect(provider.displaySources, contains('GitHub Zoo'));

      // Create a user model with specific user ownership
      await provider.createModel(
        name: 'My Special Drone Vision Model',
        category: 'Computer Vision',
        framework: 'PyTorch',
        accuracy: 94.5,
        latencyMs: 12,
        version: '1.0.0',
        description: 'Drone obstacle detection model for low-altitude flight.',
        datasetName: 'UAV-Vision',
        creatorId: 'drone-dev-01',
        creatorEmail: 'pilot@broml.ai',
      );

      // Filter by User Models
      provider.setSelectedSource('User Models');
      expect(provider.models.isNotEmpty, isTrue);
      for (final m in provider.models) {
        expect(m.isUserModel, isTrue);
      }

      // Set current user context
      provider.updateCurrentUser(userId: 'drone-dev-01', userEmail: 'pilot@broml.ai');
      expect(provider.myModelsCount, greaterThanOrEqualTo(1));

      // Filter by My Models
      provider.setSelectedSource('My Models');
      expect(provider.models.isNotEmpty, isTrue);
      expect(provider.models.any((m) => m.name == 'My Special Drone Vision Model'), isTrue);
      for (final m in provider.models) {
        expect(m.isCreatedBy('drone-dev-01', 'pilot@broml.ai'), isTrue);
      }
    });
  });
}
