import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ml_model.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  final List<MlModel> _localModels = [
    MlModel(
      id: '1',
      name: 'YOLOv8 Real-Time Object Detector',
      category: 'Computer Vision',
      framework: 'PyTorch',
      accuracy: 94.2,
      latencyMs: 12,
      version: '8.1.0',
      description: 'State-of-the-art real-time object detection model trained on COCO dataset with custom fine-tuning.',
      datasetName: 'COCO 2017 & Custom Drone Dataset',
      imageUrl: 'https://picsum.photos/seed/yolo/600/400',
    ),
    MlModel(
      id: '2',
      name: 'ResNet-50 Plant Disease Classifier',
      category: 'Computer Vision',
      framework: 'TensorFlow',
      accuracy: 96.8,
      latencyMs: 18,
      version: '2.0.1',
      description: 'Deep residual network fine-tuned to classify 38 plant leaf disease classes from smartphone camera images.',
      datasetName: 'PlantVillage Dataset (54,305 images)',
      imageUrl: 'https://picsum.photos/seed/plant/600/400',
    ),
    MlModel(
      id: '3',
      name: 'LLaMA-3 Quantized Code Assistant',
      category: 'Natural Language Processing',
      framework: 'ONNX',
      accuracy: 89.5,
      latencyMs: 45,
      version: '3.0.0',
      description: '4-bit quantized LLM optimized for on-device code completion and technical documentation summarization.',
      datasetName: 'HumanEval & Stack Exchange Quality Corpus',
      imageUrl: 'https://picsum.photos/seed/llama/600/400',
    ),
    MlModel(
      id: '4',
      name: 'Whisper Speech Recognizer',
      category: 'Audio & Speech',
      framework: 'PyTorch',
      accuracy: 95.1,
      latencyMs: 30,
      version: '1.4.0',
      description: 'Multilingual automatic speech recognition (ASR) model with automated noise cancellation and punctuation.',
      datasetName: 'LibriSpeech & Common Voice 11',
      imageUrl: 'https://picsum.photos/seed/speech/600/400',
    ),
  ];

  /// HTTP GET - Fetch list of ML Models
  Future<List<MlModel>> fetchModels() async {
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        return List<MlModel>.from(_localModels);
      } else {
        return List<MlModel>.from(_localModels);
      }
    } catch (e) {
      return List<MlModel>.from(_localModels);
    }
  }

  /// HTTP POST - Create & register a new ML Model
  Future<MlModel> createModel(MlModel model) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'title': model.name,
          'body': model.description,
          'userId': 1,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Success response
      }

      final newModel = model.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      _localModels.insert(0, newModel);
      return newModel;
    } catch (e) {
      final newModel = model.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _localModels.insert(0, newModel);
      return newModel;
    }
  }

  /// HTTP PUT - Update an existing ML Model
  Future<MlModel> updateModel(MlModel model) async {
    try {
      final url = Uri.parse('$baseUrl/1');
      await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'id': 1,
          'title': model.name,
          'body': model.description,
          'userId': 1,
        }),
      );

      final index = _localModels.indexWhere((m) => m.id == model.id);
      if (index != -1) {
        _localModels[index] = model;
      }
      return model;
    } catch (e) {
      final index = _localModels.indexWhere((m) => m.id == model.id);
      if (index != -1) {
        _localModels[index] = model;
      }
      return model;
    }
  }

  /// HTTP DELETE - Unregister/Delete an ML Model
  Future<bool> deleteModel(String id) async {
    try {
      final url = Uri.parse('$baseUrl/1');
      await http.delete(url);

      _localModels.removeWhere((m) => m.id == id);
      return true;
    } catch (e) {
      _localModels.removeWhere((m) => m.id == id);
      return true;
    }
  }
}
