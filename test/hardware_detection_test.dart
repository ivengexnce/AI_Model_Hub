import 'package:flutter_test/flutter_test.dart';
import 'package:ai_model_hub/services/hardware_detection_service.dart';
import 'package:ai_model_hub/services/canonical_catalog_service.dart';

void main() {
  group('HardwareDetectionService Automated Verification', () {
    test('Preset: Budget Laptop provides safe 2.0 GB ML limit for 4GB systems', () {
      final preset = HardwareDetectionService.budgetLaptopPreset;
      expect(preset.totalRamBytes, 4 * 1024 * 1024 * 1024);
      expect(preset.safeRamBudgetBytes, 2 * 1024 * 1024 * 1024);
      expect(preset.safeRamGb, 2.0);
      expect(preset.isAutoDetected, isFalse);
      expect(preset.presetName, 'Budget Laptop (4GB)');
    });

    test('Preset: Standard Laptop provides safe 4.5 GB ML limit for 8GB systems', () {
      final preset = HardwareDetectionService.standardLaptopPreset;
      expect(preset.totalRamBytes, 8 * 1024 * 1024 * 1024);
      expect(preset.safeRamBudgetBytes, 4831838208);
      expect(preset.safeRamGb, closeTo(4.5, 0.1));
      expect(preset.isAutoDetected, isFalse);
    });

    test('Preset: GPU Workstation provides 10.0 GB ML budget', () {
      final preset = HardwareDetectionService.workstationGpuPreset;
      expect(preset.totalRamBytes, 16 * 1024 * 1024 * 1024);
      expect(preset.safeRamBudgetBytes, 10737418240);
      expect(preset.safeRamGb, 10.0);
    });

    test('Auto-detection: Returns host hardware profile with safe buffer', () async {
      final profile = await HardwareDetectionService.autoDetect();
      expect(profile.cpuCores, greaterThanOrEqualTo(1));
      expect(profile.totalRamBytes, greaterThan(0));
      expect(profile.safeRamBudgetBytes, greaterThanOrEqualTo(536870912));
      expect(profile.safeRamGb, greaterThan(0.0));
      expect(profile.isAutoDetected, isTrue);
      expect(profile.summary, contains('Zero-Lag Guaranteed'));
    });

    test('Laptop Feasibility Badge: Correctly identifies zero-lag and heavy models', () {
      final models = CanonicalCatalogService.getCanonicalModels();

      final squeezenet = models.firstWhere((m) => m.id == 'canon-squeezenet');
      expect(squeezenet.laptopFeasibilityBadge, 'Laptop Ready (Zero Lag)');

      final mobilenet = models.firstWhere((m) => m.id == 'canon-mobilenet-v3-small');
      expect(mobilenet.laptopFeasibilityBadge, 'Laptop Ready (Zero Lag)');

      final minilm = models.firstWhere((m) => m.id == 'canon-all-minilm-l6');
      expect(minilm.laptopFeasibilityBadge, 'Laptop Ready (Zero Lag)');

      final yolov8s = models.firstWhere((m) => m.id == 'canon-yolov8s');
      expect(yolov8s.minVramBytes, greaterThan(0));
      expect(yolov8s.laptopFeasibilityBadge, 'Requires Dedicated GPU');
    });
  });
}

