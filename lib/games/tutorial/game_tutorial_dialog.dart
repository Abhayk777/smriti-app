import 'dart:async';
import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/locale_controller.dart';
import '../../ui/smriti_ui.dart';
import '../game_catalog.dart';
import '../ghost_hand.dart';

/// Interactive "How to Play" tutorial dialog.
///
/// Features a game-specific demonstration where a realistic animated 3D hand
/// actually plays the game gesture (dragging, sequential tapping, matching),
/// while the game elements dynamically respond to the hand's actions.
class GameTutorialDialog extends StatefulWidget {
  const GameTutorialDialog({
    super.key,
    required this.gameId,
    required this.onDismiss,
  });

  final String gameId;
  final VoidCallback onDismiss;

  static Future<void> show(BuildContext context, String gameId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GameTutorialDialog(
        gameId: gameId,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<GameTutorialDialog> createState() => _GameTutorialDialogState();
}

class _GameTutorialDialogState extends State<GameTutorialDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 10 seconds if elder just watches, avoiding cognitive lock
    _autoDismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.instance.currentLanguage;
    final info = gameCatalog.firstWhere(
      (g) => g.id == widget.gameId,
      orElse: () => gameCatalog.first,
    );
    final gameTitle = AppStrings.gameTitle(lang, widget.gameId);
    final instruction = _gameDescription(widget.gameId, lang, info.description);

    final isCompact = MediaQuery.of(context).size.height < 520;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 32,
        vertical: isCompact ? 12 : 24,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        decoration: BoxDecoration(
          color: AppColors.pageBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.terracotta, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Banner
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompact ? 10 : 14,
              ),
              decoration: BoxDecoration(
                color: info.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconMedallion(
                    icon: info.icon,
                    image: info.image,
                    color: info.color,
                    size: isCompact ? 38 : 46,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gameTitle,
                          style: TextStyle(
                            fontSize: isCompact ? 19 : 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _howToPlayLabel(lang),
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onColor, size: 28),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),

            // 2. Demonstration Stage with Custom Animated Game Play
            Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 18),
              child: Column(
                children: [
                  // Clear instruction
                  Text(
                    instruction,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: isCompact ? 10 : 14),

                  // Animated interactive stage that actually plays the game
                  Container(
                    height: isCompact ? 160 : 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveGameDemoStage(
                      gameId: widget.gameId,
                      isCompact: isCompact,
                      onTapAnywhere: widget.onDismiss,
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 18),

                  // Big "Let's Play" button
                  SizedBox(
                    width: double.infinity,
                    height: isCompact ? 48 : 56,
                    child: ElevatedButton.icon(
                      onPressed: widget.onDismiss,
                      icon: const Icon(Icons.play_arrow_rounded, size: 30),
                      label: Text(
                        _letsPlayLabel(lang),
                        style: TextStyle(
                          fontSize: isCompact ? 18 : 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.leafGreen,
                        foregroundColor: AppColors.onColor,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _howToPlayLabel(String code) {
    switch (code) {
      case 'as': return 'কেনে খেলিব শিকক';
      case 'bn': return 'কিভাবে খেলবেন দেখুন';
      case 'hi': return 'खेलने का तरीका देखें';
      case 'ne': return 'कसरी खेल्ने हेर्नुहोस्';
      case 'mni': return 'কেনে শানবগে য়েংবিউ';
      case 'kha': return 'Kumno ban ialehkai';
      case 'lus': return 'Khelh dan zir rawh';
      case 'grt': return 'Kalaniko mesokbo';
      case 'brx': return 'माबोरै गेलेनो नाय';
      case 'trp': return 'Bwkhwkhe kwlano nidi';
      case 'nag': return 'Kineke khelibo sabo';
      case 'en':
      default: return 'How to Play';
    }
  }

  String _letsPlayLabel(String code) {
    switch (code) {
      case 'as': return 'খেলা আৰম্ভ কৰক';
      case 'bn': return 'খেলা শুরু করুন';
      case 'hi': return 'खेल शुरू करें';
      case 'ne': return 'खेल सुरु गर्नुहोस्';
      case 'mni': return 'শানবা হৌসি';
      case 'kha': return 'Ialehkai noh';
      case 'lus': return 'Khel ṭan rawh';
      case 'grt': return 'Kalna a·bachengbo';
      case 'brx': return 'गेलेनो जागाय';
      case 'trp': return 'Kwlano cheng di';
      case 'nag': return 'Khel suru koribo';
      case 'en':
      default: return 'Let\'s Play!';
    }
  }

  String _gameDescription(String id, String code, String fallback) {
    switch (id) {
      case 'faces_of_family':
        switch (code) {
          case 'as': return 'পৰিয়ালৰ সদস্যৰ লগত মিলা ফটোখনত টিপক';
          case 'bn': return 'পরিবারের সদস্যের সাথে মেলা ছবিতে স্পর্শ করুন';
          case 'hi': return 'परिवार के सदस्य से मेल खाती तस्वीर पर टैप करें';
          default: return 'Tap the photo that matches the family member';
        }
      case 'market_basket':
        switch (code) {
          case 'as': return 'বস্তুবোৰ মনত ৰাখক আৰু সঠিক বস্তু বাছি লওক';
          case 'bn': return 'জিনিসগুলো মনে রাখুন এবং সঠিক জিনিস বেছে নিন';
          case 'hi': return 'सामान याद रखें और दुकान से वही चुनें';
          default: return 'Remember the items and pick them from the shelf';
        }
      case 'sort_harvest':
        switch (code) {
          case 'as': return 'প্ৰতিটো বস্তু তাৰ সঠিক ডলাত থওক';
          case 'bn': return 'প্রতিটি জিনিস তার সঠিক ঝুড়িতে রাখুন';
          case 'hi': return 'हर चीज़ को उसकी सही टोकरी में रखें';
          default: return 'Drag each item to its matching basket';
        }
      case 'trace_path':
        switch (code) {
          case 'as': return 'ক্ৰম অনুসৰি শিলবোৰত এটাকৈ টিপক';
          case 'bn': return 'ক্রম অনুযায়ী পাথরগুলোতে একটি করে স্পর্শ করুন';
          case 'hi': return 'संख्या के क्रम में एक-एक पत्थर पर टैप करें';
          default: return 'Tap the stones in order of their numbers';
        }
      case 'my_day':
        switch (code) {
          case 'as': return 'দিনটোৰ কামবোৰ সময় অনুসৰি সজাওক';
          case 'bn': return 'দিনের কাজগুলো সময় অনুসারে সাজান';
          case 'hi': return 'दिन के कामों को सही क्रम में लगाएँ';
          default: return 'Arrange your daily routine in order of time';
        }
      case 'lamps_festival':
        switch (code) {
          case 'as': return 'চাকি জ্বলা মন কৰক আৰু সেই ক্ৰমতে টিপক';
          case 'bn': return 'প্রদীপ জ্বলা লক্ষ্য করুন এবং সেই ক্রমে স্পর্শ করুন';
          case 'hi': return 'दीये जलते देखें और उसी क्रम में टैप करें';
          default: return 'Watch the lamps light up, then tap them in order';
        }
      case 'name_harvest':
        switch (code) {
          case 'as': return 'এই ভাগৰ যিমান পাৰে সিমান শব্দ লিখক';
          case 'bn': return 'এই বিভাগের যতগুলো পারেন শব্দ লিখুন';
          case 'hi': return 'इस श्रेणी के जितने शब्द याद आएँ लिखें';
          default: return 'Name as many items as you can in this category';
        }
      case 'weaving_patterns':
        switch (code) {
          case 'as': return 'ওপৰৰ আৰ্হি চাই তলৰ মিলাটো বাছক';
          case 'bn': return 'উপরের নকশা দেখে নিচের মেলাটি বেছে নিন';
          case 'hi': return 'ऊपर का डिज़ाइन देखकर नीचे सही डिज़ाइन चुनें';
          default: return 'Find the pattern that matches the one above';
        }
      case 'sounds_home':
        switch (code) {
          case 'as': return 'চৰাইৰ মাত শুনিলে ঢোলত চাপৰ দিয়ক';
          case 'bn': return 'পাখির ডাক শুনলে ঢোলে টোকা দিন';
          case 'hi': return 'चिड़िया की आवाज़ सुनते ही ढोल पर टैप करें';
          default: return 'Tap the drum whenever you hear the bird';
        }
      default:
        return fallback;
    }
  }
}

/// Stage that plays an interactive demonstration tailored to each specific game.
class InteractiveGameDemoStage extends StatefulWidget {
  const InteractiveGameDemoStage({
    super.key,
    required this.gameId,
    required this.isCompact,
    this.onTapAnywhere,
  });

  final String gameId;
  final bool isCompact;
  final VoidCallback? onTapAnywhere;

  @override
  State<InteractiveGameDemoStage> createState() => _InteractiveGameDemoStageState();
}

class _InteractiveGameDemoStageState extends State<InteractiveGameDemoStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTapAnywhere,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final t = _animController.value;
          final handData = _getHandData(widget.gameId, t);

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Game-specific interactive canvas
                  _buildGamePlay(widget.gameId, t, constraints),

                  // Realistic ghost hand on top
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: RealisticHandPainter(
                      position: handData.position,
                      isPressing: handData.isPressing,
                      rippleProgress: handData.rippleProgress,
                      pathPoints: const [],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  _HandData _getHandData(String gameId, double t) {
    switch (gameId) {
      case 'sort_harvest':
        // Move to tomato (0.50, 0.22), press, drag down to (0.28, 0.65), release
        if (t < 0.22) {
          final p = Curves.easeOutCubic.transform(t / 0.22);
          return _HandData(Offset.lerp(const Offset(0.70, 0.55), const Offset(0.50, 0.22), p)!);
        } else if (t < 0.32) {
          final rip = (t - 0.22) / 0.10;
          return _HandData(const Offset(0.50, 0.22), isPressing: true, rippleProgress: rip);
        } else if (t < 0.70) {
          final p = Curves.easeInOutCubic.transform((t - 0.32) / 0.38);
          return _HandData(Offset.lerp(const Offset(0.50, 0.22), const Offset(0.28, 0.65), p)!, isPressing: true);
        } else if (t < 0.92) {
          final p = Curves.easeOut.transform((t - 0.70) / 0.22);
          return _HandData(Offset.lerp(const Offset(0.28, 0.65), const Offset(0.38, 0.75), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.55));
        }

      case 'market_basket':
        // Tap Apple (0.30, 0.38), then tap Milk (0.70, 0.38)
        if (t < 0.25) {
          final p = Curves.easeInOut.transform(t / 0.25);
          return _HandData(Offset.lerp(const Offset(0.50, 0.75), const Offset(0.30, 0.38), p)!);
        } else if (t < 0.35) {
          final rip = (t - 0.25) / 0.10;
          return _HandData(const Offset(0.30, 0.38), isPressing: true, rippleProgress: rip);
        } else if (t < 0.60) {
          final p = Curves.easeInOut.transform((t - 0.35) / 0.25);
          return _HandData(Offset.lerp(const Offset(0.30, 0.38), const Offset(0.70, 0.38), p)!);
        } else if (t < 0.70) {
          final rip = (t - 0.60) / 0.10;
          return _HandData(const Offset(0.70, 0.38), isPressing: true, rippleProgress: rip);
        } else {
          final p = Curves.easeOut.transform((t - 0.70) / 0.30);
          return _HandData(Offset.lerp(const Offset(0.70, 0.38), const Offset(0.50, 0.75), p)!);
        }

      case 'trace_path':
        // Tap 1 (0.22, 0.50) -> tap 2 (0.50, 0.40) -> tap 3 (0.78, 0.55)
        if (t < 0.24) {
          final p = Curves.easeOut.transform(t / 0.24);
          return _HandData(Offset.lerp(const Offset(0.10, 0.70), const Offset(0.22, 0.50), p)!);
        } else if (t < 0.32) {
          final rip = (t - 0.24) / 0.08;
          return _HandData(const Offset(0.22, 0.50), isPressing: true, rippleProgress: rip);
        } else if (t < 0.54) {
          final p = Curves.easeInOut.transform((t - 0.32) / 0.22);
          return _HandData(Offset.lerp(const Offset(0.22, 0.50), const Offset(0.50, 0.40), p)!);
        } else if (t < 0.62) {
          final rip = (t - 0.54) / 0.08;
          return _HandData(const Offset(0.50, 0.40), isPressing: true, rippleProgress: rip);
        } else if (t < 0.82) {
          final p = Curves.easeInOut.transform((t - 0.62) / 0.20);
          return _HandData(Offset.lerp(const Offset(0.50, 0.40), const Offset(0.78, 0.55), p)!);
        } else if (t < 0.90) {
          final rip = (t - 0.82) / 0.08;
          return _HandData(const Offset(0.78, 0.55), isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(Offset(0.78, 0.55));
        }

      case 'faces_of_family':
        // Point from prompt down to Daughter (0.70, 0.65) and tap
        if (t < 0.42) {
          final p = Curves.easeInOut.transform(t / 0.42);
          return _HandData(Offset.lerp(const Offset(0.40, 0.20), const Offset(0.70, 0.65), p)!);
        } else if (t < 0.56) {
          final rip = (t - 0.42) / 0.14;
          return _HandData(const Offset(0.70, 0.65), isPressing: true, rippleProgress: rip);
        } else {
          final p = Curves.easeOut.transform((t - 0.56) / 0.44);
          return _HandData(Offset.lerp(const Offset(0.70, 0.65), const Offset(0.75, 0.75), p)!);
        }

      case 'lamps_festival':
        // Watch phase 0..0.45 (hand waiting off-screen), then tap lamp 1 (0.24, 0.62) and lamp 2 (0.76, 0.62)
        if (t < 0.45) {
          return const _HandData(Offset(0.12, 0.88));
        } else if (t < 0.60) {
          final p = Curves.easeInOut.transform((t - 0.45) / 0.15);
          return _HandData(Offset.lerp(const Offset(0.12, 0.88), const Offset(0.24, 0.62), p)!);
        } else if (t < 0.68) {
          final rip = (t - 0.60) / 0.08;
          return _HandData(const Offset(0.24, 0.62), isPressing: true, rippleProgress: rip);
        } else if (t < 0.82) {
          final p = Curves.easeInOut.transform((t - 0.68) / 0.14);
          return _HandData(Offset.lerp(const Offset(0.24, 0.62), const Offset(0.76, 0.62), p)!);
        } else if (t < 0.90) {
          final rip = (t - 0.82) / 0.08;
          return _HandData(const Offset(0.76, 0.62), isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(Offset(0.76, 0.62));
        }

      case 'my_day':
        // Grab Walk card at bottom (0.50, 0.76) and drag up to slot 2 (0.50, 0.48)
        if (t < 0.28) {
          final p = Curves.easeOut.transform(t / 0.28);
          return _HandData(Offset.lerp(const Offset(0.70, 0.85), const Offset(0.50, 0.76), p)!);
        } else if (t < 0.36) {
          final rip = (t - 0.28) / 0.08;
          return _HandData(const Offset(0.50, 0.76), isPressing: true, rippleProgress: rip);
        } else if (t < 0.72) {
          final p = Curves.easeInOut.transform((t - 0.36) / 0.36);
          return _HandData(Offset.lerp(const Offset(0.50, 0.76), const Offset(0.50, 0.48), p)!, isPressing: true);
        } else {
          final p = Curves.easeOut.transform((t - 0.72) / 0.28);
          return _HandData(Offset.lerp(const Offset(0.50, 0.48), const Offset(0.65, 0.58), p)!);
        }

      case 'weaving_patterns':
        // Inspect top pattern (0.50, 0.28), move down and tap matching option A (0.30, 0.68)
        if (t < 0.35) {
          final p = Curves.easeInOut.transform(t / 0.35);
          return _HandData(Offset.lerp(const Offset(0.35, 0.35), const Offset(0.50, 0.28), p)!);
        } else if (t < 0.62) {
          final p = Curves.easeInOut.transform((t - 0.35) / 0.27);
          return _HandData(Offset.lerp(const Offset(0.50, 0.28), const Offset(0.30, 0.68), p)!);
        } else if (t < 0.72) {
          final rip = (t - 0.62) / 0.10;
          return _HandData(const Offset(0.30, 0.68), isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(Offset(0.30, 0.68));
        }

      case 'sounds_home':
        // Bird sings, hand moves down to drum (0.50, 0.72) and taps on the sound!
        if (t < 0.38) {
          return const _HandData(Offset(0.50, 0.42));
        } else if (t < 0.56) {
          final p = Curves.easeInOut.transform((t - 0.38) / 0.18);
          return _HandData(Offset.lerp(const Offset(0.50, 0.42), const Offset(0.50, 0.72), p)!);
        } else if (t < 0.68) {
          final rip = (t - 0.56) / 0.12;
          return _HandData(const Offset(0.50, 0.72), isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(Offset(0.50, 0.72));
        }

      case 'name_harvest':
      default:
        // Tap input field (0.40, 0.42) -> move to + button (0.78, 0.42) and tap
        if (t < 0.28) {
          final p = Curves.easeInOut.transform(t / 0.28);
          return _HandData(Offset.lerp(const Offset(0.50, 0.75), const Offset(0.40, 0.42), p)!);
        } else if (t < 0.38) {
          final rip = (t - 0.28) / 0.10;
          return _HandData(const Offset(0.40, 0.42), isPressing: true, rippleProgress: rip);
        } else if (t < 0.62) {
          final p = Curves.easeInOut.transform((t - 0.38) / 0.24);
          return _HandData(Offset.lerp(const Offset(0.40, 0.42), const Offset(0.78, 0.42), p)!);
        } else if (t < 0.72) {
          final rip = (t - 0.62) / 0.10;
          return _HandData(const Offset(0.78, 0.42), isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(Offset(0.78, 0.42));
        }
    }
  }

  Widget _buildGamePlay(String gameId, double t, BoxConstraints constraints) {
    switch (gameId) {
      case 'sort_harvest':
        return _buildSortHarvestPlay(t, constraints);
      case 'market_basket':
        return _buildMarketBasketPlay(t, constraints);
      case 'trace_path':
        return _buildTracePathPlay(t, constraints);
      case 'faces_of_family':
        return _buildFacesPlay(t, constraints);
      case 'lamps_festival':
        return _buildLampsPlay(t, constraints);
      case 'my_day':
        return _buildMyDayPlay(t, constraints);
      case 'weaving_patterns':
        return _buildWeavingPlay(t, constraints);
      case 'sounds_home':
        return _buildSoundsHomePlay(t, constraints);
      case 'name_harvest':
      default:
        return _buildNameHarvestPlay(t, constraints);
    }
  }

  // 1. Sort the Harvest: Actual item drag & drop into matching basket
  Widget _buildSortHarvestPlay(double t, BoxConstraints constraints) {
    Offset itemPos = const Offset(0.50, 0.22);
    bool inBasket = false;
    if (t >= 0.32 && t < 0.70) {
      final p = Curves.easeInOutCubic.transform((t - 0.32) / 0.38);
      itemPos = Offset.lerp(const Offset(0.50, 0.22), const Offset(0.28, 0.65), p)!;
    } else if (t >= 0.70) {
      itemPos = const Offset(0.28, 0.65);
      inBasket = true;
    }

    final itemPxX = itemPos.dx * constraints.maxWidth - 44;
    final itemPxY = itemPos.dy * constraints.maxHeight - 22;

    return Stack(
      children: [
        // Baskets at bottom
        Positioned(
          left: constraints.maxWidth * 0.08,
          bottom: 12,
          child: Container(
            width: constraints.maxWidth * 0.38,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: inBasket ? AppColors.leafGreen.withValues(alpha: 0.25) : AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: inBasket ? AppColors.leafGreen : AppColors.bamboo,
                width: inBasket ? 3 : 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(inBasket ? '🥬 Vegetables ✓' : '🥬 Vegetables',
                    style: TextStyle(
                      color: inBasket ? AppColors.leafGreen : AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
                const SizedBox(height: 2),
                Text(inBasket ? '+1 Sorted!' : 'Drag here',
                    style: TextStyle(
                      color: inBasket ? AppColors.leafGreen : AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ),
        Positioned(
          right: constraints.maxWidth * 0.08,
          bottom: 12,
          child: Container(
            width: constraints.maxWidth * 0.38,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🍎 Fruits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(height: 2),
                Text('Other basket', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),
        ),

        // Dragging Tomato card
        Positioned(
          left: itemPxX,
          top: itemPxY,
          child: Transform.scale(
            scale: (t >= 0.25 && t < 0.70) ? 1.12 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.marigold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🍅', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text('Tomato', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Market Basket: Shelf tapping & basket collecting
  Widget _buildMarketBasketPlay(double t, BoxConstraints constraints) {
    final applePicked = t >= 0.28;
    final milkPicked = t >= 0.62;

    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('Shopping List: 🍎 Apple, 🥛 Milk',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryText)),
            ),
          ),
        ),
        Positioned(
          left: constraints.maxWidth * 0.22 - 32,
          top: constraints.maxHeight * 0.38 - 28,
          child: _buildShelfItemMock('🍎 Apple', applePicked),
        ),
        Positioned(
          left: constraints.maxWidth * 0.72 - 32,
          top: constraints.maxHeight * 0.38 - 28,
          child: _buildShelfItemMock('🥛 Milk', milkPicked),
        ),
        Positioned(
          left: constraints.maxWidth * 0.25,
          right: constraints.maxWidth * 0.25,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: (applePicked && milkPicked)
                  ? AppColors.leafGreen.withValues(alpha: 0.25)
                  : AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (applePicked && milkPicked) ? AppColors.leafGreen : AppColors.marigoldDark,
                width: 2.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_rounded, color: AppColors.marigoldDark, size: 22),
                const SizedBox(width: 8),
                Text(
                  (applePicked && milkPicked) ? '🧺 All 2 Picked! ✓' : (applePicked ? '🧺 1/2 Picked' : '🧺 Basket'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: (applePicked && milkPicked) ? AppColors.leafGreen : AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShelfItemMock(String label, bool picked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: picked ? AppColors.leafGreen.withValues(alpha: 0.2) : AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: picked ? AppColors.leafGreen : AppColors.border,
          width: picked ? 3 : 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (picked) ...const [
            SizedBox(width: 4),
            Icon(Icons.check_circle_rounded, color: AppColors.leafGreen, size: 16),
          ],
        ],
      ),
    );
  }

  // 3. Trace the Path: Stepping stones in sequential order 1 -> 2 -> 3
  Widget _buildTracePathPlay(double t, BoxConstraints constraints) {
    final s1 = t >= 0.24;
    final s2 = t >= 0.54;
    final s3 = t >= 0.82;

    return Stack(
      children: [
        CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _PathLinePainter(
            p1: Offset(constraints.maxWidth * 0.22, constraints.maxHeight * 0.50),
            p2: Offset(constraints.maxWidth * 0.50, constraints.maxHeight * 0.40),
            p3: Offset(constraints.maxWidth * 0.78, constraints.maxHeight * 0.55),
          ),
        ),
        Positioned(
          left: constraints.maxWidth * 0.22 - 26,
          top: constraints.maxHeight * 0.50 - 26,
          child: _buildStoneNodeMock('1', s1),
        ),
        Positioned(
          left: constraints.maxWidth * 0.50 - 26,
          top: constraints.maxHeight * 0.40 - 26,
          child: _buildStoneNodeMock('2', s2),
        ),
        Positioned(
          left: constraints.maxWidth * 0.78 - 26,
          top: constraints.maxHeight * 0.55 - 26,
          child: _buildStoneNodeMock('3', s3),
        ),
        if (s3)
          Positioned(
            bottom: 8,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('⭐ Path Complete! ✓',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStoneNodeMock(String label, bool active) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: active ? AppColors.leafGreen : AppColors.indigo,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.leafGreen : AppColors.indigo).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          active ? '$label ✓' : label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // 4. Faces of My Family: Match family member
  Widget _buildFacesPlay(double t, BoxConstraints constraints) {
    final matched = t >= 0.42;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.raisedSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text('Who is your Daughter? 👧',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryText)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPortraitCardMock('Grandson', Icons.face_rounded, false),
            _buildPortraitCardMock('Daughter', Icons.face_3_rounded, matched),
          ],
        ),
      ],
    );
  }

  Widget _buildPortraitCardMock(String name, IconData icon, bool matched) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: matched ? AppColors.leafGreen.withValues(alpha: 0.18) : AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: matched ? AppColors.leafGreen : AppColors.border,
          width: matched ? 3.5 : 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: matched ? AppColors.leafGreen : AppColors.terracotta),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          if (matched) ...const [
            SizedBox(height: 2),
            Text('❤️ Match! ✓',
                style: TextStyle(color: AppColors.leafGreen, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  // 5. Lamps of the Festival: Watch sequence then tap in order
  Widget _buildLampsPlay(double t, BoxConstraints constraints) {
    final lamp1Lit = (t >= 0.05 && t < 0.22) || t >= 0.60;
    final lamp2Lit = (t >= 0.22 && t < 0.40) || t >= 0.82;
    final isWatch = t < 0.45;

    return Container(
      color: const Color(0xFF13182E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isWatch ? Colors.amber.shade900 : AppColors.leafGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isWatch ? '1. Watch lights 🪔' : '2. Tap in same order! 🪔',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLampMock('1', lamp1Lit),
              _buildLampMock('2', false),
              _buildLampMock('3', lamp2Lit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLampMock(String num, bool lit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          size: 32,
          color: lit ? Colors.amberAccent : Colors.transparent,
        ),
        Container(
          width: 54,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.teaBrown,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: lit
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(num, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // 6. My Day: Drag to reorder daily routine into order
  Widget _buildMyDayPlay(double t, BoxConstraints constraints) {
    final sorted = t >= 0.70;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRoutineItemMock('1. 🥣 Breakfast', false),
        _buildRoutineItemMock(sorted ? '2. 🚶 Morning Walk' : '2. 🛏️ Sleep (Drag Walk here!)', sorted),
        _buildRoutineItemMock(sorted ? '3. 🛏️ Night Sleep' : '3. 🚶 Morning Walk', false),
      ],
    );
  }

  Widget _buildRoutineItemMock(String text, bool highlight) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.leafGreen.withValues(alpha: 0.2) : AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.leafGreen : AppColors.border,
          width: highlight ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          if (highlight)
            const Icon(Icons.check_circle_rounded, color: AppColors.leafGreen, size: 18),
        ],
      ),
    );
  }

  // 7. Weaving Patterns: Match top Manipuri textile strip
  Widget _buildWeavingPlay(double t, BoxConstraints constraints) {
    final matched = t >= 0.62;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Text('Target Pattern:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildTextileStrip(const [Colors.red, Colors.amber, Colors.green, Colors.amber], 20),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                _buildTextileStrip(const [Colors.red, Colors.amber, Colors.green, Colors.amber], 24, matched: matched),
                const SizedBox(height: 2),
                Text(matched ? 'Match! ✓' : 'Option A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: matched ? AppColors.leafGreen : AppColors.primaryText,
                    )),
              ],
            ),
            Column(
              children: [
                _buildTextileStrip(const [Colors.green, Colors.red, Colors.amber, Colors.red], 24),
                const SizedBox(height: 2),
                const Text('Option B', style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextileStrip(List<Color> colors, double size, {bool matched = false}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: matched ? AppColors.leafGreen : AppColors.border,
          width: matched ? 3 : 1.5,
        ),
        boxShadow: matched
            ? [BoxShadow(color: AppColors.marigold.withValues(alpha: 0.5), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: colors
            .map((c) => Container(
                  width: size,
                  height: size,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  color: c,
                ))
            .toList(),
      ),
    );
  }

  // 8. Sounds of Home: Bird sound wave -> tap the drum
  Widget _buildSoundsHomePlay(double t, BoxConstraints constraints) {
    final birdSinging = t < 0.40;
    final drumTapped = t >= 0.56;

    return Container(
      color: const Color(0xFF24422D),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flutter_dash_rounded, color: AppColors.marigold, size: 36),
              const SizedBox(width: 8),
              Text(
                birdSinging ? '🎵 Chirp! Chirp!' : '🎵 Listen...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: drumTapped ? AppColors.marigold : AppColors.terracotta,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: drumTapped
                  ? [
                      BoxShadow(
                        color: AppColors.marigold.withValues(alpha: 0.7),
                        blurRadius: 18,
                        spreadRadius: 6,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                  Text(drumTapped ? '✓ Beat!' : 'Drum',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 9. Name the Harvest: Type word & tap Add
  Widget _buildNameHarvestPlay(double t, BoxConstraints constraints) {
    final typed = t >= 0.28;
    final added = t >= 0.62;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('Category: Vegetables 🥔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.raisedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    typed ? 'Potato 🥔' : 'Type here...',
                    style: TextStyle(
                      color: typed ? AppColors.primaryText : AppColors.secondaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
          if (added)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.leafGreen.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.leafGreen),
              ),
              child: const Text('🥔 Potato (+1 named!) ✓',
                  style: TextStyle(color: AppColors.leafGreen, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _HandData {
  const _HandData(this.position, {this.isPressing = false, this.rippleProgress = 0.0});
  final Offset position;
  final bool isPressing;
  final double rippleProgress;
}

class _PathLinePainter extends CustomPainter {
  const _PathLinePainter({required this.p1, required this.p2, required this.p3});
  final Offset p1;
  final Offset p2;
  final Offset p3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
