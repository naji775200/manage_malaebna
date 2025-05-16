import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/services/localization_service.dart';
import '../../../logic/payment/payment_bloc.dart';
import '../../../logic/payment/payment_event.dart';
import '../../../logic/payment/payment_state.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../core/constants/theme.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../core/utils/security_helper.dart';

class PaymentScreen extends StatelessWidget {
  final double amount;

  const PaymentScreen({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    // Get the repository from the provider
    final paymentRepository = context.read<PaymentRepository>();

    return BlocProvider(
      create: (context) => PaymentBloc(
        paymentRepository: paymentRepository,
      )..add(const LoadPaymentHistory()),
      child: _PaymentHistoryContent(amount: amount),
    );
  }
}

class _PaymentHistoryContent extends StatefulWidget {
  final double amount;

  const _PaymentHistoryContent({required this.amount});

  @override
  State<_PaymentHistoryContent> createState() => _PaymentHistoryContentState();
}

class _PaymentHistoryContentState extends State<_PaymentHistoryContent> {
  final TextEditingController _searchController = TextEditingController();
  final DateTimeRange _defaultDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    // Check stadium ID on init
    _verifyStadiumAccess();
  }

  // Verify that user has access to stadium payments
  Future<void> _verifyStadiumAccess() async {
    final stadiumId = await AuthUtils.getStadiumIdFromAuth();
    if (stadiumId == null) {
      // If no stadium ID, show error immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Access denied: You need to be logged in as a stadium owner to view payments',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            title: Text(context.tr('payment.history.title')),
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                tooltip: context.tr('payment.history.export'),
                onPressed: () => null,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.tr('payment.history.refresh'),
                onPressed: () {
                  context.read<PaymentBloc>().add(RefreshPaymentHistory());
                },
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPaymentHistoryContent(context, state),
        );
      },
    );
  }

  Widget _buildPaymentHistoryContent(BuildContext context, PaymentState state) {
    return Column(
      children: [
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
          _buildErrorMessage(context, state.errorMessage!),
        _buildFilterBar(context, state),
        _buildSummaryStats(context, state),
        Expanded(
          child: state.transactions.isEmpty
              ? _buildEmptyState(context)
              : _buildTransactionList(context, state),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, PaymentState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodFilterChip(
                  context: context,
                  label: context.tr('payment.history.time_periods.day'),
                  period: 'day',
                  state: state,
                ),
                _buildPeriodFilterChip(
                  context: context,
                  label: context.tr('payment.history.time_periods.week'),
                  period: 'week',
                  state: state,
                ),
                _buildPeriodFilterChip(
                  context: context,
                  label: context.tr('payment.history.time_periods.month'),
                  period: 'month',
                  state: state,
                ),
                _buildPeriodFilterChip(
                  context: context,
                  label: context.tr('payment.history.time_periods.year'),
                  period: 'year',
                  state: state,
                ),
                _buildPeriodFilterChip(
                  context: context,
                  label: context.tr('payment.history.time_periods.all_time'),
                  period: 'all',
                  state: state,
                ),
                _buildCustomRangeFilterChip(context, state),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSearchField(context),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterChip({
    required BuildContext context,
    required String label,
    required String period,
    required PaymentState state,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: state.selectedPeriod == period,
        onSelected: (selected) {
          if (selected) {
            context.read<PaymentBloc>().add(LoadPaymentHistory(period: period));
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: state.selectedPeriod == period
              ? AppTheme.primaryColor
              : Colors.black87,
          fontWeight: state.selectedPeriod == period
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCustomRangeFilterChip(BuildContext context, PaymentState state) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(context.tr('payment.history.time_periods.custom_range')),
        selected: state.selectedPeriod == 'custom',
        onSelected: (selected) async {
          if (selected) {
            await _showDateRangePicker(context);
          }
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: state.selectedPeriod == 'custom'
              ? AppTheme.primaryColor
              : Colors.black87,
          fontWeight: state.selectedPeriod == 'custom'
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: context.tr('payment.history.search_placeholder'),
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                  context
                      .read<PaymentBloc>()
                      .add(const SearchPayments(query: ''));
                },
              )
            : null,
      ),
      onChanged: (value) {
        context.read<PaymentBloc>().add(SearchPayments(query: value));
      },
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? selectedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _defaultDateRange,
      firstDate: DateTime(2021),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
                ? ColorScheme.dark(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).colorScheme.surface,
                    onSurface: Theme.of(context).colorScheme.onSurface,
                  )
                : ColorScheme.light(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).colorScheme.surface,
                    onSurface: Theme.of(context).colorScheme.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange != null && mounted) {
      context.read<PaymentBloc>().add(FilterByDateRange(
          startDate: selectedRange.start, endDate: selectedRange.end));
    }
  }

  Widget _buildSummaryStats(BuildContext context, PaymentState state) {
    final currencyFormat = NumberFormat.currency(symbol: 'SAR ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context: context,
              title: context.tr('payment.history.total_revenue'),
              value: currencyFormat.format(state.totalRevenue),
              icon: Icons.account_balance_wallet,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context: context,
              title: context.tr('payment.history.transactions'),
              value: state.transactionCount.toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage != null && state.errorMessage!.isNotEmpty
                    ? context.tr('payment.history.access_denied')
                    : context.tr('payment.history.empty_state'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage != null && state.errorMessage!.isNotEmpty
                    ? context.tr('payment.history.login_as_stadium')
                    : context.tr('payment.history.empty_state_message'),
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(BuildContext context, PaymentState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length,
      itemBuilder: (context, index) {
        final transaction = state.transactions[index];
        return _buildTransactionCard(context, transaction);
      },
    );
  }

  Widget _buildTransactionCard(
      BuildContext context, Map<String, dynamic> transaction) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final date = transaction['date'] as DateTime;
    final amount = transaction['amount'] as double;
    final playerName = transaction['playerName'] as String? ?? 'Unknown Player';
    final fieldName = transaction['fieldName'] as String? ?? 'Unknown Field';
    final paymentMethod =
        transaction['paymentMethod'] as String? ?? 'Unknown Method';
    final status = transaction['status'] as String? ?? 'pending';
    final isCompleted = status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showTransactionDetails(context, transaction);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Player name and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        playerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        NumberFormat.currency(symbol: 'SAR ').format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Field name and payment method in one row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Field information with rounded container
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stadium,
                              size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            fieldName,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Payment method with status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            paymentMethod == 'Cash'
                                ? Icons.payments_outlined
                                : paymentMethod == 'Credit Card'
                                    ? Icons.credit_card
                                    : Icons.smartphone,
                            size: 14,
                            color: isCompleted
                                ? AppTheme.primaryColor
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            paymentMethod,
                            style: TextStyle(
                              color: isCompleted
                                  ? AppTheme.primaryColor
                                  : Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppTheme.primaryColor
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date information in its own row at the bottom
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(date),
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
      BuildContext context, Map<String, dynamic> transaction) {
    final dateFormat = DateFormat.yMMMd().add_jm();
    final date = transaction['date'] as DateTime;
    final amount = transaction['amount'] as double;
    final playerName = transaction['playerName'] as String? ?? 'Unknown Player';
    final fieldName = transaction['fieldName'] as String? ?? 'Unknown Field';
    final playerId = transaction['playerId'] as String? ?? 'Unknown';
    final paymentMethod =
        transaction['paymentMethod'] as String? ?? 'Unknown Method';
    final status = transaction['status'] as String? ?? 'pending';
    final isCompleted = status.toLowerCase() == 'completed';
    final transactionId = transaction['id'] as String? ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.7,
            minChildSize: 0.3,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Transaction ID and Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr(
                                'payment.history.transaction_details.title'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              NumberFormat.currency(symbol: 'SAR ')
                                  .format(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCompleted ? Icons.check_circle : Icons.pending,
                              color: isCompleted
                                  ? AppTheme.primaryColor
                                  : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: isCompleted
                                    ? AppTheme.primaryColor
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Transaction details in rounded cards
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRowCard(
                              context,
                              context
                                  .tr('payment.history.transaction_details.id'),
                              transactionId,
                              Icons.receipt,
                              AppTheme.primaryColor,
                            ),
                            _buildDetailRowCard(
                              context,
                              context.tr(
                                  'payment.history.transaction_details.date_time'),
                              dateFormat.format(date),
                              Icons.calendar_today,
                              Colors.blue,
                            ),
                            _buildDetailRowCard(
                              context,
                              context.tr(
                                  'payment.history.transaction_details.player_name'),
                              playerName,
                              Icons.person,
                              Colors.purple,
                            ),
                            _buildDetailRowCard(
                              context,
                              context.tr(
                                  'payment.history.transaction_details.player_id'),
                              playerId,
                              Icons.badge,
                              Colors.amber,
                            ),
                            _buildDetailRowCard(
                              context,
                              context.tr(
                                  'payment.history.transaction_details.field'),
                              fieldName,
                              Icons.stadium,
                              Colors.teal,
                            ),
                            _buildDetailRowCard(
                              context,
                              context.tr(
                                  'payment.history.transaction_details.payment_method'),
                              paymentMethod,
                              paymentMethod == 'Cash'
                                  ? Icons.payments_outlined
                                  : Icons.credit_card,
                              Colors.indigo,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.file_download_outlined),
                              label: Text(context.tr(
                                  'payment.history.transaction_details.download_receipt')),
                              onPressed: () {
                                // In a real app, this would download the receipt
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(context.tr(
                                          'payment.history.transaction_details.receipt_download_started'))),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(
                                    color: AppTheme.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.email_outlined),
                              label: Text(context.tr(
                                  'payment.history.transaction_details.email_receipt')),
                              onPressed: () {
                                // In a real app, this would email the receipt
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(context.tr(
                                          'payment.history.transaction_details.receipt_email_sent'))),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRowCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.grey.shade200))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(context.tr('payment.history.export_options.pdf')),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<PaymentBloc>()
                      .add(const ExportPaymentData(format: 'pdf'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.tr(
                            'payment.history.export_options.export_started'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(context.tr('payment.history.export_options.csv')),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<PaymentBloc>()
                      .add(const ExportPaymentData(format: 'csv'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.tr(
                            'payment.history.export_options.export_started'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(context.tr('payment.history.export_options.excel')),
                onTap: () {
                  Navigator.pop(context);
                  context
                      .read<PaymentBloc>()
                      .add(const ExportPaymentData(format: 'excel'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.tr(
                            'payment.history.export_options.export_started'))),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cleanupPaymentData(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('payment.cleanup.title')),
        content: Text(context.tr('payment.cleanup.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.tr('payment.cleanup.confirm')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.tr('payment.cleanup.in_progress')),
          ],
        ),
      ),
    );

    try {
      // Perform the cleanup
      final success = await SecurityHelper.performFullDataCleanup();

      // Remove the loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('payment.cleanup.success')),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the payment data
        if (mounted) {
          context.read<PaymentBloc>().add(RefreshPaymentHistory());
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('payment.cleanup.error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Remove the loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('payment.cleanup.error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
