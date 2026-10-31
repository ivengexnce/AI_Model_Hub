import 'package:flutter_test/flutter_test.dart';
import 'package:ai_model_hub/services/huggingface_service.dart';

void main() {
  group('HuggingFaceService & HfModel Automated Verification', () {
    final service = HuggingFaceService();

    test('Loads curated Hugging Face models across all 5 ML categories', () {
      final models = HuggingFaceService.getAllCuratedAsModels();
      expect(models.length, greaterThanOrEqualTo(10));

      // 1. Computer Vision
      expect(models.any((m) => m.category == 'Computer Vision' && m.name.contains('FLUX')), isTrue);
      // 2. Natural Language Processing
      expect(models.any((m) => m.category == 'Natural Language Processing' && m.name.contains('DeepSeek')), isTrue);
      // 3. Audio & Speech
      expect(models.any((m) => m.category == 'Audio & Speech' && m.name.contains('Whisper')), isTrue);
      // 4. Reinforcement Learning
      expect(models.any((m) => m.category == 'Reinforcement Learning' && m.name.contains('CleanRL')), isTrue);
      // 5. Tabular ML
      expect(models.any((m) => m.category == 'Tabular ML' && m.name.contains('Scikit')), isTrue);
    });

    test('Correctly maps framework formats (safetensors, onnx, gguf)', () {
      final models = HuggingFaceService.getAllCuratedAsModels();
      expect(models.any((m) => m.framework == 'SafeTensors'), isTrue);
      expect(models.any((m) => m.framework == 'ONNX'), isTrue);
    });

    test('Searches and filters curated models by query and category', () async {
      final cvResults = await service.searchModels(
        query: 'FLUX',
        categoryFilter: 'Computer Vision',
      );
      expect(cvResults.isNotEmpty, isTrue);
      expect(cvResults.first.id.toLowerCase(), contains('flux'));

      final nlpResults = await service.searchModels(
        query: 'DeepSeek',
        categoryFilter: 'Natural Language Processing',
      );
      expect(nlpResults.isNotEmpty, isTrue);
      expect(nlpResults.first.id.toLowerCase(), contains('deepseek'));
    });
  });
}
