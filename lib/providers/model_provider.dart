import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ml_model.dart';
import '../services/api_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';

class ModelProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirestoreService _firestoreService = FirestoreService();

  List<MlModel> _models = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String? _errorMessage;

  List<MlModel> get models => _filteredModels();
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  List<String> get categories => [
    'All',
    'Computer Vision',
    'Natural Language Processing',
    'Audio & Speech',
    'Reinforcement Learning',
    'Tabular ML'
  ];

  ModelProvider() {
    loadModels();
  }

  List<MlModel> _filteredModels() {
    return _models.where((model) {
      final matchesQuery = model.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          model.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          model.framework.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' || model.category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadModels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Try fetching from Cloud Firestore
      final firestoreModels = await _firestoreService.fetchModels();
      if (firestoreModels != null && firestoreModels.isNotEmpty) {
        _models = firestoreModels;
      } else {
        // 2. Fallback to ApiService / local dataset
        _models = await _apiService.fetchModels();
      }
    } catch (e) {
      _models = await _apiService.fetchModels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createModel({
    required String name,
    required String category,
    required String framework,
    required double accuracy,
    required int latencyMs,
    required String version,
    required String description,
    required String datasetName,
    XFile? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String imageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400';

      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadModelImage(imageFile);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final newModel = MlModel(
        id: '',
        name: name,
        category: category,
        framework: framework,
        accuracy: accuracy,
        latencyMs: latencyMs,
        version: version,
        description: description,
        datasetName: datasetName,
        imageUrl: imageUrl,
      );

      // Save to Cloud Firestore if connected
      final firestoreCreated = await _firestoreService.createModel(newModel);
      if (firestoreCreated != null) {
        _models.insert(0, firestoreCreated);
      } else {
        // Fallback to local / REST service
        final result = await _apiService.createModel(newModel);
        _models.insert(0, result);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create model: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateModel(
    MlModel existingModel, {
    required String name,
    required String category,
    required String framework,
    required double accuracy,
    required int latencyMs,
    required String version,
    required String description,
    required String datasetName,
    XFile? newImageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String imageUrl = existingModel.imageUrl;

      if (newImageFile != null) {
        final uploadedUrl = await _storageService.uploadModelImage(newImageFile);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final updatedModel = existingModel.copyWith(
        name: name,
        category: category,
        framework: framework,
        accuracy: accuracy,
        latencyMs: latencyMs,
        version: version,
        description: description,
        datasetName: datasetName,
        imageUrl: imageUrl,
      );

      // Update in Cloud Firestore if connected
      final firestoreSuccess = await _firestoreService.updateModel(updatedModel);
      if (!firestoreSuccess) {
        await _apiService.updateModel(updatedModel);
      }

      final index = _models.indexWhere((m) => m.id == existingModel.id);
      if (index != -1) {
        _models[index] = updatedModel;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update model: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteModel(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.deleteModel(id);
      final success = await _apiService.deleteModel(id);
      _models.removeWhere((m) => m.id == id);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete model: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<XFile?> pickImage(ImageSource source) {
    return _storageService.pickImage(source: source);
  }
}
