import 'package:flutter/material.dart';
import '../../../core/constants/theme.dart';

class CreditCardWidget extends StatelessWidget {
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;
  final String cardType;
  final bool isSelected;
  final VoidCallback? onTap;

  const CreditCardWidget({
    super.key,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cardType,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    AppTheme.primaryColor,
                    AppTheme.primaryLightColor,
                  ]
                : [
                    Colors.blueGrey.shade800,
                    Colors.blueGrey.shade900,
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(
                  color: Colors.white,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Card type logo
            Positioned(
              top: 16,
              right: 16,
              child: _buildCardTypeLogo(cardType),
            ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ),
              ),

            // Card details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Chip icon
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card number
                  Text(
                    cardNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card holder name and expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cardholderName.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expiryDate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTypeLogo(String cardType) {
    IconData iconData;
    Color color;

    switch (cardType.toLowerCase()) {
      case 'visa':
        iconData = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        iconData = Icons.credit_card;
        color = Colors.purple;
        break;
      default:
        iconData = Icons.credit_card;
        color = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }
}
