import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

// ---------------------------------------------------------------------------
// Layout helpers
// ---------------------------------------------------------------------------

/// Screen-size rules shared by every screen.
///
/// A device is a tablet when its shortest side is at least 600dp, the same
/// threshold Android uses for `sw600dp`. Layout choices use the live width
/// and height rather than the device type, so a tablet that the system lets
/// rotate (Android 16+ ignores orientation locks on large screens) still gets
/// a layout that fits.
class Screen {
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  /// Wide enough for side-by-side panels.
  static bool isWide(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= 720 && size.width > size.height;
  }

  /// Horizontal page padding.
  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600 ? 32 : 18;
}

/// Centres its child and caps its width, so lists and forms stay readable on
/// large tablets.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 960});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class SmritiTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.terracotta,
      onPrimary: AppColors.onColor,
      secondary: AppColors.indigo,
      onSecondary: AppColors.onColor,
      tertiary: AppColors.leafGreen,
      surface: AppColors.raisedSurface,
      onSurface: AppColors.primaryText,
      onSurfaceVariant: AppColors.secondaryText,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final rounded16 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final textTheme = Typography.blackMountainView.apply(
      bodyColor: AppColors.primaryText,
      displayColor: AppColors.primaryText,
    );
    final buttonText = textTheme.labelLarge!.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w700,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      splashFactory: InkRipple.splashFactory,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText, size: 28),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.onColor,
          disabledBackgroundColor: AppColors.wovenMat,
          disabledForegroundColor: AppColors.secondaryText,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: rounded16,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.terracottaDark,
          backgroundColor: AppColors.wovenMat.withValues(alpha: 0.5),
          minimumSize: const Size(64, 52),
          side: BorderSide.none,
          shape: rounded16,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracottaDark,
          minimumSize: const Size(48, 48),
          textStyle: buttonText.copyWith(fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.raisedSurface,
        hintStyle: const TextStyle(color: AppColors.secondaryText),
        border: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.wovenMat, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.wovenMat, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          borderSide: BorderSide(color: AppColors.terracotta, width: 3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryText,
        contentTextStyle: const TextStyle(
          fontSize: 17,
          color: AppColors.onColor,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.raisedSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.secondaryText,
          height: 1.4,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.terracotta,
        linearTrackColor: AppColors.border,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide.none,
        shape: StadiumBorder(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// Pass as `image` to draw a home with a heart instead of a photo.
const familyHomeGlyph = 'family_home';

/// A little house with a heart in its doorway: family and home.
class FamilyHomeGlyph extends StatelessWidget {
  const FamilyHomeGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.home_rounded, color: color, size: size * 0.66),
          Positioned(
            top: size * 0.44,
            child: Icon(Icons.favorite_rounded, color: AppColors.medallion, size: size * 0.24),
          ),
        ],
      ),
    );
  }
}

/// Round ivory disc holding an icon, the signature element of every tile.
class IconMedallion extends StatelessWidget {
  const IconMedallion({
    super.key,
    required this.icon,
    required this.color,
    this.size = 64,
    this.background = AppColors.medallion,
    this.image,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Color background;

  /// Photo inside `assets/images/photos/` (for example `game_lamps.jpg`).
  /// When set, the illustration replaces [icon].
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: image == null
          ? Icon(icon, color: color, size: size * 0.5)
          : image == familyHomeGlyph
              ? FamilyHomeGlyph(size: size, color: color)
              : ClipOval(
              child: Image.asset(
                'assets/images/photos/$image',
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    Icon(icon, color: color, size: size * 0.5),
              ),
            ),
    );
  }
}

/// Large round back button with an ample touch target.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: AppColors.wovenMat.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.primaryText,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

/// Page header: back button, icon, title and optional subtitle, sitting on a
/// slim woven band.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.image,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? image;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final gutter = Screen.gutter(context);
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 14, gutter, 14),
          child: Row(
            children: [
              RoundBackButton(onPressed: onBack),
              const SizedBox(width: 14),
              if (!compact) ...[
                IconMedallion(
                  icon: icon,
                  color: color,
                  image: image,
                  size: 52,
                  background: color.withValues(alpha: 0.12),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
        const GamosaBand(),
      ],
    );
  }
}

/// Friendly message for an empty list.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconMedallion(
              icon: icon,
              color: color,
              size: 112,
              background: color.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Solid tile with a pressed state that sinks slightly.
class PressableCard extends StatefulWidget {
  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.raisedSurface,
    this.borderColor,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: _pressed
                  ? Color.lerp(widget.color, Colors.black, 0.06)
                  : widget.color,
              borderRadius: BorderRadius.circular(widget.radius),
              // Outlines were replaced by soft fills and divider lines.
              boxShadow: widget.borderColor == null
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.terracottaDeep.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Large coloured action tile: medallion, title, subtitle and chevron.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.foreground = AppColors.onColor,
    this.iconColor,
    this.height,
    this.image,
  });

  final String? image;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color foreground;

  /// Icon colour inside the medallion; defaults to the tile colour.
  final Color? iconColor;
  final VoidCallback onTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 112.0);
        final medallion = (h * 0.62).clamp(56.0, 96.0);
        final titleSize = (h * 0.26).clamp(22.0, 34.0);
        final subSize = (h * 0.15).clamp(15.0, 19.0);
        return SizedBox(
          height: h,
          child: PressableCard(
            color: color,
            radius: 28,
            onTap: onTap,
            semanticLabel: title,
            padding: EdgeInsets.symmetric(horizontal: h < 110 ? 14 : 20),
            child: Row(
              children: [
                IconMedallion(
                  icon: icon,
                  color: iconColor ?? color,
                  image: image,
                  size: medallion,
                ),
                SizedBox(width: h < 110 ? 14 : 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: foreground,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subSize,
                          fontWeight: FontWeight.w500,
                          color: foreground.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: foreground,
                  size: 36,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// North-East motifs
// ---------------------------------------------------------------------------

/// Slim strip inspired by the Assamese gamosa border: two thin red rules with
/// a row of small woven diamonds between them.
class GamosaBand extends StatelessWidget {
  const GamosaBand({super.key, this.height = 12, this.opacity = 0.55});

  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _GamosaPainter(opacity: opacity)),
      ),
    );
  }
}

class _GamosaPainter extends CustomPainter {
  _GamosaPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..color = AppColors.gamosaRed.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final rule = size.height * 0.12;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rule), red);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - rule, size.width, rule),
      red,
    );

    final mid = size.height / 2;
    final d = size.height * 0.26;
    const step = 22.0;
    for (var x = step / 2; x < size.width; x += step) {
      final path = Path()
        ..moveTo(x, mid - d)
        ..lineTo(x + d, mid)
        ..lineTo(x, mid + d)
        ..lineTo(x - d, mid)
        ..close();
      canvas.drawPath(path, red);
    }
  }

  @override
  bool shouldRepaint(covariant _GamosaPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Rolling hills under a morning sun, a quiet nod to the North-East
/// landscape. When [animate] is on, the sun's rays breathe very slowly.
class HillsScene extends StatefulWidget {
  const HillsScene({super.key, this.showSun = true, this.animate = false});

  final bool showSun;
  final bool animate;

  @override
  State<HillsScene> createState() => _HillsSceneState();
}

class _HillsSceneState extends State<HillsScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _HillsPainter(
              showSun: widget.showSun,
              glow: still || !widget.animate
                  ? 0.5
                  : Curves.easeInOut.transform(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  _HillsPainter({required this.showSun, required this.glow});

  final bool showSun;

  /// 0 to 1; lengthens the rays a little.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showSun) {
      final sunCenter = Offset(w * 0.62, h * 0.42);
      final r = math.min(w, h) * 0.17;
      final rays = Paint()
        ..color = AppColors.marigold
        ..strokeWidth = math.max(2.5, r * 0.14)
        ..strokeCap = StrokeCap.round;
      final reach = 1.70 + glow * 0.18;
      for (var i = 0; i < 7; i++) {
        final a = math.pi + (math.pi / 6) * i;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(sunCenter + dir * r * 1.35, sunCenter + dir * r * reach, rays);
      }
      canvas.drawCircle(sunCenter, r, Paint()..color = AppColors.marigold);
    }

    final far = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.22, h * 0.50, w * 0.45, h * 0.70)
      ..quadraticBezierTo(w * 0.70, h * 0.88, w, h * 0.58)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()..color = AppColors.leafGreen.withValues(alpha: 0.55),
    );

    final near = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.35, h * 0.62, w * 0.62, h * 0.80)
      ..quadraticBezierTo(w * 0.82, h * 0.92, w, h * 0.78)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(near, Paint()..color = AppColors.leafGreen);
  }

  @override
  bool shouldRepaint(covariant _HillsPainter oldDelegate) =>
      oldDelegate.showSun != showSun || oldDelegate.glow != glow;
}

/// Formats minutes from midnight as "8:05 AM".
String formatClock(int hour, int minute) {
  final period = hour >= 12 ? 'PM' : 'AM';
  final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$h:${minute.toString().padLeft(2, '0')} $period';
}

// ---------------------------------------------------------------------------
// Gentle motion
// ---------------------------------------------------------------------------

/// Fades and slides its child up into place once, after [delay]. Motion is
/// slow and short so it reads as calm, and is skipped when the system asks
/// for reduced animations.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 520);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _run,
  )..forward();

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      widget.delay.inMilliseconds / (widget.delay + _run).inMilliseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Makes any child feel touchable: it sinks slightly while pressed and gives
/// a light haptic tick when tapped.
class BouncyTap extends StatefulWidget {
  const BouncyTap({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.93,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<BouncyTap> createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Grows its child in with a soft overshoot, for moments of success.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: ((v - 0.4) / 0.6).clamp(0.0, 1.0),
        child: Transform.scale(scale: v, child: child),
      ),
    );
  }
}

/// A real photograph of an everyday item (a food, a meal), looked up by id in
/// `assets/images/photos/`. Falls back to the item's emoji when no photo
/// exists, so items the caregiver adds still show something friendly.
class ItemPhoto extends StatelessWidget {
  const ItemPhoto({
    super.key,
    required this.id,
    required this.emoji,
    this.emojiSize = 40,
  });

  final String id;
  final String emoji;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/photos/$id.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: 480,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => ColoredBox(
        color: AppColors.medallion,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: emojiSize)),
        ),
      ),
    );
  }
}

/// Dark-to-clear fade laid over the bottom of a photo so white text on it
/// stays readable.
class PhotoScrim extends StatelessWidget {
  const PhotoScrim({super.key, this.strength = 0.72});

  final double strength;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.45, 1.0],
          colors: [
            Colors.transparent,
            const Color(0xFF1C1410).withValues(alpha: strength),
          ],
        ),
      ),
    );
  }
}

/// Round photo for a routine step (wake up, breakfast, lunch...). Tries the
/// step's own id, then a photo matched from its icon or label words, then the
/// step's emoji, then a friendly icon, so it never shows raw words.
class RoutinePhoto extends StatelessWidget {
  const RoutinePhoto({
    super.key,
    required this.id,
    required this.emoji,
    required this.size,
    this.label = '',
  });

  final String id;
  final String emoji;
  final String label;
  final double size;

  static const _photoByWord = <String, String>{
    'wake': 'wake_up',
    'morning': 'wake_up',
    'sunrise': 'wake_up',
    'breakfast': 'breakfast',
    'lunch': 'lunch',
    'dinner': 'dinner',
    'eat': 'dinner',
    'meal': 'lunch',
    'tea': 'evening_tea',
    'chai': 'evening_tea',
    'sleep': 'sleep',
    'bed': 'sleep',
    'medicine': 'tile_medicine',
    'tablet': 'tile_medicine',
    'pill': 'tile_medicine',
    'music': 'tile_music',
  };

  static const _iconByWord = <String, IconData>{
    'walk': Icons.directions_walk_rounded,
    'exercise': Icons.self_improvement_rounded,
    'pray': Icons.self_improvement_rounded,
    'bath': Icons.bathtub_rounded,
    'wash': Icons.bathtub_rounded,
    'tv': Icons.tv_rounded,
    'read': Icons.menu_book_rounded,
    'call': Icons.call_rounded,
    'rest': Icons.weekend_rounded,
    'nap': Icons.weekend_rounded,
  };

  String? _match(Map<String, String> table) {
    final text = '$emoji $label'.toLowerCase();
    for (final e in table.entries) {
      if (text.contains(e.key)) return e.value;
    }
    return null;
  }

  Widget _fallback() {
    final hasEmoji = emoji.runes.any((r) => r > 0x2000);
    if (hasEmoji) {
      return ColoredBox(
        color: AppColors.medallion,
        child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.5))),
      );
    }
    final text = '$emoji $label'.toLowerCase();
    IconData icon = Icons.event_available_rounded;
    for (final e in _iconByWord.entries) {
      if (text.contains(e.key)) {
        icon = e.value;
        break;
      }
    }
    return ColoredBox(
      color: AppColors.medallion,
      child: Icon(icon, size: size * 0.52, color: AppColors.terracottaDark),
    );
  }

  Widget _photo(String name, Widget Function() onError) {
    return Image.asset(
      'assets/images/photos/$name.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * 3).round(),
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => onError(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final byWord = _match(_photoByWord);
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _photo(
          id,
          () => byWord == null ? _fallback() : _photo(byWord, _fallback),
        ),
      ),
    );
  }
}
