import 'package:flutter/material.dart';

enum SnackBarType {
  success,
  error,
  info,
  warning,
}

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);

    // Get a global reference to the ScaffoldMessenger
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Determine colors based on type
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade800;
        textColor = Colors.white;
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = Colors.red.shade800;
        textColor = Colors.white;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = Colors.amber.shade800;
        textColor = Colors.black;
        icon = Icons.warning_amber_outlined;
        break;
      case SnackBarType.info:
      default:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        icon = Icons.info_outline;
        break;
    }

    // Create SnackBar action if provided
    SnackBarAction? action;
    if (onAction != null && actionLabel != null) {
      action = SnackBarAction(
        label: actionLabel,
        textColor: textColor.withOpacity(0.9),
        onPressed: () {
          // Safe dismissal
          scaffoldMessenger.hideCurrentSnackBar();
          onAction();
        },
      );
    }

    // Show the SnackBar
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: action,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(12),
      dismissDirection: DismissDirection.horizontal,
    );

    // Hide any existing SnackBar
    scaffoldMessenger.hideCurrentSnackBar();

    // Show new SnackBar
    scaffoldMessenger.showSnackBar(snackBar);
  }

  // Convenience methods
  static void showSuccess(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.info);
  }

  static void showWarning(BuildContext context, String message) {
    show(context: context, message: message, type: SnackBarType.warning);
  }
}
