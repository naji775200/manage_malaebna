import 'package:flutter/material.dart';

/// Helper class to guide developers on migrating from context.tr to the translationService
class MigrationHelper {
  /// Prints a friendly warning when context.tr is used
  static void warnContextUsage(String key, BuildContext context) {
    debugPrint(
      '⚠️ DEPRECATED: context.tr("$key") is deprecated. '
      'Replace with translationService.tr("$key", {}, context)',
    );
  }

  /// Prints suggestions for updating a file
  static void suggestFileUpdate(String filePath) {
    debugPrint('''
    🔄 Migration needed: $filePath
    Consider running this search and replace:
    
    Search:  context.tr('
    Replace: translationService.tr('
    
    Then add:
    1. Import: import '../../../core/services/translation_service.dart';
    2. Add empty map {} and context parameter to each call
    ''');
  }

  /// Guidance for updating SnackBars
  static void suggestSnackBarUpdate() {
    debugPrint('''
    🔄 Migration needed: Replace ScaffoldMessenger.of(context).showSnackBar with CustomSnackBar
    
    Instead of:
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    
    Use:
    CustomSnackBar.showInfo(context, message);
    
    Or for errors:
    CustomSnackBar.showError(context, message);
    
    Don't forget to import:
    import '../../../core/widgets/custom_snackbar.dart';
    ''');
  }
}
