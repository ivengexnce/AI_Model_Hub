import 'package:flutter/material.dart';

import '../models/ml_model.dart';
import '../theme/app_theme.dart';
import 'model_image.dart';

class ModelCard extends StatelessWidget {
  const ModelCard({super.key, required this.model, required this.onTap});

  final MlModel model;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final meta = AppTheme.mono(size: 12, color: c.onSurfaceVariant);

    return Material(
      color: c.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            model.category.toUpperCase(),
                            style: t.labelSmall?.copyWith(color: c.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _sourceBadge(model),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      model.name,
                      style: t.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      model.description,
                      style: t.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.md),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Color(model.laptopFeasibilityColorValue).withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            model.laptopFeasibilityBadge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(model.laptopFeasibilityColorValue),
                            ),
                          ),
                        ),
                        Text(
                          '${model.accuracy.toStringAsFixed(1)}%',
                          style: meta,
                        ),
                        Text('${model.latencyMs} ms', style: meta),
                        Text(model.formattedRamRequirement, style: meta),
                        Text(model.framework, style: meta),
                        Text(model.license, style: meta),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.lg),
              SizedBox(
                width: 72,
                height: 72,
                child: ModelImage(
                  url: model.imageUrl,
                  radius: Radii.sm,
                  memCacheWidth: 216,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _sourceBadge(MlModel m) {
  Widget badge(Color bg, Color bdr, Color fg, Widget icon, String text) => Padding(
    padding: const EdgeInsets.only(left: Space.sm),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4), border: Border.all(color: bdr)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [icon, const SizedBox(width: 3), Text(text, style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.w600, letterSpacing: 0.3))]),
    ),
  );
  if (m.isHuggingFace) return badge(const Color(0xFF2A1B0A), const Color(0xFF78350F), const Color(0xFFFBBF24), const Text('🤗', style: TextStyle(fontSize: 9.5)), 'Hugging Face');
  if (m.isGitHub) return badge(const Color(0xFF0F172A), const Color(0xFF334155), Colors.cyanAccent, const Icon(Icons.terminal_rounded, size: 10, color: Colors.cyanAccent), 'GitHub');
  if (m.isUserModel) return badge(const Color(0xFF064E3B).withAlpha(160), const Color(0xFF059669), const Color(0xFF34D399), const Icon(Icons.person_rounded, size: 10, color: Color(0xFF34D399)), m.creatorEmail.isNotEmpty ? 'User: ${m.creatorEmail.split('@')[0]}' : 'User Model');
  return const SizedBox.shrink();
}

