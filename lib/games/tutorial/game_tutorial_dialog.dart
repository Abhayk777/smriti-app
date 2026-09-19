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

  String _howToPlayLabel(String code) => gameTutorialHowToPlayLabel(code);
  String _letsPlayLabel(String code) => gameTutorialLetsPlayLabel(code);
  String _gameDescription(String id, String code, String fallback) =>
      gameTutorialDescription(id, code, fallback);
}

/// Localized "How to Play" header string across all 11 North-East regional languages.
String gameTutorialHowToPlayLabel(String code) {
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

/// Localized "Let's Play!" action button label.
String gameTutorialLetsPlayLabel(String code) {
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

/// Localized simple gameplay instruction for the tutorial stage.
String gameTutorialDescription(String id, String code, String fallback) {
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
        case 'as': return 'বস্তু চাই তলৰ সঠিক ডলাত টিপক';
        case 'bn': return 'জিনিস দেখে নিচের সঠিক ঝুড়িতে স্পর্শ করুন';
        case 'hi': return 'वस्तु देखकर नीचे सही टोकरी या मैट पर टैप करें';
        default: return 'Tap the basket or mat that matches the item';
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

  // Constant exact target coordinates for each game
  static const Offset sortCardPos = Offset(0.50, 0.24);
  static const Offset sortVegMatPos = Offset(0.30, 0.74);
  static const Offset sortFruitMatPos = Offset(0.70, 0.74);

  static const Offset marketApplePos = Offset(0.28, 0.35);
  static const Offset marketMilkPos = Offset(0.72, 0.35);
  static const Offset marketBasketPos = Offset(0.50, 0.78);

  static const Offset traceP1 = Offset(0.22, 0.48);
  static const Offset traceP2 = Offset(0.50, 0.30);
  static const Offset traceP3 = Offset(0.78, 0.54);

  static const Offset lamp1Pos = Offset(0.25, 0.56);
  static const Offset lamp2Pos = Offset(0.50, 0.38);
  static const Offset lamp3Pos = Offset(0.75, 0.56);

  static const Offset facePromptPos = Offset(0.50, 0.22);
  static const Offset faceCard1Pos = Offset(0.30, 0.68);
  static const Offset faceCard2Pos = Offset(0.70, 0.68);

  static const Offset myDayUpBtnPos = Offset(0.76, 0.48);
  static const Offset myDayDoneBtnPos = Offset(0.50, 0.88);

  static const Offset weaveMasterPos = Offset(0.50, 0.26);
  static const Offset weaveOpt1Pos = Offset(0.22, 0.72);
  static const Offset weaveOpt2Pos = Offset(0.50, 0.72);
  static const Offset weaveOpt3Pos = Offset(0.78, 0.72);

  static const Offset soundsDrumPos = Offset(0.50, 0.62);

  static const Offset nameInputPos = Offset(0.42, 0.46);
  static const Offset nameAddBtnPos = Offset(0.78, 0.46);

  _HandData _getHandData(String gameId, double t) {
    switch (gameId) {
      case 'sort_harvest':
        if (t < 0.22) {
          final p = Curves.easeOutCubic.transform(t / 0.22);
          return _HandData(Offset.lerp(const Offset(0.70, 0.60), sortCardPos, p)!);
        } else if (t < 0.48) {
          final p = Curves.easeInOutCubic.transform((t - 0.22) / 0.26);
          return _HandData(Offset.lerp(sortCardPos, sortVegMatPos, p)!);
        } else if (t < 0.65) {
          final rip = (t - 0.48) / 0.17;
          return _HandData(sortVegMatPos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.85) {
          final p = Curves.easeOut.transform((t - 0.65) / 0.20);
          return _HandData(Offset.lerp(sortVegMatPos, const Offset(0.32, 0.66), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.60));
        }

      case 'market_basket':
        if (t < 0.22) {
          final p = Curves.easeInOutCubic.transform(t / 0.22);
          return _HandData(Offset.lerp(const Offset(0.50, 0.75), marketApplePos, p)!);
        } else if (t < 0.34) {
          final rip = (t - 0.22) / 0.12;
          return _HandData(marketApplePos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.56) {
          final p = Curves.easeInOutCubic.transform((t - 0.34) / 0.22);
          return _HandData(Offset.lerp(marketApplePos, marketMilkPos, p)!);
        } else if (t < 0.68) {
          final rip = (t - 0.56) / 0.12;
          return _HandData(marketMilkPos, isPressing: true, rippleProgress: rip);
        } else {
          final p = Curves.easeOut.transform((t - 0.68) / 0.32);
          return _HandData(Offset.lerp(marketMilkPos, const Offset(0.60, 0.65), p)!);
        }

      case 'trace_path':
        if (t < 0.22) {
          final p = Curves.easeOutCubic.transform(t / 0.22);
          return _HandData(Offset.lerp(const Offset(0.12, 0.68), traceP1, p)!);
        } else if (t < 0.32) {
          final rip = (t - 0.22) / 0.10;
          return _HandData(traceP1, isPressing: true, rippleProgress: rip);
        } else if (t < 0.52) {
          final p = Curves.easeInOutCubic.transform((t - 0.32) / 0.20);
          return _HandData(Offset.lerp(traceP1, traceP2, p)!);
        } else if (t < 0.62) {
          final rip = (t - 0.52) / 0.10;
          return _HandData(traceP2, isPressing: true, rippleProgress: rip);
        } else if (t < 0.82) {
          final p = Curves.easeInOutCubic.transform((t - 0.62) / 0.20);
          return _HandData(Offset.lerp(traceP2, traceP3, p)!);
        } else if (t < 0.92) {
          final rip = (t - 0.82) / 0.10;
          return _HandData(traceP3, isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(traceP3);
        }

      case 'lamps_festival':
        if (t < 0.45) {
          return const _HandData(Offset(0.85, 0.85));
        } else if (t < 0.58) {
          final p = Curves.easeInOutCubic.transform((t - 0.45) / 0.13);
          return _HandData(Offset.lerp(const Offset(0.85, 0.85), lamp1Pos, p)!);
        } else if (t < 0.68) {
          final rip = (t - 0.58) / 0.10;
          return _HandData(lamp1Pos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.82) {
          final p = Curves.easeInOutCubic.transform((t - 0.68) / 0.14);
          return _HandData(Offset.lerp(lamp1Pos, lamp2Pos, p)!);
        } else if (t < 0.92) {
          final rip = (t - 0.82) / 0.10;
          return _HandData(lamp2Pos, isPressing: true, rippleProgress: rip);
        } else {
          return const _HandData(lamp2Pos);
        }

      case 'faces_of_family':
        if (t < 0.25) {
          final p = Curves.easeOutCubic.transform(t / 0.25);
          return _HandData(Offset.lerp(const Offset(0.70, 0.55), facePromptPos, p)!);
        } else if (t < 0.50) {
          final p = Curves.easeInOutCubic.transform((t - 0.25) / 0.25);
          return _HandData(Offset.lerp(facePromptPos, faceCard1Pos, p)!);
        } else if (t < 0.65) {
          final rip = (t - 0.50) / 0.15;
          return _HandData(faceCard1Pos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.85) {
          final p = Curves.easeOut.transform((t - 0.65) / 0.20);
          return _HandData(Offset.lerp(faceCard1Pos, const Offset(0.35, 0.60), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.55));
        }

      case 'my_day':
        if (t < 0.24) {
          final p = Curves.easeOutCubic.transform(t / 0.24);
          return _HandData(Offset.lerp(const Offset(0.85, 0.70), myDayUpBtnPos, p)!);
        } else if (t < 0.40) {
          final rip = (t - 0.24) / 0.16;
          return _HandData(myDayUpBtnPos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.68) {
          final p = Curves.easeInOutCubic.transform((t - 0.40) / 0.28);
          return _HandData(Offset.lerp(myDayUpBtnPos, myDayDoneBtnPos, p)!);
        } else if (t < 0.84) {
          final rip = (t - 0.68) / 0.16;
          return _HandData(myDayDoneBtnPos, isPressing: true, rippleProgress: rip);
        } else {
          final p = Curves.easeOut.transform((t - 0.84) / 0.16);
          return _HandData(Offset.lerp(myDayDoneBtnPos, const Offset(0.70, 0.75), p)!);
        }

      case 'weaving_patterns':
        if (t < 0.25) {
          final p = Curves.easeOutCubic.transform(t / 0.25);
          return _HandData(Offset.lerp(const Offset(0.35, 0.55), weaveMasterPos, p)!);
        } else if (t < 0.52) {
          final p = Curves.easeInOutCubic.transform((t - 0.25) / 0.27);
          return _HandData(Offset.lerp(weaveMasterPos, weaveOpt2Pos, p)!);
        } else if (t < 0.66) {
          final rip = (t - 0.52) / 0.14;
          return _HandData(weaveOpt2Pos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.85) {
          final p = Curves.easeOut.transform((t - 0.66) / 0.19);
          return _HandData(Offset.lerp(weaveOpt2Pos, const Offset(0.50, 0.64), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.55));
        }

      case 'sounds_home':
        if (t < 0.38) {
          return const _HandData(Offset(0.50, 0.30));
        } else if (t < 0.56) {
          final p = Curves.easeInOutCubic.transform((t - 0.38) / 0.18);
          return _HandData(Offset.lerp(const Offset(0.50, 0.30), soundsDrumPos, p)!);
        } else if (t < 0.68) {
          final rip = (t - 0.56) / 0.12;
          return _HandData(soundsDrumPos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.86) {
          final p = Curves.easeOut.transform((t - 0.68) / 0.18);
          return _HandData(Offset.lerp(soundsDrumPos, const Offset(0.50, 0.50), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.55));
        }

      case 'name_harvest':
      default:
        if (t < 0.26) {
          final p = Curves.easeOutCubic.transform(t / 0.26);
          return _HandData(Offset.lerp(const Offset(0.50, 0.75), nameInputPos, p)!);
        } else if (t < 0.48) {
          final p = Curves.easeInOutCubic.transform((t - 0.26) / 0.22);
          return _HandData(Offset.lerp(nameInputPos, nameAddBtnPos, p)!);
        } else if (t < 0.62) {
          final rip = (t - 0.48) / 0.14;
          return _HandData(nameAddBtnPos, isPressing: true, rippleProgress: rip);
        } else if (t < 0.85) {
          final p = Curves.easeOut.transform((t - 0.62) / 0.23);
          return _HandData(Offset.lerp(nameAddBtnPos, const Offset(0.78, 0.38), p)!);
        } else {
          return const _HandData(Offset(0.70, 0.55));
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

  // 1. Sort the Harvest: Authentic produce card & sorting mats
  Widget _buildSortHarvestPlay(double t, BoxConstraints constraints) {
    final tapped = t >= 0.48 && t < 0.88;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final cardW = w * 0.42;
    final cardH = h * 0.30;
    final matW = w * 0.40;
    final matH = h * 0.32;

    return Stack(
      children: [
        // Produce Card at top center
        Positioned(
          left: w * sortCardPos.dx - cardW / 2,
          top: h * sortCardPos.dy - cardH / 2,
          child: Container(
            width: cardW,
            height: cardH,
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (t < 0.25) ? AppColors.marigold : AppColors.border,
                width: (t < 0.25) ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🍅', style: TextStyle(fontSize: 32)),
                SizedBox(height: 4),
                Text('Tomato', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Item to sort', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),
        ),

        // Left Mat: Vegetables
        Positioned(
          left: w * sortVegMatPos.dx - matW / 2,
          top: h * sortVegMatPos.dy - matH / 2,
          child: Transform.scale(
            scale: (t >= 0.48 && t < 0.65) ? 0.94 : 1.0,
            child: Container(
              width: matW,
              height: matH,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: tapped ? AppColors.leafGreen.withValues(alpha: 0.25) : AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tapped ? AppColors.leafGreen : AppColors.bamboo,
                  width: tapped ? 3.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: tapped ? AppColors.leafGreen.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🥬', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 2),
                  Text(
                    tapped ? 'Vegetables ✓' : 'Vegetables',
                    style: TextStyle(
                      color: tapped ? AppColors.leafGreen : AppColors.primaryText,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    tapped ? '✓ Clicked!' : 'Tap here',
                    style: TextStyle(
                      color: tapped ? AppColors.leafGreen : AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right Mat: Fruits
        Positioned(
          left: w * sortFruitMatPos.dx - matW / 2,
          top: h * sortFruitMatPos.dy - matH / 2,
          child: Container(
            width: matW,
            height: matH,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🍎', style: TextStyle(fontSize: 26)),
                SizedBox(height: 2),
                Text('Fruits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Other mat', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Market Basket: Realistic wooden shelf & woven basket
  Widget _buildMarketBasketPlay(double t, BoxConstraints constraints) {
    final applePicked = t >= 0.22;
    final milkPicked = t >= 0.56;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final itemW = w * 0.36;
    final itemH = h * 0.28;
    final basketW = w * 0.70;
    final basketH = h * 0.28;

    return Stack(
      children: [
        // Wooden shelf bar
        Positioned(
          left: 12,
          right: 12,
          top: h * 0.46,
          height: 12,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A2B),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 3)),
              ],
            ),
          ),
        ),

        // Top Shopping banner
        Positioned(
          top: 10,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
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

        // Apple item
        Positioned(
          left: w * marketApplePos.dx - itemW / 2,
          top: h * marketApplePos.dy - itemH / 2,
          child: Container(
            width: itemW,
            height: itemH,
            decoration: BoxDecoration(
              color: applePicked ? AppColors.leafGreen.withValues(alpha: 0.2) : AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: applePicked ? AppColors.leafGreen : AppColors.border,
                width: applePicked ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🍎', style: TextStyle(fontSize: 26)),
                const Text('Apple', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (applePicked)
                  const Text('Picked ✓', style: TextStyle(color: AppColors.leafGreen, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),

        // Milk item
        Positioned(
          left: w * marketMilkPos.dx - itemW / 2,
          top: h * marketMilkPos.dy - itemH / 2,
          child: Container(
            width: itemW,
            height: itemH,
            decoration: BoxDecoration(
              color: milkPicked ? AppColors.leafGreen.withValues(alpha: 0.2) : AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: milkPicked ? AppColors.leafGreen : AppColors.border,
                width: milkPicked ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🥛', style: TextStyle(fontSize: 26)),
                const Text('Milk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                if (milkPicked)
                  const Text('Picked ✓', style: TextStyle(color: AppColors.leafGreen, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),

        // Basket at bottom
        Positioned(
          left: w * marketBasketPos.dx - basketW / 2,
          top: h * marketBasketPos.dy - basketH / 2,
          child: Container(
            width: basketW,
            height: basketH,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: (applePicked && milkPicked) ? AppColors.leafGreen.withValues(alpha: 0.25) : AppColors.wovenMat,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (applePicked && milkPicked) ? AppColors.leafGreen : AppColors.marigoldDark,
                width: 2.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_rounded, color: AppColors.marigoldDark, size: 28),
                const SizedBox(width: 10),
                Text(
                  (applePicked && milkPicked)
                      ? '🧺 2 / 2 Collected! ✓'
                      : (applePicked ? '🧺 1 / 2 Collected' : '🧺 Market Basket'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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

  // 3. Trace the Path: Meadow & River backdrop with realistic stone nodes
  Widget _buildTracePathPlay(double t, BoxConstraints constraints) {
    final s1 = t >= 0.22;
    final s2 = t >= 0.52;
    final s3 = t >= 0.82;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    return Stack(
      children: [
        // River meadow backdrop
        Positioned.fill(
          child: CustomPaint(
            painter: _TutorialRiverScenePainter(),
          ),
        ),

        // Path connector line
        CustomPaint(
          size: Size(w, h),
          painter: _PathLinePainter(
            p1: Offset(w * traceP1.dx, h * traceP1.dy),
            p2: Offset(w * traceP2.dx, h * traceP2.dy),
            p3: Offset(w * traceP3.dx, h * traceP3.dy),
            seg1Active: s2,
            seg2Active: s3,
          ),
        ),

        // Stone 1
        Positioned(
          left: w * traceP1.dx - 28,
          top: h * traceP1.dy - 28,
          child: _buildRealisticStone('1', s1),
        ),

        // Stone 2
        Positioned(
          left: w * traceP2.dx - 28,
          top: h * traceP2.dy - 28,
          child: _buildRealisticStone('2', s2),
        ),

        // Stone 3
        Positioned(
          left: w * traceP3.dx - 28,
          top: h * traceP3.dy - 28,
          child: _buildRealisticStone('3', s3),
        ),

        if (s3)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6),
                  ],
                ),
                child: const Text('⭐ Path Complete! ✓',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRealisticStone(String label, bool active) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: active ? AppColors.leafGreen : const Color(0xFF5C6B73),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          active ? '$label ✓' : label,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // 4. Lamps of the Festival: Authentic brass/clay diya lamps & midnight sky
  Widget _buildLampsPlay(double t, BoxConstraints constraints) {
    final lamp1Lit = (t >= 0.08 && t < 0.22) || t >= 0.58;
    final lamp2Lit = (t >= 0.24 && t < 0.38) || t >= 0.82;
    final isWatch = t < 0.45;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    return Container(
      color: const Color(0xFF10152B),
      child: Stack(
        children: [
          // Header mode badge
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: isWatch ? Colors.amber.shade900 : AppColors.leafGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isWatch ? '👀 1. Watch the sequence' : '👉 2. Tap lamps in same order!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ),

          // Lamp 1
          Positioned(
            left: w * lamp1Pos.dx - 36,
            top: h * lamp1Pos.dy - 36,
            child: _buildDiyaMock('1', lamp1Lit),
          ),

          // Lamp 2
          Positioned(
            left: w * lamp2Pos.dx - 36,
            top: h * lamp2Pos.dy - 36,
            child: _buildDiyaMock('2', lamp2Lit),
          ),

          // Lamp 3 (decor)
          Positioned(
            left: w * lamp3Pos.dx - 36,
            top: h * lamp3Pos.dy - 36,
            child: _buildDiyaMock('3', false),
          ),
        ],
      ),
    );
  }

  Widget _buildDiyaMock(String num, bool lit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flame
          Icon(
            Icons.local_fire_department_rounded,
            size: 28,
            color: lit ? const Color(0xFFFFB300) : Colors.transparent,
          ),
          // Clay bowl base
          Container(
            width: 52,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFB55333),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border.all(color: const Color(0xFFD48B4B), width: 1.5),
              boxShadow: lit
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.8),
                        blurRadius: 18,
                        spreadRadius: 4,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Faces of My Family: Framed family portraits & prompt
  Widget _buildFacesPlay(double t, BoxConstraints constraints) {
    final matched = t >= 0.50;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final cardW = w * 0.38;
    final cardH = h * 0.40;

    return Stack(
      children: [
        // Prompt banner
        Positioned(
          left: 20,
          right: 20,
          top: h * facePromptPos.dy - 18,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.marigold, width: 1.5),
              ),
              child: const Text('Who is Daughter (Anita)? 👧',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryText)),
            ),
          ),
        ),

        // Card 1: Daughter Anita
        Positioned(
          left: w * faceCard1Pos.dx - cardW / 2,
          top: h * faceCard1Pos.dy - cardH / 2,
          child: Container(
            width: cardW,
            height: cardH,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: matched ? AppColors.leafGreen.withValues(alpha: 0.20) : AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: matched ? AppColors.leafGreen : AppColors.border,
                width: matched ? 3.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: matched ? AppColors.leafGreen.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.medicineBlush,
                  child: Icon(Icons.face_3_rounded, size: 26, color: AppColors.terracotta),
                ),
                const SizedBox(height: 4),
                const Text('Anita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(matched ? '❤️ Match! ✓' : 'Daughter',
                    style: TextStyle(
                      color: matched ? AppColors.leafGreen : AppColors.secondaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ),

        // Card 2: Grandson
        Positioned(
          left: w * faceCard2Pos.dx - cardW / 2,
          top: h * faceCard2Pos.dy - cardH / 2,
          child: Container(
            width: cardW,
            height: cardH,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.bottomStrip,
                  child: Icon(Icons.face_rounded, size: 26, color: AppColors.indigo),
                ),
                SizedBox(height: 4),
                Text('Rahul', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Grandson', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 6. My Day: Arrange jumbled daily routine into chronological order
  Widget _buildMyDayPlay(double t, BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final cardW = (w * 0.90).clamp(240.0, 520.0);
    final cardH = (h * 0.18).clamp(34.0, 50.0);

    // Swap animation between Lunch and Morning Tea
    final swapP = t < 0.32 ? 0.0 : ((t - 0.32) / 0.18).clamp(0.0, 1.0);
    final swapCurve = Curves.easeInOutCubic.transform(swapP);
    final isSwapped = swapP >= 0.5;
    final isDone = t >= 0.74;
    final isUpPressed = t >= 0.24 && t < 0.38;
    final isDonePressed = t >= 0.68 && t < 0.82;

    // Slot Y positions
    final slot1Y = h * 0.26;
    final slot2Y = h * 0.48;
    final slot3Y = h * 0.69;

    // Lunch starts at Slot 1 and moves down to Slot 2
    final lunchY = slot1Y + (slot2Y - slot1Y) * swapCurve;
    // Morning Tea starts at Slot 2 and moves up to Slot 1
    final teaY = slot2Y - (slot2Y - slot1Y) * swapCurve;
    // Sleep stays at Slot 3
    final sleepY = slot3Y;

    return Stack(
      children: [
        // Top Banner: Morning to Night
        Positioned(
          top: h * 0.04,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.marigold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌅', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    'Put in order: Morning to Night',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('🌙', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),

        // Lunch Card (starts at #1, moves to #2)
        _buildRoutineCard(
          badge: isSwapped ? '2' : '1',
          emoji: '🍛',
          label: 'Lunch',
          y: lunchY,
          cardW: cardW,
          cardH: cardH,
          isDone: isDone,
          isHighlighted: !isSwapped,
          constraints: constraints,
        ),

        // Morning Tea Card (starts at #2, moves to #1 on Up tap)
        _buildRoutineCard(
          badge: isSwapped ? '1' : '2',
          emoji: '🍵',
          label: 'Morning Tea',
          y: teaY,
          cardW: cardW,
          cardH: cardH,
          isDone: isDone,
          isHighlighted: isSwapped,
          showUpPressed: isUpPressed && !isSwapped,
          constraints: constraints,
        ),

        // Sleep Card (stays at #3)
        _buildRoutineCard(
          badge: '3',
          emoji: '🌙',
          label: 'Sleep',
          y: sleepY,
          cardW: cardW,
          cardH: cardH,
          isDone: isDone,
          isHighlighted: false,
          isLast: true,
          constraints: constraints,
        ),

        // Done button at bottom
        Positioned(
          left: w * myDayDoneBtnPos.dx - 65,
          top: h * myDayDoneBtnPos.dy - 16,
          child: Transform.scale(
            scale: isDonePressed ? 0.92 : 1.0,
            child: Container(
              width: 130,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.leafGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.leafGreen.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDone ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isDone ? 'Well Done! ✓' : 'Done',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutineCard({
    required String badge,
    required String emoji,
    required String label,
    required double y,
    required double cardW,
    required double cardH,
    required bool isDone,
    required bool isHighlighted,
    required BoxConstraints constraints,
    bool showUpPressed = false,
    bool isLast = false,
  }) {
    final w = constraints.maxWidth;
    return Positioned(
      left: (w - cardW) / 2,
      top: y - cardH / 2,
      child: Container(
        width: cardW,
        height: cardH,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: isDone
              ? AppColors.leafGreen.withValues(alpha: 0.12)
              : AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppColors.leafGreen
                : (isHighlighted ? AppColors.marigold : AppColors.border),
            width: (isDone || isHighlighted) ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular number badge
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.leafGreen
                    : AppColors.marigold.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                isDone ? '✓' : badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDone ? Colors.white : AppColors.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Emoji
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            // Label
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Up Arrow button
            Transform.scale(
              scale: showUpPressed ? 0.85 : 1.0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: showUpPressed
                      ? AppColors.marigold.withValues(alpha: 0.3)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 20,
                  color: AppColors.marigold,
                ),
              ),
            ),
            const SizedBox(width: 2),
            // Down Arrow button
            Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: isLast
                  ? AppColors.marigold.withValues(alpha: 0.3)
                  : AppColors.marigold,
            ),
            const SizedBox(width: 4),
            // Drag handle
            Icon(
              Icons.drag_handle_rounded,
              size: 20,
              color: AppColors.secondaryText.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  // 7. Weaving Patterns: Traditional loom motifs
  Widget _buildWeavingPlay(double t, BoxConstraints constraints) {
    final matched = t >= 0.52;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final optW = w * 0.28;
    final optH = h * 0.28;

    return Stack(
      children: [
        // Master swatch at top
        Positioned(
          left: w * weaveMasterPos.dx - 80,
          top: h * weaveMasterPos.dy - 34,
          child: Container(
            width: 160,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bamboo, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Target Motif:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                _buildPatternStripe(const [Color(0xFF8B263E), Color(0xFFD4AF37), Color(0xFF2E6F40)]),
              ],
            ),
          ),
        ),

        // Option 1
        Positioned(
          left: w * weaveOpt1Pos.dx - optW / 2,
          top: h * weaveOpt1Pos.dy - optH / 2,
          child: _buildSwatchCard(const [Color(0xFF2E6F40), Color(0xFF8B263E), Color(0xFFD4AF37)], false, optW, optH),
        ),

        // Option 2 (Match)
        Positioned(
          left: w * weaveOpt2Pos.dx - optW / 2,
          top: h * weaveOpt2Pos.dy - optH / 2,
          child: _buildSwatchCard(const [Color(0xFF8B263E), Color(0xFFD4AF37), Color(0xFF2E6F40)], matched, optW, optH),
        ),

        // Option 3
        Positioned(
          left: w * weaveOpt3Pos.dx - optW / 2,
          top: h * weaveOpt3Pos.dy - optH / 2,
          child: _buildSwatchCard(const [Color(0xFFD4AF37), Color(0xFF8B263E), Color(0xFF8B263E)], false, optW, optH),
        ),
      ],
    );
  }

  Widget _buildPatternStripe(List<Color> colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors
          .map((c) => Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
              ))
          .toList(),
    );
  }

  Widget _buildSwatchCard(List<Color> colors, bool active, double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: active ? AppColors.leafGreen.withValues(alpha: 0.22) : AppColors.raisedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.leafGreen : AppColors.border,
          width: active ? 3 : 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPatternStripe(colors),
          const SizedBox(height: 4),
          Text(active ? 'Match! ✓' : 'Pattern',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: active ? AppColors.leafGreen : AppColors.secondaryText,
              )),
        ],
      ),
    );
  }

  // 8. Sounds of Home: Audio waveform & traditional Dhol drum
  Widget _buildSoundsHomePlay(double t, BoxConstraints constraints) {
    final struck = t >= 0.56 && t < 0.86;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    return Container(
      color: const Color(0xFF1B3322),
      child: Stack(
        children: [
          // Audio header
          Positioned(
            top: 14,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flutter_dash_rounded, color: AppColors.marigold, size: 28),
                const SizedBox(width: 8),
                Text(
                  t < 0.38 ? '🎵 Bird Chirping! Listen...' : '🎵 Strike the Drum on beat!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),

          // Folk drum at center
          Positioned(
            left: w * soundsDrumPos.dx - 48,
            top: h * soundsDrumPos.dy - 48,
            child: Transform.scale(
              scale: struck ? 1.10 : 1.0,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: struck ? AppColors.marigold : const Color(0xFF8B4513),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: struck
                      ? [
                          BoxShadow(
                            color: AppColors.marigold.withValues(alpha: 0.85),
                            blurRadius: 24,
                            spreadRadius: 8,
                          )
                        ]
                      : [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note_rounded, color: Colors.white, size: struck ? 32 : 26),
                      Text(
                        struck ? '✓ BEAT!' : 'Dhol',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
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

  // 9. Name the Harvest: Text search & Add button
  Widget _buildNameHarvestPlay(double t, BoxConstraints constraints) {
    final added = t >= 0.48;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final inputW = w * 0.54;
    final addBtnW = w * 0.24;

    return Stack(
      children: [
        // Category prompt
        Positioned(
          top: 14,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('Category: 🥬 Vegetables',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryText)),
            ),
          ),
        ),

        // Text input field
        Positioned(
          left: w * nameInputPos.dx - inputW / 2,
          top: h * nameInputPos.dy - 22,
          child: Container(
            width: inputW,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.marigold, width: 2),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: AppColors.secondaryText),
                SizedBox(width: 8),
                Text('Potato 🥔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ),

        // Add button
        Positioned(
          left: w * nameAddBtnPos.dx - addBtnW / 2,
          top: h * nameAddBtnPos.dy - 22,
          child: Transform.scale(
            scale: (t >= 0.48 && t < 0.62) ? 0.92 : 1.0,
            child: Container(
              width: addBtnW,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.leafGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: AppColors.leafGreen.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 4),
                    Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Result tag chip
        if (added)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.leafGreen, width: 2),
                ),
                child: const Text('🥔 Potato (+1 named!) ✓',
                    style: TextStyle(color: AppColors.leafGreen, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ),
      ],
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
  const _PathLinePainter({
    required this.p1,
    required this.p2,
    required this.p3,
    this.seg1Active = false,
    this.seg2Active = false,
  });

  final Offset p1;
  final Offset p2;
  final Offset p3;
  final bool seg1Active;
  final bool seg2Active;

  @override
  void paint(Canvas canvas, Size size) {
    // Segment 1 (p1 -> p2)
    final paint1 = Paint()
      ..color = seg1Active ? AppColors.leafGreen : Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = seg1Active ? 4.5 : 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p1, p2, paint1);

    // Segment 2 (p2 -> p3)
    final paint2 = Paint()
      ..color = seg2Active ? AppColors.leafGreen : Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = seg2Active ? 4.5 : 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(p2, p3, paint2);
  }

  @override
  bool shouldRepaint(covariant _PathLinePainter oldDelegate) =>
      oldDelegate.seg1Active != seg1Active || oldDelegate.seg2Active != seg2Active;
}

/// River meadow painter matching TracePathWidget aesthetics
class _TutorialRiverScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Meadow green background gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCE9C4), Color(0xFFB7D19A), Color(0xFF9DBB80)],
        ).createShader(Offset.zero & size),
    );

    // River bed
    final stream = Path()
      ..moveTo(-10, h * 0.40)
      ..cubicTo(w * 0.30, h * 0.18, w * 0.55, h * 0.58, w * 0.80, h * 0.38)
      ..cubicTo(w * 0.95, h * 0.30, w * 1.05, h * 0.45, w * 1.10, h * 0.48);

    // Sand shore
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.28
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE6D8B5),
    );

    // Blue water
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.20
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          colors: [Color(0xFF8CC4E0), Color(0xFF5FA6CC)],
        ).createShader(Offset.zero & size),
    );

    // Water shimmer
    canvas.drawPath(
      stream,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
