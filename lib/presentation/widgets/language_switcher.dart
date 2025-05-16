import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/localization_bloc.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool showText;
  final Color? color;

  const LanguageSwitcher({
    super.key,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isArabic = currentLocale == 'ar';
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        // Toggle language between English and Arabic
        final newLanguage = isArabic ? 'en' : 'ar';
        context.read<LocalizationBloc>().add(
              LocalizationChangedEvent(newLanguage),
            );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use language-specific text as the icon
            Text(
              isArabic ? 'ع' : 'En',
              style: TextStyle(
                color: color ?? theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 8),
              Text(
                isArabic ? 'English' : 'العربية',
                style: TextStyle(
                  color: color ?? theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
