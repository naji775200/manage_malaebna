import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/translation_service.dart';
import '../../../data/models/price_model.dart';
import '../../../data/repositories/field_repository.dart';
import '../../../logic/prices/prices_bloc.dart';
import '../../../logic/prices/prices_event.dart';
import '../../../logic/prices/prices_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_snackbar.dart';
import 'add_edit_price_screen.dart';

class PricesTab extends StatefulWidget {
  final String stadiumId;

  const PricesTab({
    super.key,
    required this.stadiumId,
  });

  @override
  State<PricesTab> createState() => _PricesTabState();
}

class _PricesTabState extends State<PricesTab> {
  late String selectedFieldId;
  List<Map<String, dynamic>> fields = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure all providers are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFields();
      }
    });
  }

  Future<void> _loadFields() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Use RepositoryProvider.of for BLoC pattern
      final fieldRepository = RepositoryProvider.of<FieldRepository>(context);
      print('🔄 PricesTab: Loading fields for stadium: ${widget.stadiumId}');

      // Fetch fields that belong to the stadium
      final stadiumFields = await fieldRepository
          .getFieldsByStadiumId(widget.stadiumId, forceRefresh: true);

      if (!mounted) return;

      print(
          '✅ PricesTab: Loaded ${stadiumFields.length} fields for stadium: ${widget.stadiumId}');

      if (stadiumFields.isEmpty) {
        print('ℹ️ PricesTab: No fields found, using default field');
        setState(() {
          fields = [
            {
              'id': 'default',
              'name': translationService.tr(
                  'prices_coupons.prices.default_field', {}, context)
            },
          ];
          selectedFieldId = 'default';
          isLoading = false;
        });
      } else {
        setState(() {
          fields = stadiumFields
              .map((field) => {
                    'id': field.id,
                    'name': field.name,
                  })
              .toList();
          selectedFieldId = fields.first['id'];
          isLoading = false;
        });
      }

      // Load prices for the selected field using BLoC
      if (mounted) {
        print('🔄 PricesTab: Loading prices for field: $selectedFieldId');
        BlocProvider.of<PricesBloc>(context).add(
          PricesLoadEvent(fieldId: selectedFieldId),
        );
      }
    } catch (e) {
      print('❌ PricesTab ERROR: Failed to load fields: $e');
      if (!mounted) return;

      // Fallback to default field if there's an error
      setState(() {
        fields = [
          {
            'id': 'default',
            'name': translationService.tr(
                'prices_coupons.prices.default_field', {}, context)
          },
        ];
        selectedFieldId = 'default';
        isLoading = false;
      });

      // Show error through properly mounted context
      Future.microtask(() {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            translationService.tr(
                'prices_coupons.prices.error_loading_fields', {}, context),
          );

          // Use BlocProvider to get bloc instance
          BlocProvider.of<PricesBloc>(context).add(
            PricesLoadEvent(fieldId: selectedFieldId),
          );
        }
      });
    }
  }

  void _handleFieldChanged(String? newFieldId) {
    if (newFieldId != null && newFieldId != selectedFieldId) {
      setState(() {
        selectedFieldId = newFieldId;
      });

      // Load prices for the newly selected field
      context.read<PricesBloc>().add(
            PricesLoadEvent(fieldId: selectedFieldId),
          );
    }
  }

  void _navigateToAddPriceScreen() {
    // Get the current PricesBloc instance from context
    final pricesBloc = BlocProvider.of<PricesBloc>(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: pricesBloc,
          child: AddEditPriceScreen(
            fieldId: selectedFieldId,
            isEditing: false,
          ),
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh prices when returning from add screen
      context.read<PricesBloc>().add(
            PricesLoadEvent(fieldId: selectedFieldId, forceRefresh: true),
          );
    });
  }

  void _navigateToEditPriceScreen(Price price) {
    // Get the current PricesBloc instance from context
    final pricesBloc = BlocProvider.of<PricesBloc>(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: pricesBloc,
          child: AddEditPriceScreen(
            fieldId: selectedFieldId,
            isEditing: true,
            price: price,
          ),
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh prices when returning from edit screen
      context.read<PricesBloc>().add(
            PricesLoadEvent(fieldId: selectedFieldId, forceRefresh: true),
          );
    });
  }

  void _confirmDeletePrice(Price price) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(translationService.tr(
              'prices_coupons.prices.confirm_delete', {}, context)),
          content: Text(translationService.tr(
              'prices_coupons.prices.confirm_delete_price_message',
              {},
              context)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(translationService.tr('common.cancel', {}, context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<PricesBloc>().add(
                      PricesDeleteEvent(priceId: price.id),
                    );
              },
              child: Text(
                translationService.tr('common.delete', {}, context),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field selection dropdown
          CustomDropdown.forFields(
            context: context,
            labelText: translationService.tr(
                'prices_coupons.prices.select_field', {}, context),
            value: selectedFieldId,
            fields: fields,
            onChanged: _handleFieldChanged,
          ),

          const SizedBox(height: 16),

          // Add price button
          CustomButton(
            text: translationService.tr(
                'prices_coupons.prices.add_price', {}, context),
            leadingIcon: Icons.add,
            onPressed: _navigateToAddPriceScreen,
            isFullWidth: true,
          ),

          const SizedBox(height: 16),

          // Prices list
          Expanded(
            child: BlocConsumer<PricesBloc, PricesState>(
              listener: (context, state) {
                if (state is PriceDeleted) {
                  CustomSnackBar.showSuccess(
                    context,
                    translationService.tr(
                        'prices_coupons.prices.price_deleted_successfully',
                        {},
                        context),
                  );
                } else if (state is PricesError) {
                  CustomSnackBar.showError(
                    context,
                    state.message,
                  );
                }
              },
              builder: (context, state) {
                if (state is PricesLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PricesLoaded) {
                  final prices = state.prices;

                  if (prices.isEmpty) {
                    return Center(
                      child: Text(
                        translationService.tr(
                            'prices_coupons.prices.no_prices_found',
                            {},
                            context),
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: prices.length,
                    itemBuilder: (context, index) {
                      final price = prices[index];
                      return Dismissible(
                        key: Key(price.id),
                        background: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.edit, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                translationService.tr(
                                    'common.edit', {}, context),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.delete, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                translationService.tr(
                                    'common.delete', {}, context),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: Text(translationService.tr(
                                      'prices_coupons.prices.confirm_delete',
                                      {},
                                      context)),
                                  content: Text(translationService.tr(
                                      'prices_coupons.prices.confirm_delete_price_message',
                                      {},
                                      context)),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                      child: Text(translationService.tr(
                                          'common.cancel', {}, context)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                      child: Text(
                                        translationService.tr(
                                            'common.delete', {}, context),
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else if (direction == DismissDirection.startToEnd) {
                            _navigateToEditPriceScreen(price);
                            return false;
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            context.read<PricesBloc>().add(
                                  PricesDeleteEvent(priceId: price.id),
                                );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToEditPriceScreen(price),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${price.startTime.format(context)} - ${price.endTime.format(context)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${price.pricePerHour} ${translationService.tr('prices_coupons.common.sar', {}, context)}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: price.daysOfWeek.map((day) {
                                      return Chip(
                                        label: Text(translationService.tr(
                                            'working_hours.days.$day',
                                            {},
                                            context)),
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        labelStyle: TextStyle(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is PricesError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  );
                }

                return Center(
                  child: Text(
                    translationService.tr(
                        'prices_coupons.prices.loading_prices', {}, context),
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
