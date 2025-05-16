import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../../data/models/coupon_model.dart';
import '../../../logic/coupons/coupons_bloc.dart';
import '../../../logic/coupons/coupons_event.dart';
import '../../../logic/coupons/coupons_state.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/utils/auth_utils.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_snackbar.dart';

class AddEditCouponScreen extends StatefulWidget {
  final String stadiumId;
  final bool isEditing;
  final Coupon? coupon;

  const AddEditCouponScreen({
    super.key,
    required this.stadiumId,
    required this.isEditing,
    this.coupon,
  });

  @override
  State<AddEditCouponScreen> createState() => _AddEditCouponScreenState();
}

class _AddEditCouponScreenState extends State<AddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _discountController;

  DateTime _expirationDate = DateTime.now().add(const Duration(days: 30));
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  String _status = 'active';

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

    if (widget.isEditing && widget.coupon != null) {
      _nameController = TextEditingController(text: widget.coupon!.name);
      _codeController = TextEditingController(text: widget.coupon!.code);
      _discountController = TextEditingController(
          text: widget.coupon!.discountPercentage.toString());
      _expirationDate = widget.coupon!.expirationDate;
      _startTime = widget.coupon!.startTime;
      _endTime = widget.coupon!.endTime;
      _status = widget.coupon!.status;

      // Set selected days
      for (var day in widget.coupon!.daysOfWeek) {
        if (_daysOfWeek.containsKey(day.toLowerCase())) {
          _daysOfWeek[day.toLowerCase()] = true;
        }
      }
    } else {
      _nameController = TextEditingController();
      _codeController = TextEditingController();
      _discountController = TextEditingController();

      // Generate a random code if not editing
      _codeController.text = _generateCouponCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  String _generateCouponCode() {
    // Generate a random 8-character code
    final uuid = const Uuid().v4();
    return uuid.substring(0, 8).toUpperCase();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (pickedDate != null && pickedDate != _expirationDate) {
      setState(() {
        _expirationDate = pickedDate;
      });
    }
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

  void _saveCoupon() async {
    if (_formKey.currentState!.validate()) {
      if (_getSelectedDays().isEmpty) {
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.coupons.please_select_at_least_one_day',
              {},
              context),
        );
        return;
      }

      final discountPercentage = int.tryParse(_discountController.text);
      if (discountPercentage == null ||
          discountPercentage <= 0 ||
          discountPercentage > 100) {
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.coupons.invalid_discount_percentage',
              {},
              context),
        );
        return;
      }

      // Show loading indicator
      final loadingDialog = _showLoadingDialog(context);

      try {
        final couponId =
            widget.isEditing ? widget.coupon!.id : const Uuid().v4();

        // Try to get stadium ID from authentication first
        String validStadiumId = widget.stadiumId;
        final authStadiumId = await AuthUtils.getStadiumIdFromAuth();

        if (authStadiumId != null && authStadiumId.isNotEmpty) {
          print(
              '🔑 AddEditCouponScreen: Using stadium ID from auth: $authStadiumId');
          validStadiumId = authStadiumId;
        } else {
          print(
              '🔑 AddEditCouponScreen: Auth failed, using passed stadium ID: ${widget.stadiumId}');
        }

        final coupon = Coupon(
          id: couponId,
          stadiumId: validStadiumId,
          name: _nameController.text,
          code: _codeController.text.toUpperCase(),
          discountPercentage: discountPercentage,
          expirationDate: _expirationDate,
          status: _status,
          startTime: _startTime,
          endTime: _endTime,
          daysOfWeek: _getSelectedDays(),
        );

        // Hide loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (widget.isEditing) {
          context.read<CouponsBloc>().add(CouponsUpdateEvent(coupon: coupon));
        } else {
          context.read<CouponsBloc>().add(CouponsCreateEvent(coupon: coupon));
        }
      } catch (e) {
        // Hide loading dialog on error
        Navigator.of(context, rootNavigator: true).pop();

        print('❌ AddEditCouponScreen ERROR: Failed to save coupon: $e');
        CustomSnackBar.showError(
          context,
          translationService.tr(
              'prices_coupons.coupons.error_saving_coupon', {}, context),
        );
      }
    }
  }

  // Show a loading dialog while fetching the stadium ID
  Widget _showLoadingDialog(BuildContext context) {
    final AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(translationService.tr(
              'prices_coupons.common.saving', {}, context)),
        ],
      ),
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

    return alert;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? translationService.tr(
                  'prices_coupons.coupons.edit_coupon', {}, context)
              : translationService.tr(
                  'prices_coupons.coupons.add_coupon', {}, context),
        ),
      ),
      body: BlocListener<CouponsBloc, CouponsState>(
        listener: (context, state) {
          if (state is CouponCreated || state is CouponUpdated) {
            CustomSnackBar.showSuccess(
              context,
              widget.isEditing
                  ? translationService.tr(
                      'prices_coupons.coupons.coupon_updated_successfully',
                      {},
                      context)
                  : translationService.tr(
                      'prices_coupons.coupons.coupon_created_successfully',
                      {},
                      context),
            );
            Navigator.pop(context);
          } else if (state is CouponsError) {
            CustomSnackBar.showError(context, state.message);
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Coupon name
              CustomTextField(
                controller: _nameController,
                label: translationService.tr(
                    'prices_coupons.coupons.coupon_name', {}, context),
                hint: translationService.tr(
                    'prices_coupons.coupons.weekend_special', {}, context),
                prefixIcon: Icons.card_giftcard,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                        'prices_coupons.coupons.name_required', {}, context);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Coupon code
              CustomTextField(
                controller: _codeController,
                label: translationService.tr(
                    'prices_coupons.coupons.coupon_code', {}, context),
                hint: 'SUMMER2023',
                prefixIcon: Icons.code,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                        'prices_coupons.coupons.code_required', {}, context);
                  }
                  if (value.length < 3 || value.length > 20) {
                    return translationService.tr(
                        'prices_coupons.coupons.code_length_error',
                        {},
                        context);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Discount percentage
              CustomTextField(
                controller: _discountController,
                label: translationService.tr(
                    'prices_coupons.coupons.discount_percentage', {}, context),
                hint: '10',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.percent,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return translationService.tr(
                        'prices_coupons.coupons.discount_required',
                        {},
                        context);
                  }
                  final discount = int.tryParse(value);
                  if (discount == null || discount <= 0 || discount > 100) {
                    return translationService.tr(
                        'prices_coupons.coupons.discount_range_error',
                        {},
                        context);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Expiration date
              Text(
                translationService.tr(
                    'prices_coupons.coupons.expiration_date', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: Text(dateFormat.format(_expirationDate)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status
              Text(
                translationService.tr(
                    'prices_coupons.coupons.status', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                value: _status,
                items: [
                  DropdownMenuItem(
                    value: 'active',
                    child: Text(translationService.tr(
                        'prices_coupons.coupons.active', {}, context)),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text(translationService.tr(
                        'prices_coupons.coupons.inactive', {}, context)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Time selection
              Text(
                translationService.tr(
                    'prices_coupons.coupons.time_range', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

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

              const SizedBox(height: 16),

              // Days of week
              Text(
                translationService.tr(
                    'prices_coupons.coupons.select_days', {}, context),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

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
                onPressed: _saveCoupon,
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
