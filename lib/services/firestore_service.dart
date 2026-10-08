import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ml_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  bool get isAvailable => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>>? get _modelsRef {
    if (!isAvailable) return null;
    return FirebaseFirestore.instance.collection('models');
  }

  /// Initial starter models to seed into Firestore if the collection is newly created
  final List<MlModel> defaultStarterModels = [
    MlModel(
      id: 'yolov8-detector',
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
      id: 'resnet50-plant',
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
      id: 'llama3-code',
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
      id: 'whisper-asr',
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

  /// Fetch all models from Firestore. If empty, seeds initial models.
  Future<List<MlModel>?> fetchModels() async {
    if (!isAvailable) return null;
    try {
      final snapshot = await _modelsRef!.get();
      if (snapshot.docs.isEmpty) {
        // Seed default models into the new database
        debugPrint('Firestore "models" collection empty. Seeding initial models...');
        await seedDefaultModels();
        return defaultStarterModels;
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MlModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      return null;
    }
  }

  /// Real-time stream of ML models from Firestore
  Stream<List<MlModel>>? streamModels() {
    if (!isAvailable) return null;
    try {
      return _modelsRef!.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return MlModel.fromJson(data);
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore stream error: $e');
      return null;
    }
  }

  /// Create a new model document in Firestore
  Future<MlModel?> createModel(MlModel model) async {
    if (!isAvailable) return null;
    try {
      final data = model.toJson();
      data.remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();

      final docRef = await _modelsRef!.add(data);
      debugPrint('Model created in Firestore: ${docRef.id}');
      return model.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Firestore create error: $e');
      return null;
    }
  }

  /// Update an existing model document in Firestore
  Future<bool> updateModel(MlModel model) async {
    if (!isAvailable) return false;
    try {
      final data = model.toJson();
      data.remove('id');
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _modelsRef!.doc(model.id).set(data, SetOptions(merge: true));
      debugPrint('Model updated in Firestore: ${model.id}');
      return true;
    } catch (e) {
      debugPrint('Firestore update error: $e');
      return false;
    }
  }

  /// Delete a model document from Firestore
  Future<bool> deleteModel(String id) async {
    if (!isAvailable) return false;
    try {
      await _modelsRef!.doc(id).delete();
      debugPrint('Model deleted from Firestore: $id');
      return true;
    } catch (e) {
      debugPrint('Firestore delete error: $e');
      return false;
    }
  }

  /// Seeds default models into Firestore
  Future<void> seedDefaultModels() async {
    if (!isAvailable) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final model in defaultStarterModels) {
        final docRef = _modelsRef!.doc(model.id);
        final data = model.toJson();
        data['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data);
      }
      await batch.commit();
      debugPrint('Default models successfully seeded into Firestore.');
    } catch (e) {
      debugPrint('Error seeding default models into Firestore: $e');
    }
  }
}
