import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/translation_service.dart';
import '../../../data/models/payment_model.dart';

class PaymentForm extends StatefulWidget {
  final Function(Payment) onSubmit;
  final bool isSavingCard;
  final Function(bool) onSaveCardToggled;
  final double amount;
  final String currency;

  const PaymentForm({
    super.key,
    required this.onSubmit,
    required this.isSavingCard,
    required this.onSaveCardToggled,
    required this.amount,
    this.currency = 'USD',
  });

  @override
  _PaymentFormState createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _saveCard = false;
  bool _processing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a Payment object that matches our model
      final payment = Payment(
        id: const Uuid().v4(), // Generate a UUID for the payment
        amount: widget.amount,
        currency: widget.currency,
        paymentMethod: 'Credit Card',
        status: 'pending',
        paymentStatus: 'pending',
      );

      widget.onSubmit(payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Number Field
          _buildCardNumberField(),
          const SizedBox(height: 16),

          // Card Holder Field
          _buildCardHolderField(),
          const SizedBox(height: 16),

          // Expiry Date and CVV (in a row)
          Row(
            children: [
              // Expiry Date Field
              Expanded(child: _buildExpiryDateField()),
              const SizedBox(width: 16),

              // CVV Field
              Expanded(child: _buildCvvField()),
            ],
          ),

          const SizedBox(height: 24),

          // Save card checkbox
          _buildSaveCardCheckbox(),

          const SizedBox(height: 24),

          // Submit Button
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildCardNumberField() {
    return TextFormField(
      controller: _cardNumberController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _cardNumberFormatter,
      ],
      decoration: InputDecoration(
        labelText: translationService.tr('payment.card_number', {}, context),
        prefixIcon: const Icon(Icons.credit_card),
        suffixIcon: _cardBrandIcon(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return translationService.tr(
              'payment.validation.card_number_required', {}, context);
        }
        if (!_isValidCardNumber(value)) {
          return translationService.tr(
              'payment.validation.card_number_invalid', {}, context);
        }
        return null;
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildCardHolderField() {
    return TextFormField(
      controller: _cardHolderController,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: translationService.tr('payment.card_holder', {}, context),
        prefixIcon: const Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return translationService.tr(
              'payment.validation.card_holder_required', {}, context);
        }
        return null;
      },
    );
  }

  Widget _buildExpiryDateField() {
    return TextFormField(
      controller: _expiryDateController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _expiryDateFormatter,
      ],
      decoration: InputDecoration(
        labelText: translationService.tr('payment.expiry_date', {}, context),
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return translationService.tr(
              'payment.validation.expiry_date_required', {}, context);
        }
        if (value.length < 5) {
          return translationService.tr(
              'payment.validation.expiry_date_invalid', {}, context);
        }
        // Parse MM/YY
        final parts = value.split('/');
        if (parts.length != 2) {
          return translationService.tr(
              'payment.validation.expiry_date_invalid', {}, context);
        }

        try {
          final month = int.parse(parts[0]);
          final year = int.parse(parts[1]) + 2000; // Convert YY to 20YY

          final now = DateTime.now();
          final expiryDate = DateTime(year, month + 1, 0); // Last day of month

          if (month < 1 || month > 12) {
            return translationService.tr(
                'payment.validation.expiry_date_invalid', {}, context);
          }

          if (expiryDate.isBefore(now)) {
            return translationService.tr(
                'payment.validation.expiry_date_invalid', {}, context);
          }
        } catch (e) {
          return translationService.tr(
              'payment.validation.expiry_date_invalid', {}, context);
        }

        return null;
      },
    );
  }

  Widget _buildCvvField() {
    return TextFormField(
      controller: _cvvController,
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: translationService.tr('payment.cvv', {}, context),
        prefixIcon: const Icon(Icons.lock),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return translationService.tr(
              'payment.validation.cvv_required', {}, context);
        }
        if (value.length < 3) {
          return translationService.tr(
              'payment.validation.cvv_invalid', {}, context);
        }
        return null;
      },
    );
  }

  Widget _buildSaveCardCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _saveCard,
          onChanged: (value) {
            setState(() {
              _saveCard = value ?? false;
            });
          },
        ),
        Expanded(
          child: Text(translationService.tr('payment.save_card', {}, context)),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return ElevatedButton(
      onPressed: _processing ? null : _submitPayment,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _processing
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(translationService.tr('payment.pay_now', {}, context)),
    );
  }

  // Custom formatters for card input
  final _cardNumberFormatter = LengthLimitingTextInputFormatter(16);
  final _expiryDateFormatter = LengthLimitingTextInputFormatter(4);

  bool _isValidCardNumber(String value) {
    return value.replaceAll(' ', '').length == 16;
  }

  void _submitPayment() {
    setState(() {
      _processing = true;
    });
    _submitForm();
  }

  Widget _cardBrandIcon() {
    // Implementation of _cardBrandIcon method
    return Container(); // Placeholder, actual implementation needed
  }
}
