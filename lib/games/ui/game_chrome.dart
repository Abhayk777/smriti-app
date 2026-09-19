import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../ui/smriti_ui.dart';
import '../game_catalog.dart';

/// The wash of the game's colour that fades into the page. Shared by the real
/// game screen and the tutorial, so the two always look the same.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, AppColors.pageBackground, 0.86)!,
            AppColors.pageBackground,
          ],
          stops: const [0.0, 0.55],
        ),
      ),
      child: child,
    );
  }
}

/// The bar across the top of a game: the game's photo and name, the timer, a
/// "how to play" button and a close button, with a thin progress line under
/// it. Shared by the real game screen and the tutorial.
class GameTopBar extends StatelessWidget {
  const GameTopBar({
    super.key,
    required this.info,
    required this.title,
    required this.elapsed,
    this.onHelp,
    this.onClose,
    this.compact = false,
  });

  final GameInfo info;
  final String title;
  final Duration elapsed;
  final VoidCallback? onHelp;
  final VoidCallback? onClose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = info.color;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final progress = (elapsed.inSeconds / 360.0).clamp(0.0, 1.0);
    final tint = color.withValues(alpha: 0.13);

    Widget roundButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      required Color background,
      required Color foreground,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: foreground, size: 25),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, compact ? 6 : 10, 14, compact ? 6 : 10),
          child: Row(
            children: [
              IconMedallion(
                icon: info.icon,
                image: info.image,
                color: color,
                size: compact ? 40 : 46,
                background: tint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: color),
                    const SizedBox(width: 5),
                    Text(
                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              roundButton(
                icon: Icons.help_outline_rounded,
                tooltip: 'How to play',
                background: tint,
                foreground: color,
                onPressed: onHelp,
              ),
              const SizedBox(width: 8),
              roundButton(
                icon: Icons.close_rounded,
                tooltip: 'Stop playing',
                background: AppColors.raisedSurface,
                foreground: AppColors.primaryText,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.16),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ),
      ],
    );
  }
}

/// A prompt that tells the elder what to do, in one calm line on a soft
/// tinted pill. Every game uses it, so instructions look the same everywhere.
class GamePrompt extends StatelessWidget {
  const GamePrompt(this.text, {super.key, this.icon, this.color, this.dark = false});

  final String text;
  final IconData? icon;
  final Color? color;

  /// True on the dark game backgrounds (lamps, sounds).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.terracotta;
    final compact = MediaQuery.sizeOf(context).height < 500;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.1) : c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 22 : 26, color: dark ? const Color(0xFFFFD98A) : c),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: dark ? const Color(0xFFFFE9B8) : AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
