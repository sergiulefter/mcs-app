import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// A reusable selectable card widget for language selection.
///
/// Shows language name with optional flag emoji and a checkmark when selected.
/// Features visual feedback for selection state with border and background color.
///
/// Example:
/// ```dart
/// LanguageSelectionCard(
///   languageName: 'English',
///   languageCode: 'en',
///   flagEmoji: '🇬🇧',
///   isSelected: currentLocale == 'en',
///   onTap: () {
///     context.setLocale(Locale('en'));
///   },
/// )
/// ```
class LanguageSelectionCard extends StatelessWidget {
  /// The display name of the language.
  final String languageName;

  /// The language code (e.g., 'en', 'ro').
  final String languageCode;

  /// Optional: Flag emoji to display.
  final String? flagEmoji;

  /// Whether this language is currently selected.
  final bool isSelected;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Optional: Custom selected color (defaults to primaryBlue).
  final Color? selectedColor;

  /// Optional: Whether to show the checkmark icon (defaults to true).
  final bool showCheckmark;

  const LanguageSelectionCard({
    super.key,
    required this.languageName,
    required this.languageCode,
    this.flagEmoji,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
    this.showCheckmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? AppTheme.primaryBlue;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveSelectedColor.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected ? effectiveSelectedColor : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          children: [
            // Flag Emoji (if provided)
            if (flagEmoji != null) ...[
              Text(
                flagEmoji!,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppTheme.spacing12),
            ],
            // Language Name
            Expanded(
              child: Text(
                languageName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ),
            // Checkmark (if selected)
            if (isSelected && showCheckmark)
              Icon(
                Icons.check_circle,
                color: effectiveSelectedColor,
                size: AppTheme.iconMedium,
              ),
          ],
        ),
      ),
    );
  }
}
