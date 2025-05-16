import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/price_model.dart';
import '../../../logic/prices/prices_bloc.dart';
import '../../../logic/prices/prices_event.dart';
import '../../../logic/prices/prices_state.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_snackbar.dart';

class AddEditPriceScreen extends StatefulWidget {
  final String fieldId;
  final bool isEditing;
  final Price? price;

  const AddEditPriceScreen({
    super.key,
    required this.fieldId,
    required this.isEditing,
    this.price,
  });

  @override
  State<AddEditPriceScreen> createState() => _AddEditPriceScreenState();
}

class _AddEditPriceScreenState extends State<AddEditPriceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _priceController;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  final Map<String, bool> _daysOfWeek = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': false,
  };

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.price != null) {
      _priceController =
          TextEditingController(text: widget.price!.pricePerHour.toString());
      _startTime = widget.price!.startTime;
      _endTime = widget.price!.endTime;

      // Set selected days
      for (var day in widget.price!.daysOfWeek) {
        if (_daysOfWeek.containsKey(day.toLowerCase())) {
          _daysOfWeek[day.toLowerCase()] = true;
        }
      }
    } else {
      _priceController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;

          // If end time is before start time, adjust end time
          if (_timeToDouble(_endTime) <= _timeToDouble(_startTime)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = pickedTime;

          // If end time is before start time, adjust start time
          if (_timeToDouble(_endTime) <= _timeToDouble(_startTime)) {
            _startTime = TimeOfDay(
              hour: (_endTime.hour - 1) % 24,
              minute: _endTime.minute,
            );
          }
        }
      });
    }
  }

  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }

  void _toggleDay(String day) {
    setState(() {
      _daysOfWeek[day] = !_daysOfWeek[day]!;
    });
  }

  List<String> _getSelectedDays() {
    return _daysOfWeek.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void _savePrice() {
    if (_formKey.currentState!.validate()) {
      if (_getSelectedDays().isEmpty) {
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.prices.please_select_at_least_one_day',
              {},
              context),
        );
        return;
      }

      final pricePerHour = double.tryParse(_priceController.text);
      if (pricePerHour == null || pricePerHour <= 0) {
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.prices.invalid_price', {}, context),
        );
        return;
      }

      try {
        final priceId = widget.isEditing ? widget.price!.id : const Uuid().v4();

        // Just use the fieldId passed to the widget - it should be valid by now
        // If it's 'default', create a UUID for consistency
        String validFieldId = widget.fieldId;
        if (validFieldId == 'default') {
          // For default values, create a consistent UUID
          const uuid = Uuid();
          const namespace = Uuid.NAMESPACE_URL;
          validFieldId = uuid.v5(namespace, 'default_field');
          print(
              'ℹ️ AddEditPriceScreen: Converting "default" field ID to UUID: $validFieldId');
        }

        final price = Price(
          id: priceId,
          fieldId: validFieldId,
          startTime: _startTime,
          endTime: _endTime,
          pricePerHour: pricePerHour,
          daysOfWeek: _getSelectedDays(),
        );

        if (widget.isEditing) {
          context.read<PricesBloc>().add(PricesUpdateEvent(price: price));
        } else {
          context.read<PricesBloc>().add(PricesCreateEvent(price: price));
        }
      } catch (e) {
        print('❌ AddEditPriceScreen ERROR: Failed to save price: $e');
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.prices.error_saving_price', {}, context),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? translationService.tr(
                  'prices_coupons.prices.edit_price', {}, context)
              : translationService.tr(
                  'prices_coupons.prices.add_price', {}, context),
        ),
      ),
      body: BlocListener<PricesBloc, PricesState>(
        listener: (context, state) {
          if (state is PriceCreated || state is PriceUpdated) {
            CustomSnackBar.showSuccess(
              context,
              widget.isEditing
                  ? translationService.tr(
                      'prices_coupons.prices.price_updated_successfully',
                      {},
                      context)
                  : translationService.tr(
                      'prices_coupons.prices.price_created_successfully',
                      {},
                      context),
            );
            Navigator.pop(context);
          } else if (state is PricesError) {
            CustomSnackBar.showError(context, state.message);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Price per hour
              CustomTextField(
                controller: _priceController,
                label: translationService.tr(
                    'prices_coupons.prices.price_per_hour', {}, context),
                hint: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.monetization_on,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                        'prices_coupons.prices.price_required', {}, context);
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return translationService.tr(
                        'prices_coupons.prices.price_must_be_positive',
                        {},
                        context);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Time selection
              Text(
                translationService.tr(
                    'prices_coupons.prices.time_range', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, true),
                      icon: const Icon(Icons.access_time),
                      label: Text(_startTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(translationService.tr(
                        'prices_coupons.common.to', {}, context)),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(context, false),
                      icon: const Icon(Icons.access_time),
                      label: Text(_endTime.format(context)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Days of week
              Text(
                translationService.tr(
                    'prices_coupons.prices.select_days', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _daysOfWeek.entries.map((entry) {
                  final bool isSelected = entry.value;
                  return FilterChip(
                    label: Text(translationService.tr(
                        'working_hours.days.${entry.key}', {}, context)),
                    selected: isSelected,
                    onSelected: (_) => _toggleDay(entry.key),
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Save button
              CustomButton(
                text: translationService.tr(
                    'prices_coupons.common.save', {}, context),
                onPressed: _savePrice,
                isFullWidth: true,
                size: CustomButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
