import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_controller.dart';
import '../ui/smriti_ui.dart';

/// A calm, dementia-friendly language switcher button for the elder.
///
/// Displays current language in native script (e.g. [ 🌐 অসমীয়া ▾ ]).
/// Tapping opens a peaceful bottom sheet with large, clear cards in native scripts.
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key, this.controller, this.compact = false});

  final LocaleController? controller;

  /// Icon-only round button, for tight headers.
  final bool compact;

  LocaleController get _controller => controller ?? LocaleController.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final meta = _controller.currentMeta;
        if (compact) {
          return IconButton(
            tooltip: meta.nativeName,
            onPressed: () => showLanguagePicker(context, controller: _controller),
            iconSize: 28,
            icon: const Icon(Icons.language_rounded, color: AppColors.leafGreen),
          );
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => showLanguagePicker(context, controller: _controller),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.raisedSurface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
                
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    size: 20,
                    color: AppColors.leafGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    meta.nativeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 22,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Displays an elder-friendly modal sheet to choose from the 8 supported NER languages.
Future<void> showLanguagePicker(
  BuildContext context, {
  LocaleController? controller,
}) async {
  final ctrl = controller ?? LocaleController.instance;
  final current = ctrl.currentLanguage;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.pageBackground,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) {
      final isCompact = MediaQuery.of(ctx).size.height < 600;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Row(
                  children: [
                    const IconMedallion(
                      icon: Icons.translate_rounded,
                      color: AppColors.leafGreen,
                      size: 44,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.chooseLanguage(current),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'North-East India Languages',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isCompact ? 10 : 16,
                  ),
                  shrinkWrap: true,
                  itemCount: kSupportedLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final meta = kSupportedLanguages[index];
                    final isSelected = meta.code == current;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ctrl.setLanguage(meta.code);
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color.lerp(AppColors.leafGreen, Colors.white, 0.85)
                                : AppColors.raisedSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.leafGreen
                                  : AppColors.border,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meta.nativeName,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w700,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${meta.englishName} • ${meta.region}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected
                                            ? AppColors.leafGreen
                                            : AppColors.secondaryText,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.leafGreen,
                                  size: 28,
                                )
                              else
                                Icon(
                                  Icons.circle_outlined,
                                  color: AppColors.border,
                                  size: 26,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
