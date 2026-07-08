import 'package:flutter/material.dart';
import 'dart:math';

class SmallWaveLoader extends StatefulWidget {
  final Color color;
  final double size;

  const SmallWaveLoader({
    Key? key,
    this.color = const Color(0xFF4A22A8),
    this.size = 12,
  }) : super(key: key);

  @override
  State<SmallWaveLoader> createState() => _SmallWaveLoaderState();
}

class _SmallWaveLoaderState extends State<SmallWaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
        final int barCount = widget.size < 16 ? 3 : 4;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(barCount, (index) {
            final delay = index * 0.15;
            final animValue = (_controller.value - delay) % 1.0;
            // Enhanced wave logic for smoother look
            final double heightScale = (sin(animValue * 2 * pi)).abs();
            final height =
                widget.size * 0.4 + (heightScale * widget.size * 1.5);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
              child: Container(
                width: widget.size * 0.25,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(widget.size * 0.15),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
