import 'dart:math';
import 'package:flutter/material.dart';

class Flip3dCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const Flip3dCard({
    super.key,
    required this.front,
    required this.back,
  });

  @override
  State<Flip3dCard> createState() => _Flip3dCardState();
}

class _Flip3dCardState extends State<Flip3dCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isUnder = _animation.value > (pi / 2);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(_animation.value);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: widget.back,
                  )
                : widget.front,
          );
        },
      ),
    );
  }
}
