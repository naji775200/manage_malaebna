import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/theme/theme_bloc.dart';

class ThemeSwitcher extends StatelessWidget {
  final Color? color;

  const ThemeSwitcher({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when theme changes
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Safely determine if dark mode is enabled, defaulting to system preference if themeMode is null
        final ThemeMode currentThemeMode = themeState.themeMode ?? ThemeMode.system;
        final bool isDark = currentThemeMode == ThemeMode.dark ||
            (currentThemeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final theme = Theme.of(context);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            try {
              // Toggle between dark and light themes
              final newThemeMode = isDark ? ThemeMode.light : ThemeMode.dark;
              // Safely access BlocProvider
              final themeBloc = BlocProvider.of<ThemeBloc>(context, listen: false);
              themeBloc.add(ThemeChangedEvent(newThemeMode));
            } catch (e) {
              // Log the error but don't crash
              print('Error toggling theme: $e');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                key: ValueKey<bool>(isDark),
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                color: color ?? theme.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}
