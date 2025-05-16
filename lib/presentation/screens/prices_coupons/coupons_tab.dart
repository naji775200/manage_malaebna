import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/coupon_model.dart';
import '../../../logic/coupons/coupons_bloc.dart';
import '../../../logic/coupons/coupons_event.dart';
import '../../../logic/coupons/coupons_state.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_snackbar.dart';
import 'add_edit_coupon_screen.dart';

class CouponsTab extends StatefulWidget {
  final String stadiumId;

  const CouponsTab({
    super.key,
    required this.stadiumId,
  });

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    print('🔄 CouponsTab: Loading coupons for stadium: ${widget.stadiumId}');
    context.read<CouponsBloc>().add(
          CouponsLoadEvent(stadiumId: widget.stadiumId),
        );
  }

  void _navigateToAddCouponScreen() {
    // Get the current CouponsBloc instance from context
    final couponsBloc = BlocProvider.of<CouponsBloc>(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: couponsBloc,
          child: AddEditCouponScreen(
            stadiumId: widget.stadiumId,
            isEditing: false,
          ),
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh coupons when returning from add screen
      _loadCoupons();
    });
  }

  void _navigateToEditCouponScreen(Coupon coupon) {
    // Get the current CouponsBloc instance from context
    final couponsBloc = BlocProvider.of<CouponsBloc>(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: couponsBloc,
          child: AddEditCouponScreen(
            stadiumId: widget.stadiumId,
            isEditing: true,
            coupon: coupon,
          ),
        ),
        fullscreenDialog: true,
      ),
    ).then((_) {
      // Refresh coupons when returning from edit screen
      _loadCoupons();
    });
  }

  void _confirmDeleteCoupon(Coupon coupon) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(translationService.tr(
              'prices_coupons.coupons.confirm_delete', {}, context)),
          content: Text(translationService.tr(
              'prices_coupons.coupons.confirm_delete_coupon_message',
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
                context.read<CouponsBloc>().add(
                      CouponsDeleteEvent(couponId: coupon.id),
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

  String _getCouponStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'prices_coupons.coupons.active_coupon';
      case 'inactive':
        return 'prices_coupons.coupons.inactive_coupon';
      case 'expired':
        return 'prices_coupons.coupons.expired_coupon';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add coupon button
          CustomButton(
            text: translationService.tr(
                'prices_coupons.coupons.add_coupon', {}, context),
            leadingIcon: Icons.add,
            onPressed: _navigateToAddCouponScreen,
            isFullWidth: true,
          ),

          const SizedBox(height: 16),

          // Coupons list
          Expanded(
            child: BlocConsumer<CouponsBloc, CouponsState>(
              listener: (context, state) {
                if (state is CouponDeleted) {
                  CustomSnackBar.showSuccess(
                    context,
                    translationService.tr(
                        'prices_coupons.coupons.coupon_deleted_successfully',
                        {},
                        context),
                  );
                } else if (state is CouponsError) {
                  CustomSnackBar.showError(
                    context,
                    state.message,
                  );
                }
              },
              builder: (context, state) {
                if (state is CouponsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CouponsLoaded) {
                  final coupons = state.coupons;

                  if (coupons.isEmpty) {
                    return Center(
                      child: Text(
                        translationService.tr(
                            'prices_coupons.coupons.no_coupons_found',
                            {},
                            context),
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final isExpired =
                          coupon.expirationDate.isBefore(DateTime.now());
                      final statusText = isExpired
                          ? translationService.tr(
                              'prices_coupons.coupons.expired_coupon',
                              {},
                              context)
                          : translationService.tr(
                              _getCouponStatusColor(coupon.status),
                              {},
                              context);
                      final statusColor = isExpired
                          ? Colors.red
                          : coupon.status.toLowerCase() == 'active'
                              ? Colors.green
                              : Colors.orange;

                      return Dismissible(
                        key: Key(coupon.id),
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
                                      'prices_coupons.coupons.confirm_delete',
                                      {},
                                      context)),
                                  content: Text(translationService.tr(
                                      'prices_coupons.coupons.confirm_delete_coupon_message',
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
                            _navigateToEditCouponScreen(coupon);
                            return false;
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            context.read<CouponsBloc>().add(
                                  CouponsDeleteEvent(couponId: coupon.id),
                                );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToEditCouponScreen(coupon),
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
                                      Expanded(
                                        child: Text(
                                          coupon.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: statusColor,
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          '${coupon.discountPercentage}% ${translationService.tr('prices_coupons.coupons.off', {}, context)}',
                                          style: TextStyle(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${translationService.tr('prices_coupons.coupons.code', {}, context)}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        coupon.code,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${translationService.tr('prices_coupons.coupons.expires', {}, context)}: ${dateFormat.format(coupon.expirationDate)}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${coupon.startTime.format(context)} - ${coupon.endTime.format(context)}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: coupon.daysOfWeek.map((day) {
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
                                          fontSize: 12,
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                } else if (state is CouponsError) {
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
                        'prices_coupons.coupons.loading_coupons', {}, context),
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
