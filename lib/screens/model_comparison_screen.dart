import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/decision_record.dart';
import '../models/project_requirement.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_theme.dart';

class ModelComparisonScreen extends StatelessWidget {
  final List<ModelEvaluationResult> candidates;
  final ProjectRequirement requirement;

  const ModelComparisonScreen({super.key, required this.candidates, required this.requirement});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final topThree = candidates.take(3).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Side-by-Side Comparison')),
      body: candidates.isEmpty
          ? const Center(child: Text('No models to compare.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Requirement Header
                  Container(
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: c.surfaceContainerHighest.withAlpha(60),
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: c.outlineVariant.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 24, color: Colors.cyanAccent),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Text(
                            'Task: ${requirement.task} • Budget: ${(requirement.availableRamBytes / 1073741824).toStringAsFixed(1)} GB RAM • ${requirement.cpuOnly ? "CPU-Only" : "GPU Enabled"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  Text('HEAD-TO-HEAD MATRIX', style: t.labelSmall?.copyWith(color: c.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: Space.sm),

                  // Candidate Cards Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: topThree.map((r) => Container(width: 290, margin: const EdgeInsets.only(right: Space.md), child: _buildCard(context, r, c))).toList(),
                    ),
                  ),
                  const SizedBox(height: Space.lg),

                  // Feature Matrix Table
                  Container(
                    decoration: BoxDecoration(
                      color: c.surfaceContainerHighest.withAlpha(40),
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: c.outlineVariant.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Rank & Score', topThree.map((e) => '#${e.rank} (${e.score.toStringAsFixed(0)} pts)').toList(), c),
                        _buildRow('Model', topThree.map((e) => e.model.name.split(' ').first).toList(), c),
                        _buildRow('Laptop Latency', topThree.map((e) => '${e.model.latencyMs} ms').toList(), c),
                        _buildRow('RAM Footprint', topThree.map((e) => e.model.formattedRamRequirement).toList(), c),
                        _buildRow('Size (Disk)', topThree.map((e) => e.model.formattedModelSize).toList(), c),
                        _buildRow('Parameters', topThree.map((e) => e.model.formattedParameters).toList(), c),
                        _buildRow('Accuracy', topThree.map((e) => '${e.model.accuracy.toStringAsFixed(1)}%').toList(), c),
                        _buildRow('License', topThree.map((e) => e.model.license).toList(), c),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(BuildContext context, ModelEvaluationResult r, ColorScheme c) {
    final isTop = r.rank == 1;
    final m = r.model;

    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: isTop ? const Color(0xFF064E3B).withAlpha(35) : c.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: isTop ? const Color(0xFF059669) : c.outlineVariant.withAlpha(80), width: isTop ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isTop ? '🏆 RANK #1' : 'RANK #${r.rank}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isTop ? const Color(0xFF34D399) : c.onSurface)),
              Text('${r.score.toStringAsFixed(0)} pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Space.xs),
          Text(m.laptopFeasibilityBadge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(m.laptopFeasibilityColorValue))),
          const Divider(height: Space.md),
          _stat('CPU Latency', '${m.latencyMs} ms', c),
          _stat('RAM', m.formattedRamRequirement, c),
          _stat('Accuracy', '${m.accuracy.toStringAsFixed(1)}%', c),
          _stat('License', m.license, c),
          const SizedBox(height: Space.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isTop ? const Color(0xFF059669) : c.primary, foregroundColor: Colors.white),
              onPressed: () => _saveAndPop(context, r),
              child: Text(isTop ? 'Select #1 Best' : 'Select #${r.rank}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String val, ColorScheme c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
            Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _buildRow(String label, List<String> values, ColorScheme c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.outlineVariant.withAlpha(40)))),
        child: Row(
          children: [
            SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant, fontWeight: FontWeight.w600))),
            ...values.map((v) => Expanded(child: Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))),
          ],
        ),
      );

  void _saveAndPop(BuildContext context, ModelEvaluationResult r) async {
    final auth = context.read<AuthProvider>();
    final modelProvider = context.read<ModelProvider>();

    await modelProvider.saveDecision(DecisionRecord(
      id: 'dec-${DateTime.now().millisecondsSinceEpoch}',
      userId: auth.currentUser?.uid ?? 'guest',
      requirement: requirement,
      selectedModelId: r.model.id,
      selectedModelName: r.model.name,
      selectedModelTask: r.model.task,
      framework: r.model.framework,
      license: r.model.license,
      score: r.score,
      rank: r.rank,
      decisionReason: r.inclusionReasons.isNotEmpty ? r.inclusionReasons.first : 'Selected via comparison matrix.',
      tradeoffs: r.tradeoffs,
      evidenceSource: r.model.evidenceSourceUrl.isNotEmpty ? r.model.evidenceSourceUrl : r.model.githubUrl,
      evidenceConfidence: r.evidenceConfidence,
      timestamp: DateTime.now(),
    ));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Selected ${r.model.name}!'), backgroundColor: const Color(0xFF059669)));
      Navigator.of(context).pop();
    }
  }
}
