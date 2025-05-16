import 'package:flutter/material.dart';

class CountryCode {
  final String code;
  final String countryName;
  final String flagEmoji;

  const CountryCode({
    required this.code,
    required this.countryName,
    required this.flagEmoji,
  });
}

class CountryCodeSelector extends StatelessWidget {
  final CountryCode selectedCountry;
  final Function(CountryCode) onCountrySelected;
  final List<CountryCode> countries;

  const CountryCodeSelector({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
    this.countries = const [
      CountryCode(code: '+966', countryName: 'Saudi Arabia', flagEmoji: '🇸🇦'),
      CountryCode(code: '+967', countryName: 'Yemen', flagEmoji: '🇾🇪'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: InkWell(
        onTap: () => _showCountryPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${selectedCountry.flagEmoji} ${selectedCountry.code}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 24.0, right: 24.0, bottom: 16.0),
                child: Text(
                  'Select Country Code',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ...countries.map((country) => ListTile(
                    leading: Text(
                      country.flagEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(country.countryName),
                    trailing: Text(
                      country.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    selected: country.code == selectedCountry.code,
                    selectedTileColor:
                        theme.colorScheme.primary.withOpacity(0.1),
                    onTap: () {
                      onCountrySelected(country);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
