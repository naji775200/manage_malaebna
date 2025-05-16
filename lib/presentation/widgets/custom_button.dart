import 'package:flutter/material.dart';

enum CustomButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

enum CustomButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonVariant variant;
  final CustomButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isFullWidth;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CustomButtonVariant.primary,
    this.size = CustomButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.width,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;

    // Get button padding based on size
    final buttonPadding = padding ?? _getButtonPadding();

    // Get button text style based on size
    final textStyle = _getTextStyle(theme);

    // Get button colors based on variant and disabled state
    final ButtonStyle buttonStyle = _getButtonStyle(theme, isDisabled);

    // Build button content with icons and text
    Widget buttonContent = _buildButtonContent(theme, textStyle);

    // Show loading indicator if button is in loading state
    if (isLoading) {
      buttonContent = _buildLoadingState(theme);
    }

    return SizedBox(
      width: _getButtonWidth(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle.copyWith(
          padding: WidgetStateProperty.all(buttonPadding),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          ),
        ),
        child: buttonContent,
      ),
    );
  }

  double? _getButtonWidth() {
    if (width != null) return width;
    if (isFullWidth) return double.infinity;
    return null;
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (size) {
      case CustomButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case CustomButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
      case CustomButtonSize.medium:
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = theme.textTheme.labelLarge ?? const TextStyle();
    switch (size) {
      case CustomButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case CustomButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
      case CustomButtonSize.medium:
      default:
        return baseStyle.copyWith(fontSize: 14);
    }
  }

  ButtonStyle _getButtonStyle(ThemeData theme, bool isDisabled) {
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final secondaryColor = theme.colorScheme.secondary;
    final onSecondaryColor = theme.colorScheme.onSecondary;
    final disabledColor = theme.disabledColor;
    final disabledBackgroundColor = theme.disabledColor.withOpacity(0.12);

    switch (variant) {
      case CustomButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor:
              isDisabled ? disabledBackgroundColor : secondaryColor,
          foregroundColor: isDisabled ? disabledColor : onSecondaryColor,
          elevation: 0,
        );
      case CustomButtonVariant.outlined:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isDisabled ? disabledColor : primaryColor,
          elevation: 0,
          side: BorderSide(
            color: isDisabled ? disabledColor : primaryColor,
            width: 1,
          ),
        );
      case CustomButtonVariant.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: isDisabled ? disabledColor : primaryColor,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      case CustomButtonVariant.primary:
      default:
        return ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? disabledBackgroundColor : primaryColor,
          foregroundColor: isDisabled ? disabledColor : onPrimaryColor,
          elevation: 0,
        );
    }
  }

  Widget _buildButtonContent(ThemeData theme, TextStyle textStyle) {
    if (leadingIcon != null && trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: textStyle.fontSize! * 1.2),
          SizedBox(width: textStyle.fontSize! * 0.5),
          Text(text, style: textStyle),
          SizedBox(width: textStyle.fontSize! * 0.5),
          Icon(trailingIcon, size: textStyle.fontSize! * 1.2),
        ],
      );
    } else if (leadingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: textStyle.fontSize! * 1.2),
          SizedBox(width: textStyle.fontSize! * 0.5),
          Text(text, style: textStyle),
        ],
      );
    } else if (trailingIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: textStyle),
          SizedBox(width: textStyle.fontSize! * 0.5),
          Icon(trailingIcon, size: textStyle.fontSize! * 1.2),
        ],
      );
    } else {
      return Text(text, style: textStyle);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    final color = variant == CustomButtonVariant.outlined ||
            variant == CustomButtonVariant.text
        ? theme.colorScheme.primary
        : theme.colorScheme.onPrimary;

    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
