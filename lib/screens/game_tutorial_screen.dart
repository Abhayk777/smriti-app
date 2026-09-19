import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/i18n/locale_controller.dart';
import '../games/game_catalog.dart';
import '../games/tutorial/game_tutorial_dialog.dart';
import 'game_screen.dart';

/// Dedicated tutorial screen displayed before any cognitive game starts.
///
/// Features a realistic animated 3D ghost hand actively demonstrating the
/// game mechanics so the elder understands how to play without stress.
/// The game session only starts when the elder explicitly taps "Let's Play".
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
        MaterialPageRoute(
          builder: (_) => GameScreen(gameId: gameId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = gameInfoFor(gameId);
    final themeColor = info?.color ?? AppColors.terracotta;
    final lang = LocaleController.instance.currentLanguage;
    final title = info?.name ?? gameId;
    final isCompact = MediaQuery.of(context).size.height < 550;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          color: AppColors.primaryText,
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: themeColor.withValues(alpha: 0.15),
              child: Icon(info?.icon ?? Icons.games, color: themeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    gameTutorialHowToPlayLabel(lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 24,
            vertical: isCompact ? 8 : 16,
          ),
          child: Column(
            children: [
              // Interactive 3D ghost hand demonstration stage
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.raisedSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveGameDemoStage(
                    gameId: gameId,
                    isCompact: isCompact,
                    onTapAnywhere: () => _onProceed(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Clear Instruction Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.medallion,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.bamboo, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.touch_app_rounded, color: themeColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        gameTutorialDescription(
                          gameId,
                          lang,
                          info?.description ?? 'Follow the animated hand to play.',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Big high-contrast CTA button
              SizedBox(
                width: double.infinity,
                height: isCompact ? 54 : 64,
                child: ElevatedButton.icon(
                  onPressed: () => _onProceed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFromGame ? AppColors.terracotta : AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: Icon(
                    isFromGame ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                    size: isCompact ? 26 : 32,
                  ),
                  label: Text(
                    isFromGame
                        ? (lang == 'hi' ? 'खेल जारी रखें' : 'Resume Game')
                        : gameTutorialLetsPlayLabel(lang),
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
