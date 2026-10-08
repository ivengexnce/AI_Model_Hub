import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/ml_model.dart';
import '../providers/model_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/model_image.dart';
import 'add_edit_model_screen.dart';

class ModelDetailScreen extends StatelessWidget {
  const ModelDetailScreen({super.key, required this.model});

  final MlModel model;

  @override
  Widget build(BuildContext context) {
    // Re-read from the provider so edits show up without reopening the screen.
    final m = context.select<ModelProvider, MlModel>(
      (p) => p.models.firstWhere((x) => x.id == model.id, orElse: () => model),
    );
    final busy = context.select<ModelProvider, bool>((p) => p.isLoading);

    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final gutter = pageGutter(context);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxxl),
        children: [
          Text(
            m.category.toUpperCase(),
            style: t.labelSmall?.copyWith(color: c.primary),
          ),
          const SizedBox(height: Space.sm),
          Text(m.name, style: t.headlineMedium),
          const SizedBox(height: Space.xl),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ModelImage(url: m.imageUrl, radius: Radii.md),
          ),
          const SizedBox(height: Space.xl),
          Container(
            padding: const EdgeInsets.symmetric(vertical: Space.lg),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: c.outlineVariant),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Accuracy',
                      value: m.accuracy.toStringAsFixed(1),
                      unit: '%',
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: Space.xl),
                      child: _Metric(
                        label: 'Latency',
                        value: '${m.latencyMs}',
                        unit: 'ms',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xxl),
          const SectionLabel('Specifications'),
          _SpecRow(label: 'Framework', value: m.framework),
          const Divider(),
          _SpecRow(label: 'Dataset', value: m.datasetName),
          const Divider(),
          _SpecRow(label: 'Version', value: m.version, mono: true),
          if (m.githubUrl.isNotEmpty) ...[
            const Divider(),
            _SpecRow(label: 'GitHub', value: m.githubUrl, mono: true),
          ],
          const SizedBox(height: Space.xxl),
          const SectionLabel('About'),
          Text(m.description, style: t.bodyLarge?.copyWith(height: 1.55)),
          if (m.githubUrl.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            OutlinedButton.icon(
              icon: const Icon(Icons.code_rounded),
              label: const Text('Copy GitHub Repository Link'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: m.githubUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: ${m.githubUrl}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: Space.xxl),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditModelScreen(modelToEdit: m),
                          ),
                        ),
                  child: const Text('Edit model'),
                ),
              ),
              const SizedBox(width: Space.md),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.error,
                  side: BorderSide(color: c.error.withValues(alpha: 0.5)),
                ),
                onPressed: busy ? null : () => _delete(context, m),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, MlModel m) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final provider = context.read<ModelProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete model?'),
        content: Text(
          '“${m.name}” will be removed from the registry. This can’t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await provider.deleteModel(m.id);
    if (ok) {
      nav.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Model deleted')));
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Couldn’t delete the model. Try again.')),
      );
    }
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit});

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
        ),
        const SizedBox(height: Space.sm),
        Text.rich(
          TextSpan(
            text: value,
            style: AppTheme.mono(size: 28, color: c.onSurface),
            children: [
              TextSpan(
                text: ' $unit',
                style: AppTheme.mono(size: 14, color: c.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? AppTheme.mono(size: 14, color: c.onSurface)
                  : t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
