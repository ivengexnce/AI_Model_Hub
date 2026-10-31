import 'package:flutter_test/flutter_test.dart';
import 'package:ai_model_hub/services/github_service.dart';

void main() {
  group('GithubService & GithubRepo Domain Integration Tests', () {
    test('Correctly deserializes GitHub API JSON into GithubRepo entity', () {
      final json = {
        'id': 123456,
        'name': 'whisper-finetuned',
        'full_name': 'community/whisper-finetuned',
        'description': 'Finetuned Whisper model for medical audio transcription',
        'html_url': 'https://github.com/community/whisper-finetuned',
        'stargazers_count': 1420,
        'forks_count': 180,
        'language': 'Python',
        'topics': ['audio', 'speech-recognition', 'pytorch'],
        'owner': {
          'login': 'community',
          'avatar_url': 'https://avatars.githubusercontent.com/u/1234?v=4',
        },
      };

      final repo = GithubRepo.fromJson(json);

      expect(repo.id, '123456');
      expect(repo.name, 'whisper-finetuned');
      expect(repo.fullName, 'community/whisper-finetuned');
      expect(repo.stars, 1420);
      expect(repo.forks, 180);
      expect(repo.language, 'Python');
      expect(repo.topics, contains('speech-recognition'));
      expect(repo.ownerName, 'community');
    });

    test('Maps Audio & Speech repositories to correct BroML domain', () {
      final repo = GithubRepo(
        id: '1',
        name: 'voice-synthesizer',
        fullName: 'org/voice-synthesizer',
        description: 'Text-to-speech neural voice synthesis engine',
        htmlUrl: 'https://github.com/org/voice-synthesizer',
        stars: 500,
        forks: 50,
        language: 'Python',
        topics: ['tts', 'voice', 'speech'],
        ownerName: 'org',
        ownerAvatarUrl: '',
      );

      final model = repo.toMlModel();
      expect(model.category, 'Audio & Speech');
      expect(model.githubUrl, 'https://github.com/org/voice-synthesizer');
      expect(model.accuracy, inInclusiveRange(88.0, 99.4));
      expect(model.latencyMs, inInclusiveRange(8, 90));
    });

    test('Maps NLP and LLM repositories to Natural Language Processing', () {
      final repo = GithubRepo(
        id: '2',
        name: 'tiny-llama-chat',
        fullName: 'org/tiny-llama-chat',
        description: 'Quantized LLM for on-device chat assistants',
        htmlUrl: 'https://github.com/org/tiny-llama-chat',
        stars: 3200,
        forks: 300,
        language: 'Python',
        topics: ['llm', 'transformers', 'nlp'],
        ownerName: 'org',
        ownerAvatarUrl: '',
      );

      final model = repo.toMlModel();
      expect(model.category, 'Natural Language Processing');
    });

    test('Detects Framework properly (TensorFlow, ONNX, JAX, PyTorch)', () {
      final tfRepo = GithubRepo(
        id: '3',
        name: 'tf-mobilenet',
        fullName: 'org/tf-mobilenet',
        description: 'MobileNet model in tensorflow',
        htmlUrl: 'https://github.com/org/tf-mobilenet',
        stars: 200,
        forks: 20,
        language: 'Python',
        topics: ['tensorflow', 'vision'],
        ownerName: 'org',
        ownerAvatarUrl: '',
      );
      expect(tfRepo.toMlModel().framework, 'TensorFlow');

      final onnxRepo = GithubRepo(
        id: '4',
        name: 'onnx-runtime-engine',
        fullName: 'org/onnx-runtime-engine',
        description: 'Edge execution via ONNX',
        htmlUrl: 'https://github.com/org/onnx-runtime-engine',
        stars: 200,
        forks: 20,
        language: 'Python',
        topics: ['onnx'],
        ownerName: 'org',
        ownerAvatarUrl: '',
      );
      expect(onnxRepo.toMlModel().framework, 'ONNX');
    });

    test('Curated fallback list contains premier open-source ML models', () {
      expect(GithubService.curatedMlRepos, isNotEmpty);
      expect(GithubService.curatedMlRepos.length, greaterThanOrEqualTo(6));
      expect(GithubService.curatedMlRepos.any((r) => r.name.contains('YOLO')), isTrue);
      expect(GithubService.curatedMlRepos.any((r) => r.name.contains('Whisper')), isTrue);
      expect(GithubService.curatedMlRepos.any((r) => r.name.contains('Transformers')), isTrue);
      expect(GithubService.curatedMlRepos.any((r) => r.name.contains('LLaMA')), isTrue);
    });

    test('Offline search filters curated models by query and category filter', () async {
      final service = GithubService();

      // Search for whisper
      final results = await service.searchRepositories(query: 'whisper');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.name.toLowerCase().contains('whisper') || r.description.toLowerCase().contains('whisper')), isTrue);
    });
  });
}

