class MlModel {
  final String id;
  final String name;
  final String category;
  final String framework;
  final double accuracy;
  final int latencyMs;
  final String version;
  final String description;
  final String datasetName;
  final String imageUrl;

  MlModel({
    required this.id,
    required this.name,
    required this.category,
    required this.framework,
    required this.accuracy,
    required this.latencyMs,
    required this.version,
    required this.description,
    required this.datasetName,
    required this.imageUrl,
  });

  factory MlModel.fromJson(Map<String, dynamic> json) {
    return MlModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? json['title'] ?? 'Unnamed Model',
      category: json['category'] ?? 'Computer Vision',
      framework: json['framework'] ?? 'PyTorch',
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : 92.5,
      latencyMs: (json['latencyMs'] is num) ? (json['latencyMs'] as num).toInt() : 15,
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? 'No description provided.',
      datasetName: json['datasetName'] ?? 'Custom Dataset',
      imageUrl: json['imageUrl'] ?? json['thumbnail'] ?? 'https://picsum.photos/400/300',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'framework': framework,
      'accuracy': accuracy,
      'latencyMs': latencyMs,
      'version': version,
      'description': description,
      'datasetName': datasetName,
      'imageUrl': imageUrl,
    };
  }

  MlModel copyWith({
    String? id,
    String? name,
    String? category,
    String? framework,
    double? accuracy,
    int? latencyMs,
    String? version,
    String? description,
    String? datasetName,
    String? imageUrl,
  }) {
    return MlModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      framework: framework ?? this.framework,
      accuracy: accuracy ?? this.accuracy,
      latencyMs: latencyMs ?? this.latencyMs,
      version: version ?? this.version,
      description: description ?? this.description,
      datasetName: datasetName ?? this.datasetName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
