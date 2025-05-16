import 'package:flutter/foundation.dart';

class ErrorHandler {
  static String handleError(dynamic error,
      {String defaultMessage = 'An unknown error occurred'}) {
    try {
      if (error == null) {
        return defaultMessage;
      }

      // Log the error for debugging
      debugPrint('Error occurred: $error');

      // Check if it's an exception with a message
      if (error is Exception || error is Error) {
        final errorMessage = error.toString();
        if (errorMessage.isNotEmpty) {
          return errorMessage;
        }
      }

      // If it's a String, return it directly
      if (error is String && error.isNotEmpty) {
        return error;
      }

      // Handle specific error types
      if (error.toString().contains('network')) {
        return 'Network error. Please check your internet connection.';
      }

      if (error.toString().contains('permission')) {
        return 'Permission denied. Please check your permissions.';
      }

      if (error.toString().contains('not found')) {
        return 'The requested resource was not found.';
      }

      if (error.toString().contains('authentication')) {
        return 'Authentication error. Please login again.';
      }

      // Default case
      return defaultMessage;
    } catch (e) {
      // If anything goes wrong during error handling, return the default message
      debugPrint('Error in error handler: $e');
      return defaultMessage;
    }
  }

  static void logError(dynamic error,
      {StackTrace? stackTrace, String? message}) {
    if (kDebugMode) {
      print('ERROR${message != null ? ' - $message' : ''}: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }
}
