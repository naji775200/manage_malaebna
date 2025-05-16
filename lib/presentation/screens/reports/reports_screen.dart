import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/reports/reports_bloc.dart';
import '../../../logic/reports/reports_event.dart';
import '../../../logic/reports/reports_state.dart';
import '../../../core/services/translation_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(translationService.tr(
              'stadium_management.tabs.reports', {}, context)),
          bottom: TabBar(
            tabs: [
              Tab(
                  text: translationService.tr(
                      'stadium_management.revenue_overview', {}, context)),
              Tab(
                  text: translationService.tr(
                      'stadium_management.total_bookings', {}, context)),
            ],
          ),
        ),
        body: const _ReportsContent(),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportsBloc()..add(const LoadReports('week')),
      child: Scaffold(
        appBar: AppBar(
          title: Text(translationService.tr(
              'stadium_management.tabs.reports', {}, context)),
        ),
        body: const _ReportsContent(),
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, ReportsState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translationService.tr(
                'stadium_management.select_period', {}, context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodButton(
                  context,
                  'day',
                  translationService.tr(
                      'stadium_management.today', {}, context),
                  Icons.today,
                  state.currentPeriod,
                ),
                _buildPeriodButton(
                  context,
                  'week',
                  translationService.tr(
                      'stadium_management.this_week', {}, context),
                  Icons.date_range,
                  state.currentPeriod,
                ),
                _buildPeriodButton(
                  context,
                  'month',
                  translationService.tr(
                      'stadium_management.this_month', {}, context),
                  Icons.calendar_month,
                  state.currentPeriod,
                ),
                _buildPeriodButton(
                  context,
                  'year',
                  translationService.tr(
                      'stadium_management.this_year', {}, context),
                  Icons.calendar_today,
                  state.currentPeriod,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(
    BuildContext context,
    String period,
    String label,
    IconData icon,
    String selectedPeriod,
  ) {
    final isSelected = selectedPeriod == period;

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: () {
          context.read<ReportsBloc>().add(ChangePeriod(period));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context,
              title: translationService.tr(
                  'stadium_management.total_bookings', {}, context),
              value: '${state.totalBookings}',
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              context,
              title: translationService.tr(
                  'stadium_management.total_revenue', {}, context),
              value: '${state.totalRevenue} SAR',
              icon: Icons.payments,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context, ReportsState state) {
    if (state.isLoading && !state.hasReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasReports) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              translationService.tr(
                  'stadium_management.no_reports', {}, context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              translationService.tr(
                  'stadium_management.no_reports_desc', {}, context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      );
    }

    // Get the appropriate key based on the selected period
    String dateKey = _getPeriodKey(state.currentPeriod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            translationService.tr(
                'stadium_management.detailed_report', {}, context),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ReportsBloc>()
                  .add(RefreshReports(state.currentPeriod));
              await Future.delayed(const Duration(milliseconds: 800));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: state.reports.length,
              itemBuilder: (context, index) {
                final report = state.reports[index];
                final date = report[dateKey] ??
                    report['date'] ??
                    report['week'] ??
                    report['month'] ??
                    'N/A';
                return _buildReportItem(
                  context,
                  date: date.toString(),
                  bookings: report['bookings'] as int? ?? 0,
                  revenue: report['revenue'] as int? ?? 0,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getPeriodKey(String period) {
    switch (period) {
      case 'day':
        return 'date';
      case 'week':
        return 'date';
      case 'month':
        return 'week';
      case 'year':
        return 'month';
      default:
        return 'date';
    }
  }

  Widget _buildReportItem(
    BuildContext context, {
    required String date,
    required int bookings,
    required int revenue,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatBookingsCount(bookings, context),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$revenue SAR',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBookingsCount(int count, BuildContext context) {
    return translationService.tr('stadium_management.bookings_count',
        {'count': count.toString()}, context);
  }
}
