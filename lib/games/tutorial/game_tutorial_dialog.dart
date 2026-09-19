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
/// Features a realistic animated pointing hand demonstrating the game gesture,
/// with contact ripples and directional cues, styled for elderly users.
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
  late final GhostHandController _handController;
  Timer? _loopTimer;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _handController = GhostHandController();
    _startDemoLoop();

    // Auto-dismiss after 9 seconds if elder just watches, so they aren't stuck
    _autoDismissTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _startDemoLoop() {
    final path = _demoPathFor(widget.gameId);
    _handController.play(path);

    _loopTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted && !_handController.isPlaying) {
        _handController.play(path);
      }
    });
  }

  List<Offset> _demoPathFor(String gameId) {
    switch (gameId) {
      case 'sort_harvest':
        return const [Offset(0.5, 0.32), Offset(0.28, 0.72)];
      case 'trace_path':
        return const [Offset(0.25, 0.45), Offset(0.5, 0.45), Offset(0.75, 0.45)];
      case 'market_basket':
        return const [Offset(0.35, 0.5), Offset(0.65, 0.5)];
      case 'lamps_festival':
        return const [Offset(0.28, 0.5), Offset(0.5, 0.5), Offset(0.72, 0.5)];
      case 'faces_of_family':
        return const [Offset(0.5, 0.35), Offset(0.5, 0.7)];
      case 'my_day':
        return const [Offset(0.5, 0.35), Offset(0.5, 0.65)];
      case 'weaving_patterns':
        return const [Offset(0.5, 0.68), Offset(0.5, 0.35)];
      case 'sounds_home':
        return const [Offset(0.5, 0.35), Offset(0.35, 0.65)];
      case 'name_harvest':
      default:
        return const [Offset(0.5, 0.4), Offset(0.5, 0.7)];
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _autoDismissTimer?.cancel();
    _handController.stop();
    _handController.dispose();
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

            // 2. Demonstration Stage with Animated Ghost Hand
            Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 18),
              child: Column(
                children: [
                  // Clear description
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

                  // Animated interactive stage
                  Container(
                    height: isCompact ? 150 : 210,
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
                    child: Stack(
                      children: [
                        // Background mock elements for the game
                        Positioned.fill(
                          child: _buildStageMock(widget.gameId, isCompact),
                        ),

                        // Realistic animated ghost hand overlay
                        Positioned.fill(
                          child: GhostHandOverlay(
                            controller: _handController,
                            onTapAnywhereToDismiss: widget.onDismiss,
                          ),
                        ),
                      ],
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

  Widget _buildStageMock(String gameId, bool isCompact) {
    switch (gameId) {
      case 'sort_harvest':
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.marigold, width: 2),
              ),
              child: const Text('🍅 Tomato', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMockBox('Vegetables', AppColors.leafGreen),
                _buildMockBox('Fruits', AppColors.terracotta),
              ],
            ),
          ],
        );

      case 'trace_path':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMockNode('1', AppColors.leafGreen),
            _buildMockNode('2', AppColors.marigold),
            _buildMockNode('3', AppColors.terracotta),
          ],
        );

      case 'lamps_festival':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text('🪔', style: TextStyle(fontSize: 36)),
            const Text('🪔', style: TextStyle(fontSize: 36)),
            const Text('🪔', style: TextStyle(fontSize: 36)),
          ],
        );

      default:
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.raisedSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.indigo, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.touch_app_rounded, color: AppColors.terracotta, size: 28),
                SizedBox(width: 10),
                Text('Tap to pick the correct item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMockBox(String label, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMockNode(String label, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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
