import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/ml_model.dart';
import '../providers/auth_provider.dart';
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
    final isSaved = context.select<ModelProvider, bool>((p) => p.isModelSaved(m));

    final currentUser = context.select<AuthProvider, AuthUser?>((a) => a.currentUser);
    final isOwner = currentUser != null && (
      (m.creatorId.isNotEmpty && m.creatorId == currentUser.uid) ||
      (m.creatorEmail.isNotEmpty && m.creatorEmail.toLowerCase() == currentUser.email.toLowerCase())
    );

    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final gutter = pageGutter(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: isSaved ? 'Remove from Saved' : 'Save to Profile',
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
              color: isSaved ? Colors.cyanAccent : null,
            ),
            onPressed: () async {
              final added = await context.read<ModelProvider>().toggleSaveModel(m);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(added ? 'Saved "${m.name}" to your profile!' : 'Removed from saved models.'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, Space.sm, gutter, Space.xxxl),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.category.toUpperCase(),
                  style: t.labelSmall?.copyWith(color: c.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent.withAlpha(150)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Your Model (Owner)',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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
          if (m.creatorEmail.isNotEmpty) ...[
            const Divider(),
            _SpecRow(
              label: 'Author',
              value: isOwner ? 'You (${m.creatorEmail})' : m.creatorEmail,
            ),
          ],
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

          // Ownership actions: ONLY the owner can edit or delete!
          if (isOwner) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditModelScreen(modelToEdit: m),
                            ),
                          ),
                    label: const Text('Edit model'),
                  ),
                ),
                const SizedBox(width: Space.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.error,
                    side: BorderSide(color: c.error.withValues(alpha: 0.5)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: busy ? null : () => _delete(context, m),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ] else ...[
            // Non-owner view: Save to Profile / Local
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: isSaved ? Colors.indigo[700] : null,
                    ),
                    icon: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
                      size: 20,
                    ),
                    label: Text(
                      isSaved ? 'Saved in Your Profile' : 'Save to Profile / Local',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final added = await context.read<ModelProvider>().toggleSaveModel(m);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added ? 'Saved "${m.name}" to your profile!' : 'Removed from saved models.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Only the model author can edit or delete this model.',
                style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
              ),
            ),
          ],
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
