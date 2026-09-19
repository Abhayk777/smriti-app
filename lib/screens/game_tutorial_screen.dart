import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/i18n/locale_controller.dart';
import '../games/game_catalog.dart';
import '../games/tutorial/game_demo_stage.dart';
import '../games/tutorial/game_tutorial_dialog.dart';
import '../games/ui/game_chrome.dart';
import '../ui/smriti_ui.dart';
import 'game_screen.dart';

/// The screen shown before a game starts. The real game plays itself inside a
/// phone-shaped frame, with a ghost hand tapping the right answers; one plain
/// sentence explains it, and the game begins when the elder taps "Let's
/// Play!". Also opened mid-game from the "?" button.
class GameTutorialScreen extends StatelessWidget {
  const GameTutorialScreen({
    super.key,
    required this.gameId,
    this.isFromGame = false,
  });

  final String gameId;
  final bool isFromGame;

  void _onProceed(BuildContext context) {
    if (isFromGame) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(gameId: gameId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = gameInfoFor(gameId);
    final color = info?.color ?? AppColors.terracotta;
    final lang = LocaleController.instance.currentLanguage;
    final title = info?.name ?? gameId;
    final compact = MediaQuery.sizeOf(context).height < 560;
    final gutter = Screen.gutter(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: GameBackdrop(
        color: color,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, compact ? 6 : 12, gutter, compact ? 10 : 18),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        RoundBackButton(onPressed: () => Navigator.of(context).pop()),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                gameTutorialHowToPlayLabel(lang),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 14),

                    // The real game, playing itself in a phone frame
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final ratio = kDemoScreen.width / kDemoScreen.height;
                          final captionH = compact ? 0.0 : 104.0;
                          const bezel = 8.0;
                          final availH = c.maxHeight - captionH - 12;
                          final frameW = math.min(c.maxWidth, availH * ratio + bezel * 2);
                          final innerW = frameW - bezel * 2;
                          final innerH = innerW / ratio;
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: frameW,
                                    padding: const EdgeInsets.all(bezel),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(38),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.28),
                                          blurRadius: 30,
                                          offset: const Offset(0, 14),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: SizedBox(
                                        width: innerW,
                                        height: innerH,
                                        child: InteractiveGameDemoStage(
                                          gameId: gameId,
                                          isCompact: compact,
                                          onTapAnywhere: () => _onProceed(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: frameW,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.raisedSurface,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.07),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.14),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.touch_app_rounded, color: color, size: 24),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              gameTutorialDescription(
                                                gameId,
                                                lang,
                                                info?.description ?? 'Follow the hand to play.',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                height: 1.25,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 14),

                    // Start
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 56 : 66,
                      child: ElevatedButton.icon(
                        onPressed: () => _onProceed(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFromGame ? AppColors.terracotta : AppColors.leafGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: Icon(
                          isFromGame ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                          size: compact ? 26 : 34,
                        ),
                        label: Text(
                          isFromGame
                              ? (lang == 'hi' ? 'खेल जारी रखें' : 'Resume Game')
                              : gameTutorialLetsPlayLabel(lang),
                          style: TextStyle(
                            fontSize: compact ? 19 : 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
