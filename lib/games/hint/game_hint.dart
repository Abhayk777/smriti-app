import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';

/// A gentle hint glow widget for dementia-friendly games.
///
/// Wraps interactive game items (cards, mats, options). If [isAnswer] is true,
/// after a 30-second inactivity delay, it subtly pulses a warm glowing border
/// and soft halo to assist the elder without penalizing or frustrating them.
class HintGlow extends StatefulWidget {
  const HintGlow({
    super.key,
    required this.child,
    this.isAnswer = false,
    this.radius = 16,
    this.delay = const Duration(seconds: 30),
  });

  final Widget child;
  final bool isAnswer;
  final double radius;
  final Duration delay;

  @override
  State<HintGlow> createState() => _HintGlowState();
}

class _HintGlowState extends State<HintGlow>
    with SingleTickerProviderStateMixin {
  Timer? _idleTimer;
  AnimationController? _animController;
  Animation<double>? _glowAnimation;
  bool _isGlowing = false;

  @override
  void initState() {
    super.initState();
    _startIdleTimer();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    if (!widget.isAnswer) return;

    _idleTimer = Timer(widget.delay, () {
      if (!mounted) return;
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);

      _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
        CurvedAnimation(parent: _animController!, curve: Curves.easeInOut),
      );

      setState(() {
        _isGlowing = true;
      });
    });
  }

  @override
  void didUpdateWidget(HintGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnswer != widget.isAnswer) {
      _cleanup();
      _startIdleTimer();
    }
  }

  void _cleanup() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _animController?.dispose();
    _animController = null;
    _isGlowing = false;
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGlowing || _animController == null || _glowAnimation == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation!,
      builder: (context, child) {
        final glow = _glowAnimation!.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: AppColors.marigold,
              width: 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.marigold.withValues(alpha: 0.7),
                blurRadius: glow,
                spreadRadius: glow * 0.25,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.45),
                blurRadius: glow * 0.5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
