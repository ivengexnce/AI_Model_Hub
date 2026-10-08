import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ml_model.dart';

class GithubRepo {
  final String id;
  final String name;
  final String fullName;
  final String description;
  final String htmlUrl;
  final int stars;
  final int forks;
  final String language;
  final List<String> topics;
  final String ownerName;
  final String ownerAvatarUrl;

  GithubRepo({
    required this.id,
    required this.name,
    required this.fullName,
    required this.description,
    required this.htmlUrl,
    required this.stars,
    required this.forks,
    required this.language,
    required this.topics,
    required this.ownerName,
    required this.ownerAvatarUrl,
  });

  factory GithubRepo.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? {};
    final rawTopics = json['topics'] as List<dynamic>? ?? [];

    return GithubRepo(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unnamed Repo',
      fullName: json['full_name'] ?? json['name'] ?? '',
      description: json['description'] ?? 'No description provided.',
      htmlUrl: json['html_url'] ?? 'https://github.com',
      stars: (json['stargazers_count'] is num) ? (json['stargazers_count'] as num).toInt() : 0,
      forks: (json['forks_count'] is num) ? (json['forks_count'] as num).toInt() : 0,
      language: json['language'] ?? 'Python',
      topics: rawTopics.map((t) => t.toString()).toList(),
      ownerName: owner['login'] ?? 'developer',
      ownerAvatarUrl: owner['avatar_url'] ?? 'https://avatars.githubusercontent.com/u/9919?s=200&v=4',
    );
  }

  /// Converts this GitHub repository into an MlModel for BroML Hub
  MlModel toMlModel() {
    final lowerDesc = description.toLowerCase();
    final lowerTopics = topics.map((t) => t.toLowerCase()).toList();

    // 1. Detect Category
    String category = 'Computer Vision';
    if (lowerTopics.any((t) => t.contains('audio') || t.contains('speech') || t.contains('asr') || t.contains('voice') || t.contains('tts')) ||
        lowerDesc.contains('speech') || lowerDesc.contains('whisper') || lowerDesc.contains('audio')) {
      category = 'Audio & Speech';
    } else if (lowerTopics.any((t) => t.contains('nlp') || t.contains('llm') || t.contains('language') || t.contains('gpt') || t.contains('llama') || t.contains('text') || t.contains('transformers')) ||
        lowerDesc.contains('llm') || lowerDesc.contains('language model') || lowerDesc.contains('gpt') || lowerDesc.contains('llama') || lowerDesc.contains('nlp')) {
      category = 'Natural Language Processing';
    } else if (lowerTopics.any((t) => t.contains('reinforcement') || t.contains('rl') || t.contains('gym')) ||
        lowerDesc.contains('reinforcement') || lowerDesc.contains('q-learning')) {
      category = 'Reinforcement Learning';
    } else if (lowerTopics.any((t) => t.contains('tabular') || t.contains('dataframe') || t.contains('xgboost') || t.contains('lightgbm')) ||
        lowerDesc.contains('tabular') || lowerDesc.contains('classification')) {
      category = 'Tabular ML';
    } else {
      category = 'Computer Vision';
    }

    // 2. Detect Framework
    String framework = 'PyTorch';
    if (lowerTopics.contains('tensorflow') || lowerDesc.contains('tensorflow')) {
      framework = 'TensorFlow';
    } else if (lowerTopics.contains('onnx') || lowerDesc.contains('onnx')) {
      framework = 'ONNX';
    } else if (lowerTopics.contains('jax') || lowerDesc.contains('jax')) {
      framework = 'JAX';
    } else if (lowerTopics.contains('keras') || lowerDesc.contains('keras')) {
      framework = 'Keras';
    } else {
      framework = 'PyTorch';
    }

    // 3. Format Stars into Accuracy & Latency benchmarks
    final accuracy = (92.0 + (stars % 70) / 10.0).clamp(88.0, 99.4);
    final latency = (12 + (stars % 38)).clamp(8, 90);

    // 4. Clean human-readable display name
    String cleanName = name.replaceAll('-', ' ').replaceAll('_', ' ');
    cleanName = cleanName.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');

    return MlModel(
      id: '',
      name: cleanName,
      category: category,
      framework: framework,
      accuracy: double.parse(accuracy.toStringAsFixed(1)),
      latencyMs: latency,
      version: '1.0.0',
      description: description,
      datasetName: 'GitHub: $fullName',
      imageUrl: ownerAvatarUrl.isNotEmpty ? ownerAvatarUrl : 'https://picsum.photos/seed/$name/600/400',
      githubUrl: htmlUrl,
    );
  }
}

class GithubService {
  static const String _searchUrl = 'https://api.github.com/search/repositories';

  /// Curated list of premier open-source ML models for instant offline browsing
  static final List<GithubRepo> curatedMlRepos = [
    GithubRepo(
      id: 'gh-1',
      name: 'YOLOv11 Object Detection & Segmentation',
      fullName: 'ultralytics/ultralytics',
      description: 'Ultralytics YOLO11: Cutting-edge real-time object detection, instance segmentation, and pose estimation model.',
      htmlUrl: 'https://github.com/ultralytics/ultralytics',
      stars: 42100,
      forks: 8900,
      language: 'Python',
      topics: ['computer-vision', 'yolo', 'pytorch', 'object-detection'],
      ownerName: 'ultralytics',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/26833433?v=4',
    ),
    GithubRepo(
      id: 'gh-2',
      name: 'OpenAI Whisper Robust Speech Recognition',
      fullName: 'openai/whisper',
      description: 'Robust Speech Recognition via Large-Scale Weak Supervision with state-of-the-art multilingual transcription.',
      htmlUrl: 'https://github.com/openai/whisper',
      stars: 78500,
      forks: 9200,
      language: 'Python',
      topics: ['speech-recognition', 'audio', 'pytorch', 'asr', 'transcription'],
      ownerName: 'openai',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/14957082?v=4',
    ),
    GithubRepo(
      id: 'gh-3',
      name: 'HuggingFace Transformers Core Model Hub',
      fullName: 'huggingface/transformers',
      description: 'State-of-the-art Machine Learning for Pytorch, TensorFlow, and JAX supporting thousands of pretrained models.',
      htmlUrl: 'https://github.com/huggingface/transformers',
      stars: 139000,
      forks: 26000,
      language: 'Python',
      topics: ['nlp', 'deep-learning', 'pytorch', 'transformers', 'bert', 'llm'],
      ownerName: 'huggingface',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/25720743?v=4',
    ),
    GithubRepo(
      id: 'gh-4',
      name: 'Meta LLaMA 3 Generative Foundation Model',
      fullName: 'meta-llama/llama3',
      description: 'Meta Llama 3 language models: High-performance open-weight LLMs trained on over 15 trillion tokens.',
      htmlUrl: 'https://github.com/meta-llama/llama3',
      stars: 38400,
      forks: 4100,
      language: 'Python',
      topics: ['llm', 'generative-ai', 'nlp', 'pytorch', 'llama'],
      ownerName: 'meta-llama',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/142994464?v=4',
    ),
    GithubRepo(
      id: 'gh-5',
      name: 'AUTOMATIC1111 Stable Diffusion WebUI',
      fullName: 'AUTOMATIC1111/stable-diffusion-webui',
      description: 'Stable Diffusion web UI for latent diffusion text-to-image generation and neural artwork synthesis.',
      htmlUrl: 'https://github.com/AUTOMATIC1111/stable-diffusion-webui',
      stars: 148000,
      forks: 28000,
      language: 'Python',
      topics: ['diffusion-models', 'computer-vision', 'pytorch', 'generative-art'],
      ownerName: 'AUTOMATIC1111',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/82946571?v=4',
    ),
    GithubRepo(
      id: 'gh-6',
      name: 'vLLM High-Throughput LLM Serving',
      fullName: 'vllm-project/vllm',
      description: 'A high-throughput and memory-efficient inference and serving engine for LLMs featuring PagedAttention.',
      htmlUrl: 'https://github.com/vllm-project/vllm',
      stars: 36200,
      forks: 5100,
      language: 'Python',
      topics: ['llm-inference', 'nlp', 'pytorch', 'cuda', 'paged-attention'],
      ownerName: 'vllm-project',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/137798991?v=4',
    ),
    GithubRepo(
      id: 'gh-7',
      name: 'Stable Baselines 3 Reinforcement Learning',
      fullName: 'DLR-RM/stable-baselines3',
      description: 'Reliable implementations of reinforcement learning algorithms in PyTorch (PPO, A2C, DDPG, SAC, TD3).',
      htmlUrl: 'https://github.com/DLR-RM/stable-baselines3',
      stars: 10400,
      forks: 2100,
      language: 'Python',
      topics: ['reinforcement-learning', 'gym', 'pytorch', 'rl', 'ppo'],
      ownerName: 'DLR-RM',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/23306161?v=4',
    ),
    GithubRepo(
      id: 'gh-8',
      name: 'Segment Anything Model (SAM 2)',
      fullName: 'facebookresearch/sam2',
      description: 'The SAM 2 foundation model for video and image segmentation in the wild with real-time zero-shot prompting.',
      htmlUrl: 'https://github.com/facebookresearch/sam2',
      stars: 19800,
      forks: 1800,
      language: 'Python',
      topics: ['computer-vision', 'segmentation', 'pytorch', 'sam', 'video-ai'],
      ownerName: 'facebookresearch',
      ownerAvatarUrl: 'https://avatars.githubusercontent.com/u/16943930?v=4',
    ),
  ];

  /// Searches GitHub repositories using query and optional topic filter
  Future<List<GithubRepo>> searchRepositories({
    String query = 'machine-learning',
    String? categoryFilter,
  }) async {
    String finalQuery = query.trim().isEmpty ? 'machine-learning' : query.trim();

    if (categoryFilter != null && categoryFilter != 'All') {
      switch (categoryFilter) {
        case 'Computer Vision':
          finalQuery += '+topic:computer-vision';
          break;
        case 'Natural Language Processing':
          finalQuery += '+topic:nlp';
          break;
        case 'Audio & Speech':
          finalQuery += '+topic:speech';
          break;
        case 'Reinforcement Learning':
          finalQuery += '+topic:reinforcement-learning';
          break;
        default:
          break;
      }
    }

    try {
      final uri = Uri.parse('$_searchUrl?q=$finalQuery&sort=stars&order=desc&per_page=20');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BroML-Mobile-App',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((item) => GithubRepo.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        debugPrint('GitHub API returned status ${response.statusCode}, using curated fallback.');
        return _filterCurated(query, categoryFilter);
      }
    } catch (e) {
      debugPrint('GitHub API search error ($e), using curated fallback.');
      return _filterCurated(query, categoryFilter);
    }
  }

  List<GithubRepo> _filterCurated(String query, String? categoryFilter) {
    return curatedMlRepos.where((repo) {
      final matchesQuery = query.isEmpty ||
          query == 'machine-learning' ||
          repo.name.toLowerCase().contains(query.toLowerCase()) ||
          repo.description.toLowerCase().contains(query.toLowerCase()) ||
          repo.topics.any((t) => t.toLowerCase().contains(query.toLowerCase()));

      if (categoryFilter == null || categoryFilter == 'All') return matchesQuery;

      final modelCategory = repo.toMlModel().category;
      return matchesQuery && modelCategory == categoryFilter;
    }).toList();
  }
}
