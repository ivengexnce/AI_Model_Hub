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
                    Text(
                      model.category.toUpperCase(),
                      style: t.labelSmall?.copyWith(color: c.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      model.name,
                      style: t.titleMedium,
                      maxLines: 1,
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
                      children: [
                        Text(
                          '${model.accuracy.toStringAsFixed(1)}%',
                          style: meta,
                        ),
                        Text('${model.latencyMs} ms', style: meta),
                        Text(model.framework, style: meta),
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
