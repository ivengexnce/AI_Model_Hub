import 'dart:math';
import 'package:flutter/material.dart';

class Floating3dBadge extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const Floating3dBadge({
    super.key,
    required this.icon,
    this.color = Colors.indigoAccent,
    this.size = 28,
  });

  @override
  State<Floating3dBadge> createState() => _Floating3dBadgeState();
}

class _Floating3dBadgeState extends State<Floating3dBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * 2 * pi;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(sin(angle) * 0.4)
            ..rotateX(cos(angle) * 0.2),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withAlpha(30),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(60),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
