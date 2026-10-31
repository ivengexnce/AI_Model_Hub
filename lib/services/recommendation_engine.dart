import 'dart:math' as math;
import '../models/ml_model.dart';
import '../models/project_requirement.dart';

class ModelEvaluationResult {
  final MlModel model;
  final bool isEligible;
  final List<String> rejectionReasons, inclusionReasons, tradeoffs;
  final double score, performanceScore, hardwareScore, latencyScore, efficiencyScore;
  final int rank;
  final String evidenceConfidence;

  ModelEvaluationResult({
    required this.model,
    required this.isEligible,
    this.rejectionReasons = const [],
    this.inclusionReasons = const [],
    this.tradeoffs = const [],
    this.score = 0.0,
    this.rank = 0,
    this.performanceScore = 0.0,
    this.hardwareScore = 0.0,
    this.latencyScore = 0.0,
    this.efficiencyScore = 0.0,
    this.evidenceConfidence = 'High',
  });
}

class RecommendationEngine {
  static List<ModelEvaluationResult> evaluate({
    required List<MlModel> candidates,
    required ProjectRequirement requirement,
  }) {
    if (candidates.isEmpty) return [];

    final eligible = <MlModel>[];
    final ineligibles = <ModelEvaluationResult>[];

    // Phase 1: Hard Constraint Elimination (Blueprint 8.2)
    for (final m in candidates) {
      final reasons = <String>[];
      if (!_tasksMatch(m.task, requirement.task)) {
        reasons.add('Task mismatch: Model performs "${m.task}", but project requires "${requirement.task}".');
      }
      if (m.minRamBytes > requirement.availableRamBytes) {
        reasons.add('RAM budget exceeded: Model requires ${(m.minRamBytes / 1073741824).toStringAsFixed(1)} GB RAM, but environment only provides ${requirement.availableRamGb.toStringAsFixed(1)} GB.');
      }
      if (requirement.cpuOnly && m.minVramBytes > 0) {
        reasons.add('Requires dedicated GPU: Model requires ${(m.minVramBytes / 1073741824).toStringAsFixed(1)} GB VRAM, but CPU-only execution was requested.');
      }
      if (requirement.maxLatencyMs != null && m.latencyMs > requirement.maxLatencyMs!) {
        reasons.add('Latency ceiling exceeded: Measured ${m.latencyMs} ms exceeds target of ${requirement.maxLatencyMs} ms.');
      }
      if (requirement.allowedLicenses.isNotEmpty && !requirement.allowedLicenses.contains(m.license)) {
        reasons.add('License restricted: "${m.license}" is not in project allowlist (${requirement.allowedLicenses.join(', ')}).');
      }

      if (reasons.isEmpty) {
        eligible.add(m);
      } else {
        ineligibles.add(ModelEvaluationResult(model: m, isEligible: false, rejectionReasons: reasons));
      }
    }

    if (eligible.isEmpty) return ineligibles;

    // Phase 2: Feature Normalization & Weighted Ranking (Blueprint 8.3 & 8.4)
    final minAcc = eligible.map((e) => e.accuracy).reduce(math.min);
    final maxAcc = eligible.map((e) => e.accuracy).reduce(math.max);
    final minLat = eligible.map((e) => e.latencyMs).reduce(math.min);
    final maxLat = eligible.map((e) => e.latencyMs).reduce(math.max);
    final minRam = eligible.map((e) => e.minRamBytes).reduce(math.min);
    final maxRam = eligible.map((e) => e.minRamBytes).reduce(math.max);
    final minSize = eligible.map((e) => e.modelSizeBytes).reduce(math.min);
    final maxSize = eligible.map((e) => e.modelSizeBytes).reduce(math.max);

    double norm(num val, num min, num max, {bool invert = false}) {
      if (max == min) return 1.0;
      final raw = invert ? (max - val) / (max - min) : (val - min) / (max - min);
      return raw.clamp(0.0, 1.0).toDouble();
    }

    final scored = eligible.map((m) {
      final pScore = norm(m.accuracy, minAcc, maxAcc);
      final hScore = norm(m.minRamBytes, minRam, maxRam, invert: true);
      final lScore = norm(m.latencyMs, minLat, maxLat, invert: true);
      final eScore = norm(m.modelSizeBytes, minSize, maxSize, invert: true);

      final totalW = requirement.performanceWeight + requirement.hardwareWeight + requirement.latencyWeight + requirement.efficiencyWeight;
      final composite = totalW > 0
          ? ((requirement.performanceWeight * pScore +
                  requirement.hardwareWeight * hScore +
                  requirement.latencyWeight * lScore +
                  requirement.efficiencyWeight * eScore) /
              totalW)
          : 0.5;

      return ModelEvaluationResult(
        model: m,
        isEligible: true,
        score: double.parse((composite * 100).toStringAsFixed(1)),
        performanceScore: double.parse((pScore * 100).toStringAsFixed(1)),
        hardwareScore: double.parse((hScore * 100).toStringAsFixed(1)),
        latencyScore: double.parse((lScore * 100).toStringAsFixed(1)),
        efficiencyScore: double.parse((eScore * 100).toStringAsFixed(1)),
        inclusionReasons: [
          'Directly supports target task "${m.task}".',
          'Memory footprint (${m.formattedRamRequirement}) is comfortably within the ${requirement.availableRamGb.toStringAsFixed(1)} GB budget.',
          'Inference latency of ${m.latencyMs} ms on standard hardware.',
          'Verified benchmark: ${m.accuracy.toStringAsFixed(1)}% on ${m.benchmarkDataset}.',
        ],
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // Assign final ranks and trade-off summaries
    final ranked = <ModelEvaluationResult>[];
    for (int i = 0; i < scored.length; i++) {
      final item = scored[i];
      final rank = i + 1;
      final tradeoffs = <String>[];

      if (rank == 1 && scored.length > 1) {
        final r2 = scored[1];
        if (item.model.accuracy > r2.model.accuracy) {
          tradeoffs.add('Provides +${(item.model.accuracy - r2.model.accuracy).toStringAsFixed(1)}% higher benchmark score than runner-up (${r2.model.name}).');
        }
        if (item.model.latencyMs > r2.model.latencyMs) {
          tradeoffs.add('Trades ${item.model.latencyMs - r2.model.latencyMs} ms slower latency for superior architecture capacity.');
        }
      } else if (rank > 1) {
        final top = scored[0];
        if (item.model.latencyMs < top.model.latencyMs) {
          tradeoffs.add('Faster by ${top.model.latencyMs - item.model.latencyMs} ms compared to #1 recommendation, at the cost of lower benchmark accuracy.');
        }
        if (item.model.modelSizeBytes < top.model.modelSizeBytes) {
          tradeoffs.add('Significantly smaller storage footprint (${item.model.formattedModelSize} vs ${top.model.formattedModelSize}).');
        }
      }

      ranked.add(ModelEvaluationResult(
        model: item.model,
        isEligible: true,
        rank: rank,
        score: item.score,
        performanceScore: item.performanceScore,
        hardwareScore: item.hardwareScore,
        latencyScore: item.latencyScore,
        efficiencyScore: item.efficiencyScore,
        inclusionReasons: item.inclusionReasons,
        tradeoffs: tradeoffs,
      ));
    }

    return [...ranked, ...ineligibles];
  }

  static bool _tasksMatch(String mTask, String rTask) {
    if (mTask.toLowerCase() == rTask.toLowerCase()) return true;
    bool isNlpClass(String t) => t == 'Text Classification' || t == 'Sentiment Analysis';
    return isNlpClass(mTask) && isNlpClass(rTask);
  }
}
