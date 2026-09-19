import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_colors.dart';

/// A gentle hint glow widget for dementia-friendly games.
///
/// Wraps interactive game items (cards, mats, options). If [isAnswer] is true,
/// after a gentle inactivity delay (default 10 seconds), it subtly pulses a warm
/// glow to help the elder if they feel stuck, without penalizing or frustrating them.
class HintGlow extends StatefulWidget {
  const HintGlow({
    super.key,
    required this.child,
    this.isAnswer = false,
    this.radius = 16,
    this.delay = const Duration(seconds: 10),
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

      _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: AppColors.marigold.withValues(alpha: 0.65),
                blurRadius: _glowAnimation!.value,
                spreadRadius: _glowAnimation!.value / 3,
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
