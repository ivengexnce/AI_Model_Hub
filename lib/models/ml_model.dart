class MlModel {
  final String id;
  final String name;
  final String category;
  final String task;
  final String framework;
  final double accuracy;
  final int latencyMs;
  final String version;
  final String description;
  final String datasetName;
  final String imageUrl;
  final String githubUrl;
  final String creatorId;
  final String creatorEmail;

  // Technical Decision Intelligence Attributes (BroML Blueprint 1.0)
  final int parameterCount;
  final int modelSizeBytes;
  final int minRamBytes;
  final int minVramBytes;
  final String license;
  final String benchmarkDataset;
  final String evidenceSourceUrl;
  final String verificationStatus;

  MlModel({
    required this.id,
    required this.name,
    required this.category,
    this.task = 'Image Classification',
    required this.framework,
    required this.accuracy,
    required this.latencyMs,
    required this.version,
    required this.description,
    required this.datasetName,
    required this.imageUrl,
    this.githubUrl = '',
    this.creatorId = '',
    this.creatorEmail = '',
    this.parameterCount = 25000000,
    this.modelSizeBytes = 100000000,
    this.minRamBytes = 2147483648, // 2 GB default
    this.minVramBytes = 0,
    this.license = 'Apache-2.0',
    this.benchmarkDataset = 'Benchmark Dataset',
    this.evidenceSourceUrl = '',
    this.verificationStatus = 'verified',
  });

  factory MlModel.fromJson(Map<String, dynamic> json) {
    return MlModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? json['title'] ?? 'Unnamed Model',
      category: json['category'] ?? 'Computer Vision',
      task: json['task'] ?? json['taskType'] ?? _inferTask(json['category'] ?? 'Computer Vision'),
      framework: json['framework'] ?? 'PyTorch',
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : 92.5,
      latencyMs: (json['latencyMs'] is num) ? (json['latencyMs'] as num).toInt() : 15,
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? 'No description provided.',
      datasetName: json['datasetName'] ?? 'Custom Dataset',
      imageUrl: json['imageUrl'] ?? json['thumbnail'] ?? 'https://picsum.photos/400/300',
      githubUrl: json['githubUrl'] ?? json['repoUrl'] ?? '',
      creatorId: json['creatorId']?.toString() ?? json['userId']?.toString() ?? '',
      creatorEmail: json['creatorEmail']?.toString() ?? '',
      parameterCount: (json['parameterCount'] is num) ? (json['parameterCount'] as num).toInt() : 25000000,
      modelSizeBytes: (json['modelSizeBytes'] is num) ? (json['modelSizeBytes'] as num).toInt() : 100000000,
      minRamBytes: (json['minRamBytes'] is num) ? (json['minRamBytes'] as num).toInt() : 2147483648,
      minVramBytes: (json['minVramBytes'] is num) ? (json['minVramBytes'] as num).toInt() : 0,
      license: json['license'] ?? 'Apache-2.0',
      benchmarkDataset: json['benchmarkDataset'] ?? json['datasetName'] ?? 'Standard Benchmark',
      evidenceSourceUrl: json['evidenceSourceUrl'] ?? json['githubUrl'] ?? '',
      verificationStatus: json['verificationStatus'] ?? 'verified',
    );
  }

  static String _inferTask(String category) {
    switch (category) {
      case 'Computer Vision':
        return 'Image Classification';
      case 'Natural Language Processing':
        return 'Text Classification';
      case 'Audio & Speech':
        return 'Speech Recognition';
      case 'Reinforcement Learning':
        return 'Policy Optimization';
      case 'Tabular ML':
        return 'Tabular Classification';
      default:
        return 'Image Classification';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'task': task,
      'framework': framework,
      'accuracy': accuracy,
      'latencyMs': latencyMs,
      'version': version,
      'description': description,
      'datasetName': datasetName,
      'imageUrl': imageUrl,
      'githubUrl': githubUrl,
      'creatorId': creatorId,
      'creatorEmail': creatorEmail,
      'parameterCount': parameterCount,
      'modelSizeBytes': modelSizeBytes,
      'minRamBytes': minRamBytes,
      'minVramBytes': minVramBytes,
      'license': license,
      'benchmarkDataset': benchmarkDataset,
      'evidenceSourceUrl': evidenceSourceUrl,
      'verificationStatus': verificationStatus,
    };
  }

  MlModel copyWith({
    String? id,
    String? name,
    String? category,
    String? task,
    String? framework,
    double? accuracy,
    int? latencyMs,
    String? version,
    String? description,
    String? datasetName,
    String? imageUrl,
    String? githubUrl,
    String? creatorId,
    String? creatorEmail,
    int? parameterCount,
    int? modelSizeBytes,
    int? minRamBytes,
    int? minVramBytes,
    String? license,
    String? benchmarkDataset,
    String? evidenceSourceUrl,
    String? verificationStatus,
  }) {
    return MlModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      task: task ?? this.task,
      framework: framework ?? this.framework,
      accuracy: accuracy ?? this.accuracy,
      latencyMs: latencyMs ?? this.latencyMs,
      version: version ?? this.version,
      description: description ?? this.description,
      datasetName: datasetName ?? this.datasetName,
      imageUrl: imageUrl ?? this.imageUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorEmail: creatorEmail ?? this.creatorEmail,
      parameterCount: parameterCount ?? this.parameterCount,
      modelSizeBytes: modelSizeBytes ?? this.modelSizeBytes,
      minRamBytes: minRamBytes ?? this.minRamBytes,
      minVramBytes: minVramBytes ?? this.minVramBytes,
      license: license ?? this.license,
      benchmarkDataset: benchmarkDataset ?? this.benchmarkDataset,
      evidenceSourceUrl: evidenceSourceUrl ?? this.evidenceSourceUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  // --- Display & Decision Helpers ---
  String get formattedParameters {
    if (parameterCount >= 1000000000) {
      return '${(parameterCount / 1000000000).toStringAsFixed(1)}B params';
    }
    if (parameterCount >= 1000000) {
      return '${(parameterCount / 1000000).toStringAsFixed(1)}M params';
    }
    if (parameterCount >= 1000) {
      return '${(parameterCount / 1000).toStringAsFixed(0)}k params';
    }
    return '$parameterCount params';
  }

  String get formattedModelSize {
    final mb = modelSizeBytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedRamRequirement {
    final gb = minRamBytes / (1024 * 1024 * 1024);
    if (gb < 1.0) {
      final mb = minRamBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(0)} MB RAM';
    }
    return '${gb.toStringAsFixed(1)} GB RAM';
  }

  /// Whether this model originates from Hugging Face Hub
  bool get isHuggingFace => id.startsWith('hf-') || githubUrl.contains('huggingface.co');

  /// Whether this model originates from GitHub AI Zoo
  bool get isGitHub => (id.startsWith('gh-') || githubUrl.contains('github.com')) && !isHuggingFace;

  /// Whether this model was created by a user / custom upload
  bool get isUserModel =>
      creatorId.isNotEmpty ||
      creatorEmail.isNotEmpty ||
      (!id.startsWith('gh-') && !id.startsWith('hf-') && !id.startsWith('seed-') && !id.startsWith('canon-'));

  /// Checks if this model was authored by the specified user
  bool isCreatedBy(String? userId, String? userEmail) {
    if (userId != null && userId.isNotEmpty && creatorId.isNotEmpty && creatorId == userId) {
      return true;
    }
    if (userEmail != null &&
        userEmail.isNotEmpty &&
        creatorEmail.isNotEmpty &&
        creatorEmail.toLowerCase() == userEmail.toLowerCase()) {
      return true;
    }
    return false;
  }

  /// Human-readable origin label for UI badges
  String get originLabel {
    if (isHuggingFace) return 'Hugging Face';
    if (isGitHub) return 'GitHub';
    if (creatorEmail.isNotEmpty) return creatorEmail;
    if (isUserModel) return 'User Model';
    return 'Verified Canonical';
  }

  /// Laptop CPU Feasibility Assessment
  /// Evaluates whether this model can run on typical budget/standard laptops without lag or freezing
  String get laptopFeasibilityBadge {
    if (minVramBytes > 0) return 'Requires Dedicated GPU';
    if (latencyMs <= 30 && minRamBytes <= 1073741824) {
      return 'Laptop Ready (Zero Lag)';
    }
    if (latencyMs <= 80 && minRamBytes <= 3221225472) {
      return 'Standard Laptop';
    }
    return 'Heavy on Laptop CPU';
  }

  /// Color value associated with laptop feasibility
  int get laptopFeasibilityColorValue {
    if (minVramBytes > 0) return 0xFFDC2626; // Red
    if (latencyMs <= 30 && minRamBytes <= 1073741824) {
      return 0xFF10B981; // Green
    }
    if (latencyMs <= 80 && minRamBytes <= 3221225472) {
      return 0xFFF59E0B; // Amber
    }
    return 0xFFEF4444; // Orange/Red
  }
}
