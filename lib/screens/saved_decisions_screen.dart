import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/decision_record.dart';
import '../providers/model_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SavedDecisionsScreen extends StatelessWidget {
  final VoidCallback? onStartDecision;

  const SavedDecisionsScreen({super.key, this.onStartDecision});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final provider = context.watch<ModelProvider>();
    final decisions = provider.savedDecisions;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history_edu_rounded, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 8),
            Text('Saved Decision Reports'),
          ],
        ),
      ),
      body: decisions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Space.lg),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.cyanAccent),
                    ),
                    const SizedBox(height: Space.lg),
                    Text('No Decisions Saved Yet', style: t.titleMedium),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Run the Decision Engine with your project hardware requirements to generate and preserve reproducible selection reports.',
                      textAlign: TextAlign.center,
                      style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: Space.lg),
                    if (onStartDecision != null)
                      FilledButton.icon(
                        onPressed: onStartDecision,
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Start Model Selection'),
                      ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(Space.lg),
              itemCount: decisions.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.md),
              itemBuilder: (context, index) {
                final d = decisions[index];
                return _buildDecisionCard(context, d, c, t);
              },
            ),
    );
  }

  Widget _buildDecisionCard(BuildContext context, DecisionRecord d, ColorScheme c, TextTheme t) {
    final dateStr = '${d.timestamp.day}/${d.timestamp.month}/${d.timestamp.year}';

    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.cyan.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  d.selectedModelTask.toUpperCase(),
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  Text(dateStr, style: TextStyle(fontSize: 11, color: c.onSurfaceVariant)),
                  const SizedBox(width: Space.xs),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    tooltip: 'Delete Report',
                    onPressed: () {
                      context.read<ModelProvider>().deleteDecision(d.id);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(d.selectedModelName, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: Space.xs),
          Text(
            'Target: ${d.requirement.targetPlatform} • Budget: ${d.requirement.availableRamGb.toStringAsFixed(1)} GB RAM ${d.requirement.cpuOnly ? '(CPU-Only)' : '(GPU)'}',
            style: TextStyle(fontSize: 12, color: c.onSurfaceVariant),
          ),
          const SizedBox(height: Space.sm),
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓ ', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(d.decisionReason, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                ),
              ],
            ),
          ),
          if (d.tradeoffs.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            ...d.tradeoffs.map(
                  (tradeoff) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '⚖ $tradeoff',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

