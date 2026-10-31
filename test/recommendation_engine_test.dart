import 'package:flutter_test/flutter_test.dart';
import 'package:ai_model_hub/models/project_requirement.dart';
import 'package:ai_model_hub/services/canonical_catalog_service.dart';
import 'package:ai_model_hub/services/recommendation_engine.dart';

void main() {
  group('RecommendationEngine Automated Verification (Blueprint Section 8)', () {
    final catalog = CanonicalCatalogService.getCanonicalModels();

    test('Hard Constraint 1: Rejects models with task mismatch', () {
      const requirement = ProjectRequirement(
        id: 'req-cv',
        task: 'Image Classification',
        availableRamBytes: 17179869184, // 16 GB (Plenty of RAM)
        cpuOnly: false,
      );

      final results = RecommendationEngine.evaluate(
        candidates: catalog,
        requirement: requirement,
      );

      final eligible = results.where((r) => r.isEligible).toList();
      final ineligible = results.where((r) => !r.isEligible).toList();

      expect(eligible.isNotEmpty, isTrue);
      // All eligible models MUST have task 'Image Classification'
      for (final r in eligible) {
        expect(r.model.task, 'Image Classification');
      }

      // Ineligible models must contain rejection reasons
      expect(ineligible.isNotEmpty, isTrue);
      expect(
        ineligible.any((r) => r.rejectionReasons.any((reason) => reason.contains('Task mismatch'))),
        isTrue,
      );
    });

    test('Hard Constraint 2: Rejects models that exceed RAM budget with exact explanation', () {
      // User only has 512 MB RAM (ultra-constrained IoT edge device)
      const requirement = ProjectRequirement(
        id: 'req-low-ram',
        task: 'Image Classification',
        availableRamBytes: 536870912, // 512 MB RAM
        cpuOnly: true,
      );

      final results = RecommendationEngine.evaluate(
        candidates: catalog,
        requirement: requirement,
      );

      final eligible = results.where((r) => r.isEligible).toList();
      final ineligible = results.where((r) => !r.isEligible && r.model.task == 'Image Classification').toList();

      // MobileNetV3-Small requires 512MB RAM, so it is ELIGIBLE!
      expect(eligible.any((r) => r.model.id == 'canon-mobilenet-v3-small'), isTrue);

      // ResNet-50 requires 2GB RAM, so it MUST be REJECTED!
      expect(ineligible.any((r) => r.model.id == 'canon-resnet-50'), isTrue);
      final resnetResult = ineligible.firstWhere((r) => r.model.id == 'canon-resnet-50');
      expect(
        resnetResult.rejectionReasons.any((msg) => msg.contains('RAM budget exceeded')),
        isTrue,
      );
    });

    test('Hard Constraint 3: Rejects models violating license allowlist', () {
      // User enterprise only permits Apache-2.0 or MIT
      const requirement = ProjectRequirement(
        id: 'req-license',
        task: 'Object Detection',
        availableRamBytes: 8589934592, // 8 GB RAM
        cpuOnly: true,
        allowedLicenses: ['Apache-2.0', 'MIT'],
      );

      final results = RecommendationEngine.evaluate(
        candidates: catalog,
        requirement: requirement,
      );

      final eligible = results.where((r) => r.isEligible).toList();
      final ineligible = results.where((r) => !r.isEligible && r.model.task == 'Object Detection').toList();

      // SSD-MobileNet is Apache-2.0, so it is eligible!
      expect(eligible.any((r) => r.model.id == 'canon-ssd-mobilenet-v2'), isTrue);

      // YOLOv8n is AGPL-3.0, so it MUST be rejected under license constraint!
      expect(ineligible.any((r) => r.model.id == 'canon-yolov8n'), isTrue);
      final yoloResult = ineligible.firstWhere((r) => r.model.id == 'canon-yolov8n');
      expect(
        yoloResult.rejectionReasons.any((msg) => msg.contains('License restricted')),
        isTrue,
      );
    });

    test('Weighted Ranking: Ranks eligible candidates deterministically with scores and trade-offs', () {
      const requirement = ProjectRequirement(
        id: 'req-nlp',
        task: 'Text Classification',
        availableRamBytes: 8589934592, // 8 GB RAM
        cpuOnly: true,
        performanceWeight: 0.40,
        hardwareWeight: 0.30,
        latencyWeight: 0.20,
        efficiencyWeight: 0.10,
      );

      final results = RecommendationEngine.evaluate(
        candidates: catalog,
        requirement: requirement,
      );

      final eligible = results.where((r) => r.isEligible).toList();
      expect(eligible.length, greaterThanOrEqualTo(2));

      // Rank 1 must have highest score
      expect(eligible.first.rank, 1);
      expect(eligible.first.score, greaterThan(0.0));
      expect(eligible.first.score, lessThanOrEqualTo(100.0));
      expect(eligible.first.inclusionReasons, isNotEmpty);

      // Verify descending scores
      for (int i = 0; i < eligible.length - 1; i++) {
        expect(eligible[i].score, greaterThanOrEqualTo(eligible[i + 1].score));
      }
    });

    test('Feature Normalization: Handles edge case with single candidate without dividing by zero', () {
      final singleCandidate = [catalog.firstWhere((m) => m.id == 'canon-mobilenet-v3-small')];
      const requirement = ProjectRequirement(
        id: 'req-single',
        task: 'Image Classification',
        availableRamBytes: 4294967296,
        cpuOnly: true,
      );

      final results = RecommendationEngine.evaluate(
        candidates: singleCandidate,
        requirement: requirement,
      );

      expect(results.length, 1);
      expect(results.first.isEligible, isTrue);
      expect(results.first.score, 100.0);
    });
  });
}
