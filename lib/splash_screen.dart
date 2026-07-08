import 'dart:async';
import 'package:flutter/material.dart';

const Color primaryPurple = Color(0xFF4A22A8);
const Color white = Colors.white;

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryPurple,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'N',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: white,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ICO MART',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                      color: white,
                          letterSpacing: 0.5,
                          fontSize: 32,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
