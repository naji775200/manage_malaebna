import 'package:flutter/services.dart';

// Custom formatter to add spaces in phone number for better readability
class PhoneNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final newText = StringBuffer();
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    for (int i = 0; i < digits.length; i++) {
      // Add a space after 3rd and 6th digits for better readability
      if (i == 3 || i == 6) {
        newText.write(' ');
      }
      newText.write(digits[i]);
    }

    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
