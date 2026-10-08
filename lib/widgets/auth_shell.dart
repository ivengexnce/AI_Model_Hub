import 'package:flutter/material.dart';

import 'common_widgets.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.backgroundDecoration,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget>? backgroundDecoration;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: Navigator.canPop(context) ? AppBar() : null,
      body: Stack(
        children: [
          ...?backgroundDecoration,
          SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.xl,
              vertical: Space.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(size: 32),
                  const SizedBox(height: Space.xxl),
                  Text(title, style: t.headlineMedium),
                  const SizedBox(height: Space.sm),
                  Text(
                    subtitle,
                    style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                  ),
                  const SizedBox(height: Space.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
}
