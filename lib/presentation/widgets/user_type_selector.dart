import 'package:flutter/material.dart';
import '../../core/services/translation_service.dart';

class UserTypeSelector extends StatefulWidget {
  final Function(String) onChanged;
  final String? initialValue;
  final String label;
  final bool isRequired;
  final bool isDisabled;

  const UserTypeSelector({
    super.key,
    required this.onChanged,
    this.initialValue,
    required this.label,
    this.isRequired = false,
    this.isDisabled = false,
  });

  @override
  State<UserTypeSelector> createState() => _UserTypeSelectorState();
}

class _UserTypeSelectorState extends State<UserTypeSelector> {
  late String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 4),
            if (widget.isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 16),
            _buildTypeOption(
              'stadium',
              Icons.stadium_outlined,
              translationService.tr('auth.user_type.stadium', {}, context),
            ),
            const SizedBox(width: 8),
            _buildTypeOption(
              'owner',
              Icons.business_center_outlined,
              translationService.tr('auth.user_type.owner', {}, context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);

    return Expanded(
      child: Opacity(
        opacity: widget.isDisabled ? 0.6 : 1.0,
        child: InkWell(
          onTap: widget.isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedType = type;
                  });
                  widget.onChanged(type);
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (widget.isDisabled && isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      translationService.tr(
                          'auth.account_type_locked', {}, context),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
