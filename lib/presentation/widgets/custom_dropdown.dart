import 'package:flutter/material.dart';
import '../../core/services/translation_service.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final bool isRequired;

  const CustomDropdown({
    super.key,
    required this.labelText,
    this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.borderRadius = 16.0,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: contentPadding,
        errorMaxLines: 2,
      ),
      icon: const Icon(Icons.arrow_drop_down),
      dropdownColor: Theme.of(context).colorScheme.surface,
    );
  }

  static CustomDropdown<String> forFields({
    required BuildContext context,
    required String labelText,
    required String value,
    required List<Map<String, dynamic>> fields,
    required Function(String?) onChanged,
    bool isRequired = false,
  }) {
    return CustomDropdown<String>(
      labelText: labelText,
      value: value,
      items: fields.map((field) {
        return DropdownMenuItem<String>(
          value: field['id'],
          child: Text(field['name']),
        );
      }).toList(),
      onChanged: onChanged,
      isRequired: isRequired,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return translationService.tr(
                    'common.field_required', {}, context);
              }
              return null;
            }
          : null,
    );
  }
}
