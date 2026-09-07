import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../cognitive_game.dart';
import 'faces_game.dart';

/// Playable Faces of My Family widget.
///
/// Shows a person's photo (or avatar) and asks the elder to identify them.
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
  DateTime? _shownAt;
  DateTime? _firstTapAt;
  bool _answered = false;

  late final PersonItem _target;
  late final List<PersonItem> _options;
  late final String _mode;

  @override
  void initState() {
    super.initState();
    _shownAt = DateTime.now();
    _target = widget.item.payload['target'] as PersonItem;
    _options =
        (widget.item.payload['options'] as List<Object?>).cast<PersonItem>();
    _mode = widget.item.payload['mode'] as String;
  }

  void _onOptionTap(PersonItem chosen) {
    if (_answered) return;
    _firstTapAt ??= DateTime.now();
    setState(() => _answered = true);

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

    Future.delayed(const Duration(milliseconds: 600), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question prompt
          Text(
            _promptForMode(_mode),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Person avatar/photo
          _buildAvatar(),
          const SizedBox(height: 30),

          // Answer options
          if (!_answered)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _options.map(_buildOption).toList(),
            )
          else
            const Icon(
              Icons.check_circle,
              size: 60,
              color: AppColors.leafGreen,
            ),
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

  Widget _buildAvatar() {
    // Use first letter of name as avatar since we have no real photos
    final initial = _target.name.isNotEmpty ? _target.name[0] : '?';
    final colors = [
      AppColors.terracotta,
      AppColors.indigo,
      AppColors.leafGreen,
      AppColors.marigold,
    ];
    final color = colors[_target.name.hashCode % colors.length];

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            color: AppColors.onColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOption(PersonItem person) {
    return GestureDetector(
      onTap: () => _onOptionTap(person),
      child: Container(
        constraints: const BoxConstraints(minWidth: 140, minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.raisedSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _mode == 'relationship' ? person.relationship : person.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (_mode == 'relationship')
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
