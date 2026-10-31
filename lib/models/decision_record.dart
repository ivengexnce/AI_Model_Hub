import 'project_requirement.dart';

/// Preserves the historical model selection decision and evidence snapshot (Blueprint 6.2)
class DecisionRecord {
  final String id;
  final String userId;
  final ProjectRequirement requirement;
  final String selectedModelId;
  final String selectedModelName;
  final String selectedModelTask;
  final String framework;
  final String license;
  final double score;
  final int rank;
  final String decisionReason;
  final List<String> tradeoffs;
  final String evidenceSource;
  final String evidenceConfidence;
  final DateTime timestamp;

  DecisionRecord({
    required this.id,
    required this.userId,
    required this.requirement,
    required this.selectedModelId,
    required this.selectedModelName,
    required this.selectedModelTask,
    required this.framework,
    required this.license,
    required this.score,
    required this.rank,
    required this.decisionReason,
    required this.tradeoffs,
    required this.evidenceSource,
    required this.evidenceConfidence,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'requirement': requirement.toJson(),
      'selectedModelId': selectedModelId,
      'selectedModelName': selectedModelName,
      'selectedModelTask': selectedModelTask,
      'framework': framework,
      'license': license,
      'score': score,
      'rank': rank,
      'decisionReason': decisionReason,
      'tradeoffs': tradeoffs,
      'evidenceSource': evidenceSource,
      'evidenceConfidence': evidenceConfidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DecisionRecord.fromJson(Map<String, dynamic> json) {
    return DecisionRecord(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId'] ?? 'user',
      requirement: ProjectRequirement.fromJson(
        json['requirement'] as Map<String, dynamic>? ?? {},
      ),
      selectedModelId: json['selectedModelId'] ?? '',
      selectedModelName: json['selectedModelName'] ?? 'Selected Model',
      selectedModelTask: json['selectedModelTask'] ?? 'Image Classification',
      framework: json['framework'] ?? 'PyTorch',
      license: json['license'] ?? 'Apache-2.0',
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 85.0,
      rank: (json['rank'] is num) ? (json['rank'] as num).toInt() : 1,
      decisionReason: json['decisionReason'] ?? 'Meets project hardware and latency constraints.',
      tradeoffs: (json['tradeoffs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      evidenceSource: json['evidenceSource'] ?? '',
      evidenceConfidence: json['evidenceConfidence'] ?? 'High',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

