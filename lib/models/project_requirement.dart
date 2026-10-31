/// Project requirement specification for BroML Decision Intelligence (Blueprint 1.0)
class ProjectRequirement {
  final String id;
  final String task;
  final String targetPlatform;
  final int availableRamBytes;
  final int availableVramBytes;
  final bool cpuOnly;
  final int? maxModelSizeBytes;
  final int? maxLatencyMs;
  final List<String> allowedLicenses;
  final double performanceWeight;
  final double hardwareWeight;
  final double latencyWeight;
  final double efficiencyWeight;

  const ProjectRequirement({
    required this.id,
    required this.task,
    this.targetPlatform = 'Edge / Mobile',
    this.availableRamBytes = 4294967296, // 4 GB
    this.availableVramBytes = 0,
    this.cpuOnly = true,
    this.maxModelSizeBytes,
    this.maxLatencyMs,
    this.allowedLicenses = const [],
    this.performanceWeight = 0.35,
    this.hardwareWeight = 0.30,
    this.latencyWeight = 0.20,
    this.efficiencyWeight = 0.15,
  });

  /// Initial supported tasks from BroML Blueprint Section 1.3
  static const List<String> supportedTasks = [
    'Image Classification',
    'Object Detection',
    'Text Classification',
    'Sentiment Analysis',
    'Text Embedding',
  ];

  static const List<String> supportedPlatforms = [
    'Edge / Mobile',
    'Embedded Device (Raspberry Pi)',
    'Standard CPU Server',
    'Cloud GPU (T4 / A10G)',
    'Developer Workstation',
  ];

  static const List<String> commonLicenses = [
    'Apache-2.0',
    'MIT',
    'BSD-3-Clause',
    'AGPL-3.0',
    'OpenRAIL',
  ];

  double get availableRamGb => availableRamBytes / (1024 * 1024 * 1024);
  double get availableVramGb => availableVramBytes / (1024 * 1024 * 1024);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task': task,
      'targetPlatform': targetPlatform,
      'availableRamBytes': availableRamBytes,
      'availableVramBytes': availableVramBytes,
      'cpuOnly': cpuOnly,
      'maxModelSizeBytes': maxModelSizeBytes,
      'maxLatencyMs': maxLatencyMs,
      'allowedLicenses': allowedLicenses,
      'performanceWeight': performanceWeight,
      'hardwareWeight': hardwareWeight,
      'latencyWeight': latencyWeight,
      'efficiencyWeight': efficiencyWeight,
    };
  }

  factory ProjectRequirement.fromJson(Map<String, dynamic> json) {
    return ProjectRequirement(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      task: json['task'] ?? 'Image Classification',
      targetPlatform: json['targetPlatform'] ?? 'Edge / Mobile',
      availableRamBytes: (json['availableRamBytes'] is num)
          ? (json['availableRamBytes'] as num).toInt()
          : 4294967296,
      availableVramBytes: (json['availableVramBytes'] is num)
          ? (json['availableVramBytes'] as num).toInt()
          : 0,
      cpuOnly: json['cpuOnly'] ?? true,
      maxModelSizeBytes: (json['maxModelSizeBytes'] is num)
          ? (json['maxModelSizeBytes'] as num).toInt()
          : null,
      maxLatencyMs: (json['maxLatencyMs'] is num)
          ? (json['maxLatencyMs'] as num).toInt()
          : null,
      allowedLicenses: (json['allowedLicenses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      performanceWeight: (json['performanceWeight'] is num)
          ? (json['performanceWeight'] as num).toDouble()
          : 0.35,
      hardwareWeight: (json['hardwareWeight'] is num)
          ? (json['hardwareWeight'] as num).toDouble()
          : 0.30,
      latencyWeight: (json['latencyWeight'] is num)
          ? (json['latencyWeight'] as num).toDouble()
          : 0.20,
      efficiencyWeight: (json['efficiencyWeight'] is num)
          ? (json['efficiencyWeight'] as num).toDouble()
          : 0.15,
    );
  }

  ProjectRequirement copyWith({
    String? id,
    String? task,
    String? targetPlatform,
    int? availableRamBytes,
    int? availableVramBytes,
    bool? cpuOnly,
    int? maxModelSizeBytes,
    int? maxLatencyMs,
    List<String>? allowedLicenses,
    double? performanceWeight,
    double? hardwareWeight,
    double? latencyWeight,
    double? efficiencyWeight,
  }) {
    return ProjectRequirement(
      id: id ?? this.id,
      task: task ?? this.task,
      targetPlatform: targetPlatform ?? this.targetPlatform,
      availableRamBytes: availableRamBytes ?? this.availableRamBytes,
      availableVramBytes: availableVramBytes ?? this.availableVramBytes,
      cpuOnly: cpuOnly ?? this.cpuOnly,
      maxModelSizeBytes: maxModelSizeBytes ?? this.maxModelSizeBytes,
      maxLatencyMs: maxLatencyMs ?? this.maxLatencyMs,
      allowedLicenses: allowedLicenses ?? this.allowedLicenses,
      performanceWeight: performanceWeight ?? this.performanceWeight,
      hardwareWeight: hardwareWeight ?? this.hardwareWeight,
      latencyWeight: latencyWeight ?? this.latencyWeight,
      efficiencyWeight: efficiencyWeight ?? this.efficiencyWeight,
    );
  }
}

