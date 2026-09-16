import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../core/files/local_media.dart';
import '../../ui/smriti_ui.dart';
import '../cognitive_game.dart';
import 'faces_game.dart';

/// Playable Faces of My Family widget.
///
/// Shows a family member's photo (from the caregiver's web app) and asks the
/// elder to identify them. Falls back to a coloured initial when no photo has
/// been downloaded yet.
/// Progressive modes: recognition (pick from options) → free naming → relationship.
class FacesWidget extends StatefulWidget {
  const FacesWidget({
    super.key,
    required this.game,
    required this.item,
    required this.onComplete,
  });

  final FacesGame game;
  final GameItem item;
  final VoidCallback onComplete;

  @override
  State<FacesWidget> createState() => _FacesWidgetState();
}

class _FacesWidgetState extends State<FacesWidget> {
  static const _optionColors = [
    AppColors.indigo,
    AppColors.riverTeal,
    AppColors.orchid,
    AppColors.bamboo,
  ];

  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _answered = false;
  String? _chosenId;

  late final PersonItem _target;
  late final List<PersonItem> _options;
  late final String _mode;
  late final Future<File?> _photo;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _target = widget.item.payload['target'] as PersonItem;
    _options =
        (widget.item.payload['options'] as List<Object?>).cast<PersonItem>();
    _mode = widget.item.payload['mode'] as String;
    _photo = _findPhoto();
  }

  Future<File?> _findPhoto() async {
    try {
      return await resolvePersonPhoto(_target.photoPath, _target.id);
    } catch (_) {
      return null;
    }
  }

  void _onOptionTap(PersonItem chosen) {
    if (_answered) return;
    _firstTapAt ??= DateTime.now();
    setState(() {
      _answered = true;
      _chosenId = chosen.id;
    });

    final now = DateTime.now();
    final initiationMs =
        _firstTapAt!.difference(_shownAt!).inMilliseconds;
    final movementMs = now.difference(_firstTapAt!).inMilliseconds;

    widget.game.submit(
      item: widget.item,
      chosenId: chosen.id,
      initiationMs: initiationMs,
      movementMs: movementMs,
    );

    Future.delayed(const Duration(milliseconds: 900), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.height < 500;
    final wide = size.width > size.height && size.width >= 720;

    final prompt = Text(
      _promptForMode(_mode),
      style: TextStyle(
        fontSize: isCompact ? 20 : 26,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      textAlign: TextAlign.center,
    );

    final options = Wrap(
      spacing: 14,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < _options.length; i++)
          _buildOption(_options[i], _optionColors[i % _optionColors.length], isCompact),
      ],
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(child: Center(child: _buildPortrait(size.height * 0.55))),
            const SizedBox(width: 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [prompt, const SizedBox(height: 28), options],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: isCompact ? 8 : 22),
      child: Column(
        children: [
          prompt,
          SizedBox(height: isCompact ? 12 : 22),
          _buildPortrait(isCompact ? 120 : (size.width * 0.6).clamp(160.0, 260.0)),
          SizedBox(height: isCompact ? 14 : 26),
          options,
        ],
      ),
    );
  }

  String _promptForMode(String mode) {
    switch (mode) {
      case 'recognition_3':
      case 'recognition_2':
        return 'Who is this person?';
      case 'free_naming':
        return 'Can you name this person?';
      case 'relationship':
        return 'How is this person related to you?';
      case 'last_contact':
        return 'When did you last see this person?';
      default:
        return 'Who is this person?';
    }
  }

  Color get _personColor {
    const colors = [
      AppColors.terracotta,
      AppColors.indigo,
      AppColors.leafGreen,
      AppColors.marigoldDark,
    ];
    return colors[_target.name.hashCode.abs() % colors.length];
  }

  Widget _buildPortrait(double size) {
    final color = _personColor;
    final initial = _target.name.isNotEmpty ? _target.name[0].toUpperCase() : '?';

    return PopIn(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(size * 0.18),
          border: Border.all(color: AppColors.marigold, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.14),
          child: FutureBuilder<File?>(
            future: _photo,
            builder: (context, snapshot) {
              final file = snapshot.data;
              if (file != null) {
                return Image.file(file, fit: BoxFit.cover);
              }
              return Container(
                color: color.withValues(alpha: 0.15),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOption(PersonItem person, Color color, bool isCompact) {
    final chosen = _chosenId == person.id;
    final dimmed = _answered && !chosen;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.35 : 1,
      child: BouncyTap(
        onTap: _answered ? null : () => _onOptionTap(person),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minWidth: isCompact ? 130 : 160,
            minHeight: isCompact ? 56 : 72,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 18 : 26,
            vertical: isCompact ? 10 : 16,
          ),
          decoration: BoxDecoration(
            color: chosen ? color : Color.lerp(color, Colors.white, 0.84),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _mode == 'relationship' ? _capitalize(person.relationship) : person.name,
                style: TextStyle(
                  fontSize: isCompact ? 19 : 24,
                  fontWeight: FontWeight.w800,
                  color: chosen ? AppColors.onColor : AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              if (_mode == 'relationship')
                Text(
                  person.name,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    color: chosen ? AppColors.onColor : AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
