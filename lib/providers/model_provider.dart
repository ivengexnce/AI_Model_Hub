import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ml_model.dart';
import '../models/project_requirement.dart';
import '../models/decision_record.dart';
import '../services/api_service.dart';
import '../services/canonical_catalog_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../services/github_service.dart';
import '../services/recommendation_engine.dart';

class ModelProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirestoreService _firestoreService = FirestoreService();

  List<MlModel> _models = [];
  List<MlModel> _savedModels = [];
  List<DecisionRecord> _savedDecisions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSource = 'All';
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserEmail;

  List<MlModel> get models => _filteredModels();
  List<MlModel> get savedModels => _savedModels;
  List<DecisionRecord> get savedDecisions => _savedDecisions;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedSource => _selectedSource;
  String? get errorMessage => _errorMessage;

  int get totalModelsCount => _models.length;
  int get userModelsCount => _models.where((m) => m.isUserModel).length;
  int get githubModelsCount => _models.where((m) => m.isGitHub).length;
  int get huggingFaceModelsCount => _models.where((m) => m.isHuggingFace).length;
  int get savedModelsCount => _savedModels.length;

  int get myModelsCount {
    if ((_currentUserId == null || _currentUserId!.isEmpty) &&
        (_currentUserEmail == null || _currentUserEmail!.isEmpty)) {
      return 0;
    }
    return _models.where((m) => m.isCreatedBy(_currentUserId, _currentUserEmail)).length;
  }

  void updateCurrentUser({String? userId, String? userEmail}) {
    if (_currentUserId != userId || _currentUserEmail != userEmail) {
      _currentUserId = userId;
      _currentUserEmail = userEmail;
      notifyListeners();
    }
  }

  /// All supported sources for filtering and discovery
  List<String> get sources => [
    'All',
    'My Models',
    'User Models',
    'Hugging Face Hub',
    'GitHub Zoo',
    'Custom Models',
  ];

  /// Display sources for UI chips
  List<String> get displaySources => [
    'All',
    'My Models',
    'User Models',
    'Hugging Face Hub',
    'GitHub Zoo',
  ];

  /// Standard ML task domain categories
  List<String> get domainCategories => [
    'Computer Vision',
    'Natural Language Processing',
    'Audio & Speech',
    'Reinforcement Learning',
    'Tabular ML',
  ];

  /// Filter categories including collections and domains
  List<String> get categories => [
    'All',
    'My Models',
    'Saved',
    'Computer Vision',
    'Natural Language Processing',
    'Audio & Speech',
    'Reinforcement Learning',
    'Tabular ML',
  ];

  ModelProvider() {
    loadModels();
    _loadSavedModels();
    _loadSavedDecisions();
  }

  Future<void> _loadSavedDecisions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('broml_saved_decisions');
      if (raw != null) {
        _savedDecisions = raw.map((item) => DecisionRecord.fromJson(jsonDecode(item))).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved decisions: $e');
    }
  }

  Future<void> saveDecision(DecisionRecord record) async {
    _savedDecisions.removeWhere((d) => d.id == record.id);
    _savedDecisions.insert(0, record);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedDecisions.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList('broml_saved_decisions', list);
    } catch (e) {
      debugPrint('Error persisting decision: $e');
    }
  }

  Future<void> deleteDecision(String id) async {
    _savedDecisions.removeWhere((d) => d.id == id);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedDecisions.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList('broml_saved_decisions', list);
    } catch (e) {
      debugPrint('Error deleting decision: $e');
    }
  }

  /// Runs the Blueprint 1.0 Decision Engine strictly against verified canonical and user models
  List<ModelEvaluationResult> evaluateRequirements(ProjectRequirement req) {
    // Only evaluate canonical verified models and verified custom user models
    final canonicalList = CanonicalCatalogService.getCanonicalModels();
    final verifiedUserModels = _models.where((m) => m.isUserModel && m.verificationStatus == 'verified');

    final map = <String, MlModel>{};
    for (final m in canonicalList) {
      map[m.id] = m;
    }
    for (final m in verifiedUserModels) {
      map[m.id] = m;
    }

    return RecommendationEngine.evaluate(
      candidates: map.values.toList(),
      requirement: req,
    );
  }

  /// Authorization check: Determines if a user has permission to edit or delete a model (BOLA prevention)
  bool canUserModifyModel(
    MlModel model, {
    String? userId,
    String? userEmail,
    bool isAdmin = false,
  }) {
    if (isAdmin) return true;
    if (userId == null || userId.isEmpty) return false;

    // Direct owner check by uid
    if (model.creatorId.isNotEmpty && model.creatorId == userId) {
      return true;
    }

    // Owner check by verified email
    if (model.creatorEmail.isNotEmpty &&
        userEmail != null &&
        userEmail.isNotEmpty &&
        model.creatorEmail.toLowerCase() == userEmail.toLowerCase()) {
      return true;
    }

    // System/starter models without owner cannot be modified by standard users
    return false;
  }

  Future<void> _loadSavedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('saved_local_models');
      if (raw != null) {
        _savedModels = raw.map((item) => MlModel.fromJson(jsonDecode(item))).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved models: $e');
    }
  }

  Future<void> _persistSavedModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedModels.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList('saved_local_models', list);
    } catch (e) {
      debugPrint('Error persisting saved models: $e');
    }
  }

  bool isModelSaved(MlModel model) {
    return _savedModels.any((m) =>
      (m.id.isNotEmpty && m.id == model.id) ||
      (m.githubUrl.isNotEmpty && m.githubUrl == model.githubUrl) ||
      m.name == model.name
    );
  }

  Future<bool> toggleSaveModel(MlModel model) async {
    final index = _savedModels.indexWhere((m) =>
      (m.id.isNotEmpty && m.id == model.id) ||
      (m.githubUrl.isNotEmpty && m.githubUrl == model.githubUrl) ||
      m.name == model.name
    );

    final bool added;
    if (index >= 0) {
      _savedModels.removeAt(index);
      added = false;
    } else {
      _savedModels.insert(0, model);
      added = true;
    }
    await _persistSavedModels();
    notifyListeners();
    return added;
  }

  List<MlModel> _filteredModels() {
    List<MlModel> baseList;
    if (_selectedCategory == 'Saved') {
      baseList = _savedModels;
    } else if (_selectedCategory == 'My Models') {
      baseList = _models.where((m) => m.isCreatedBy(_currentUserId, _currentUserEmail)).toList();
    } else {
      baseList = _models;
    }

    return baseList.where((model) {
      final q = _searchQuery.toLowerCase().trim();
      final qNormalized = q.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '').replaceAll('/', '');
      final nameNormalized = model.name.toLowerCase().replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '').replaceAll('/', '');
      final descNormalized = model.description.toLowerCase();

      final matchesQuery = q.isEmpty ||
          model.name.toLowerCase().contains(q) ||
          nameNormalized.contains(qNormalized) ||
          descNormalized.contains(q) ||
          model.framework.toLowerCase().contains(q) ||
          model.datasetName.toLowerCase().contains(q) ||
          model.category.toLowerCase().contains(q) ||
          model.githubUrl.toLowerCase().contains(q);

      final matchesCategory = _selectedCategory == 'All' ||
          _selectedCategory == 'Saved' ||
          _selectedCategory == 'My Models' ||
          model.category == _selectedCategory;

      final matchesSource = _selectedSource == 'All' ||
          (_selectedSource == 'My Models' && model.isCreatedBy(_currentUserId, _currentUserEmail)) ||
          ((_selectedSource == 'User Models' || _selectedSource == 'Custom Models') && model.isUserModel) ||
          (_selectedSource == 'GitHub Zoo' && model.isGitHub) ||
          (_selectedSource == 'Hugging Face Hub' && model.isHuggingFace);

      return matchesQuery && matchesCategory && matchesSource;
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

  void setSelectedSource(String source) {
    _selectedSource = source;
    notifyListeners();
  }

  Future<void> loadModels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<MlModel> combined = [];

      // 1. Add canonical verified models from CanonicalCatalogService (Blueprint 1.0)
      final canonicalList = CanonicalCatalogService.getCanonicalModels();
      combined.addAll(canonicalList);

      // 2. Fetch user-created models from Cloud Firestore
      try {
        final firestoreModels = await _firestoreService.fetchModels();
        if (firestoreModels != null && firestoreModels.isNotEmpty) {
          for (final m in firestoreModels) {
            if (!combined.any((x) => x.id == m.id || x.name.toLowerCase() == m.name.toLowerCase())) {
              combined.add(m);
            }
          }
        }
      } catch (e) {
        debugPrint('Firestore fetch error: $e');
      }

      _models = combined;
    } catch (e) {
      _models = CanonicalCatalogService.getCanonicalModels();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Batch imports multiple GitHub repositories directly into the Hub
  Future<int> importGithubRepos(
    List<GithubRepo> repos, {
    String creatorId = '',
    String creatorEmail = '',
  }) async {
    int imported = 0;
    for (final repo in repos) {
      final model = repo.toMlModel();
      final alreadyExists = _models.any((m) =>
        (m.githubUrl.isNotEmpty && m.githubUrl.toLowerCase() == model.githubUrl.toLowerCase()) ||
        m.name.toLowerCase() == model.name.toLowerCase()
      );

      if (!alreadyExists) {
        final success = await createModel(
          name: model.name,
          category: model.category,
          framework: model.framework,
          accuracy: model.accuracy,
          latencyMs: model.latencyMs,
          version: model.version,
          description: model.description,
          datasetName: model.datasetName,
          githubUrl: model.githubUrl,
          creatorId: creatorId,
          creatorEmail: creatorEmail,
        );
        if (success) imported++;
      }
    }
    return imported;
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
    String githubUrl = '',
    String creatorId = '',
    String creatorEmail = '',
    XFile? imageFile,
  }) async {
    // Input sanitization and bounds check
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 100) {
      _errorMessage = 'Invalid model name (1-100 characters required).';
      notifyListeners();
      return false;
    }

    if (accuracy < 0.0 || accuracy > 100.0) {
      _errorMessage = 'Accuracy must be between 0% and 100%.';
      notifyListeners();
      return false;
    }

    if (latencyMs < 1 || latencyMs > 60000) {
      _errorMessage = 'Latency must be between 1ms and 60,000ms.';
      notifyListeners();
      return false;
    }

    final cleanUrl = githubUrl.trim();
    if (cleanUrl.isNotEmpty &&
        (!cleanUrl.startsWith('https://') || cleanUrl.contains('javascript:'))) {
      _errorMessage = 'GitHub link must be a valid secure URL starting with https://';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String imageUrl = 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/600/400';

      if (imageFile != null) {
        final uploadedUrl = await _storageService.uploadModelImage(imageFile, userId: creatorId);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final newModel = MlModel(
        id: '',
        name: cleanName,
        category: category,
        framework: framework,
        accuracy: accuracy,
        latencyMs: latencyMs,
        version: version.trim().isEmpty ? '1.0.0' : version.trim(),
        description: description.trim(),
        datasetName: datasetName.trim(),
        imageUrl: imageUrl,
        githubUrl: cleanUrl,
        creatorId: creatorId,
        creatorEmail: creatorEmail,
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
    String? githubUrl,
    XFile? newImageFile,
    String? currentUserId,
    String? currentUserEmail,
    bool isAdmin = false,
  }) async {
    // Authorization check (BOLA / IDOR defense)
    if (currentUserId != null &&
        !canUserModifyModel(
          existingModel,
          userId: currentUserId,
          userEmail: currentUserEmail,
          isAdmin: isAdmin,
        )) {
      _errorMessage = 'Access denied: You are not authorized to edit this model.';
      notifyListeners();
      return false;
    }

    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanName.length > 100) {
      _errorMessage = 'Invalid model name (1-100 characters required).';
      notifyListeners();
      return false;
    }

    if (accuracy < 0.0 || accuracy > 100.0) {
      _errorMessage = 'Accuracy must be between 0% and 100%.';
      notifyListeners();
      return false;
    }

    final cleanUrl = (githubUrl ?? existingModel.githubUrl).trim();
    if (cleanUrl.isNotEmpty &&
        (!cleanUrl.startsWith('https://') || cleanUrl.contains('javascript:'))) {
      _errorMessage = 'GitHub link must be a valid secure URL starting with https://';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String imageUrl = existingModel.imageUrl;

      if (newImageFile != null) {
        final uploadedUrl = await _storageService.uploadModelImage(newImageFile, userId: currentUserId);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final updatedModel = existingModel.copyWith(
        name: cleanName,
        category: category,
        framework: framework,
        accuracy: accuracy,
        latencyMs: latencyMs,
        version: version.trim(),
        description: description.trim(),
        datasetName: datasetName.trim(),
        imageUrl: imageUrl,
        githubUrl: cleanUrl,
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

  Future<bool> deleteModel(
    String id, {
    String? currentUserId,
    String? currentUserEmail,
    bool isAdmin = false,
  }) async {
    // Authorization check (BOLA / IDOR defense)
    final existingIndex = _models.indexWhere((m) => m.id == id);
    if (existingIndex != -1 && currentUserId != null) {
      final existingModel = _models[existingIndex];
      if (!canUserModifyModel(
        existingModel,
        userId: currentUserId,
        userEmail: currentUserEmail,
        isAdmin: isAdmin,
      )) {
        _errorMessage = 'Access denied: You are not authorized to delete this model.';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
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
