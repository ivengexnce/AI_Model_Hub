import 'dart:math';
import 'package:flutter/material.dart';

class Animated3dCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double maxTiltAngle;

  const Animated3dCard({
    super.key,
    required this.child,
    this.onTap,
    this.maxTiltAngle = 0.15,
  });

  @override
  State<Animated3dCard> createState() => _Animated3dCardState();
}

class _Animated3dCardState extends State<Animated3dCard> with SingleTickerProviderStateMixin {
  double _rotateX = 0;
  double _rotateY = 0;
  bool _isHovered = false;

  void _onHover(PointerEvent event, Size size) {
    final x = event.localPosition.dx;
    final y = event.localPosition.dy;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    setState(() {
      _rotateY = ((x - centerX) / centerX) * widget.maxTiltAngle;
      _rotateX = -((y - centerY) / centerY) * widget.maxTiltAngle;
      _isHovered = true;
    });
  }

  void _resetTilt() {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (event) => _onHover(event, size),
          onExit: (_) => _resetTilt(),
          child: GestureDetector(
            onPanUpdate: (details) {
              final x = details.localPosition.dx;
              final y = details.localPosition.dy;
              setState(() {
                _rotateY = ((x - (size.width / 2)) / (size.width / 2)) * widget.maxTiltAngle;
                _rotateX = -((y - (size.height / 2)) / (size.height / 2)) * widget.maxTiltAngle;
              });
            },
            onPanEnd: (_) => _resetTilt(),
            onTap: widget.onTap,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _isHovered ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, hoverProgress, _) {
                final scaleVal = 1.0 + (hoverProgress * 0.03);
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateX(_rotateX)
                    ..rotateY(_rotateY)
                    ..scaleByDouble(scaleVal, scaleVal, 1.0, 1.0),
                  alignment: FractionalOffset.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withAlpha((40 + (hoverProgress * 60)).toInt()),
                          blurRadius: 12 + (hoverProgress * 12),
                          spreadRadius: hoverProgress * 2,
                          offset: Offset(
                            _rotateY * 20,
                            10 + (-_rotateX * 20),
                          ),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        widget.child,

                        // 3D Specular Highlight / Reflection Effect
                        if (_isHovered)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withAlpha(50),
                                      Colors.transparent,
                                      Colors.black.withAlpha(20),
                                    ],
                                    begin: Alignment(
                                      cos(_rotateY * 10),
                                      sin(_rotateX * 10),
                                    ),
                                    end: Alignment(
                                      -cos(_rotateY * 10),
                                      -sin(_rotateX * 10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
