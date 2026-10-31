import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_requirement.dart';
import '../models/decision_record.dart';
import '../providers/auth_provider.dart';
import '../providers/model_provider.dart';
import '../services/hardware_detection_service.dart';
import '../services/recommendation_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/account_menu.dart';
import 'model_detail_screen.dart';
import 'model_comparison_screen.dart';

class DecisionEngineScreen extends StatefulWidget {
  const DecisionEngineScreen({super.key});

  @override
  State<DecisionEngineScreen> createState() => _DecisionEngineScreenState();
}

class _DecisionEngineScreenState extends State<DecisionEngineScreen> {
  String _selectedTask = 'Image Classification';
  double _ramGb = 2.0;
  bool _cpuOnly = true;
  final double _maxLatencyMs = 50.0;
  final bool _enforceLatency = false;

  DetectedHardwareProfile? _detectedHardware;
  bool _isDetecting = false;
  List<ModelEvaluationResult>? _results;

  @override
  void initState() {
    super.initState();
    _autoDetect();
  }

  Future<void> _autoDetect() async {
    setState(() => _isDetecting = true);
    try {
      final p = await HardwareDetectionService.autoDetect();
      setState(() {
        _detectedHardware = p;
        _ramGb = p.safeRamGb;
        _cpuOnly = true;
        _isDetecting = false;
      });
      _evaluate();
    } catch (_) {
      setState(() => _isDetecting = false);
      _evaluate();
    }
  }

  void _applyPreset(DetectedHardwareProfile p) {
    setState(() {
      _detectedHardware = p;
      _ramGb = p.safeRamGb;
      _cpuOnly = p.presetName != 'GPU Workstation';
    });
    _evaluate();
  }

  ProjectRequirement _req() => ProjectRequirement(
        id: 'req-${DateTime.now().millisecondsSinceEpoch}',
        task: _selectedTask,
        targetPlatform: 'Edge / Laptop',
        availableRamBytes: (_ramGb * 1073741824).toInt(),
        availableVramBytes: _cpuOnly ? 0 : 4294967296,
        cpuOnly: _cpuOnly,
        maxLatencyMs: _enforceLatency ? _maxLatencyMs.toInt() : null,
      );

  void _evaluate() {
    final res = context.read<ModelProvider>().evaluateRequirements(_req());
    setState(() => _results = res);
  }

  void _compare(List<ModelEvaluationResult> eligible) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ModelComparisonScreen(candidates: eligible, requirement: _req())));
  }

  void _save(ModelEvaluationResult r) async {
    final auth = context.read<AuthProvider>();
    final mp = context.read<ModelProvider>();

    await mp.saveDecision(DecisionRecord(
      id: 'dec-${DateTime.now().millisecondsSinceEpoch}',
      userId: auth.currentUser?.uid ?? 'guest',
      requirement: _req(),
      selectedModelId: r.model.id,
      selectedModelName: r.model.name,
      selectedModelTask: r.model.task,
      framework: r.model.framework,
      license: r.model.license,
      score: r.score,
      rank: r.rank,
      decisionReason: r.inclusionReasons.isNotEmpty ? r.inclusionReasons.first : 'Optimal fit for requirements.',
      tradeoffs: r.tradeoffs,
      evidenceSource: r.model.evidenceSourceUrl.isNotEmpty ? r.model.evidenceSourceUrl : r.model.githubUrl,
      evidenceConfidence: r.evidenceConfidence,
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "${r.model.name}"!'), backgroundColor: const Color(0xFF065F46)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.psychology_rounded, color: Colors.cyanAccent, size: 22),
          SizedBox(width: 8),
          Text('Model Decision Engine'),
        ]),
        actions: const [AccountMenu()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBuilderCard(c, t),
            const SizedBox(height: Space.lg),
            if (_results != null) _buildResults(c, t),
          ],
        ),
      ),
    );
  }

  Widget _buildBuilderCard(ColorScheme c, TextTheme t) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: Space.sm),
            Text('Hardware Profiling & Constraints', style: t.titleMedium),
          ]),
          const SizedBox(height: Space.sm),

          // Preset Chips & Auto-Detect
          Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
            ActionChip(
              avatar: _isDetecting ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.bolt_rounded, size: 15, color: Colors.cyanAccent),
              label: const Text('Auto-Detect My Hardware'),
              backgroundColor: const Color(0xFF0F172A),
              side: BorderSide(color: _detectedHardware?.isAutoDetected == true ? Colors.cyanAccent : const Color(0xFF334155)),
              onPressed: _isDetecting ? null : _autoDetect,
            ),
            ChoiceChip(
              selected: _detectedHardware?.presetName == 'Budget Laptop (4GB)',
              label: const Text('Budget Laptop (4GB)'),
              onSelected: (_) => _applyPreset(HardwareDetectionService.budgetLaptopPreset),
            ),
            ChoiceChip(
              selected: _detectedHardware?.presetName == 'Standard Laptop (8GB)',
              label: const Text('Standard Laptop (8GB)'),
              onSelected: (_) => _applyPreset(HardwareDetectionService.standardLaptopPreset),
            ),
          ]),

          if (_detectedHardware != null) ...[
            const SizedBox(height: Space.xs),
            Text(_detectedHardware!.summary, style: const TextStyle(fontSize: 11, color: Color(0xFFA7F3D0), fontWeight: FontWeight.w500)),
          ],
          const Divider(height: Space.lg),

          // 1. Task Selector
          Text('1. TARGET ML TASK', style: t.labelSmall?.copyWith(color: c.primary)),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: ProjectRequirement.supportedTasks.map((task) {
              final sel = task == _selectedTask;
              return ChoiceChip(
                selected: sel,
                label: Text(task, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedTask = task);
                    _evaluate();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: Space.md),

          // 2. RAM Budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2. RAM BUDGET', style: t.labelSmall?.copyWith(color: c.primary)),
              Text('${_ramGb.toStringAsFixed(1)} GB RAM', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Slider(
            value: _ramGb,
            min: 0.5,
            max: 16.0,
            divisions: 31,
            label: '${_ramGb.toStringAsFixed(1)} GB',
            onChanged: (v) => setState(() => _ramGb = v),
            onChangeEnd: (_) => _evaluate(),
          ),

          // 3. CPU Mode
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('CPU-Only Execution (Zero-Lag Mode)', style: TextStyle(fontSize: 13)),
              value: _cpuOnly,
              onChanged: (v) {
                setState(() => _cpuOnly = v);
                _evaluate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ColorScheme c, TextTheme t) {
    final eligible = _results!.where((r) => r.isEligible).toList();
    final ineligibles = _results!.where((r) => !r.isEligible).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Decision Results', style: t.headlineSmall),
            Text('${eligible.length} Eligible • ${ineligibles.length} Ineligible', style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Space.sm),

        if (eligible.length >= 2) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(40)),
            onPressed: () => _compare(eligible),
            icon: const Icon(Icons.table_chart_outlined, size: 16),
            label: Text('Compare All ${eligible.length} Candidates Side-by-Side', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: Space.md),
        ],

        if (eligible.isEmpty)
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(Radii.sm)),
            child: const Text('No models satisfy constraints. Try increasing RAM or relaxing CPU constraints.', style: TextStyle(fontSize: 13)),
          )
        else ...[
          _buildTopCard(eligible.first, eligible, c, t),
          const SizedBox(height: Space.md),
          if (eligible.length > 1) ...[
            Text('SHORTLISTED RUNNER-UPS', style: t.labelSmall?.copyWith(color: c.primary)),
            const SizedBox(height: Space.xs),
            ...eligible.sublist(1).map((r) => _buildRunnerUp(r, eligible, c)),
          ],
        ],

        if (ineligibles.isNotEmpty) ...[
          const SizedBox(height: Space.md),
          Text('INELIGIBLE CANDIDATES (REASONS)', style: t.labelSmall?.copyWith(color: Colors.redAccent)),
          const SizedBox(height: Space.xs),
          ...ineligibles.take(5).map((r) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF1E1B1B), borderRadius: BorderRadius.circular(4)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ...r.rejectionReasons.map((x) => Text('✗ $x', style: const TextStyle(fontSize: 10, color: Color(0xFFF87171)))),
                ]),
              )),
        ],
      ],
    );
  }

  Widget _buildTopCard(ModelEvaluationResult r, List<ModelEvaluationResult> all, ColorScheme c, TextTheme t) {
    final m = r.model;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withAlpha(40),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: const Color(0xFF059669), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('🏆 RANK #1 RECOMMENDED', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 11)),
            Text('${r.score.toStringAsFixed(0)} / 100', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
          const SizedBox(height: Space.xs),
          Text(m.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(m.description, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Space.sm),

          Wrap(spacing: Space.sm, runSpacing: Space.xs, children: [
            _chip(m.laptopFeasibilityBadge, Color(m.laptopFeasibilityColorValue)),
            _chip(m.formattedRamRequirement, Colors.cyanAccent),
            _chip('${m.latencyMs} ms', Colors.white),
            _chip('${m.accuracy.toStringAsFixed(1)}%', Colors.white),
          ]),
          const SizedBox(height: Space.sm),

          ...r.inclusionReasons.take(2).map((x) => Text('✓ $x', style: const TextStyle(fontSize: 11, color: Color(0xFFF1F5F9)))),
          const SizedBox(height: Space.md),

          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _save(r), child: const Text('Save Decision'))),
            if (all.length >= 2) ...[
              const SizedBox(width: Space.xs),
              IconButton.filledTonal(onPressed: () => _compare(all), icon: const Icon(Icons.compare_arrows_rounded, size: 18)),
            ],
            const SizedBox(width: Space.xs),
            FilledButton.tonal(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModelDetailScreen(model: m))),
              child: const Text('Details'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildRunnerUp(ModelEvaluationResult r, List<ModelEvaluationResult> all, ColorScheme c) {
    return Container(
      margin: const EdgeInsets.only(bottom: Space.xs),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(color: c.surfaceContainerLow, borderRadius: BorderRadius.circular(Radii.sm), border: Border.all(color: c.outlineVariant)),
      child: Row(children: [
        Text('#${r.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.model.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('${r.model.formattedRamRequirement} • ${r.model.latencyMs} ms • ${r.model.laptopFeasibilityBadge}', style: TextStyle(fontSize: 10, color: c.onSurfaceVariant)),
          ]),
        ),
        TextButton(onPressed: () => _compare(all), child: const Text('Compare', style: TextStyle(fontSize: 11))),
      ]),
    );
  }

  Widget _chip(String label, Color col) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: col.withAlpha(25), borderRadius: BorderRadius.circular(4), border: Border.all(color: col.withAlpha(90))),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
      );
}
