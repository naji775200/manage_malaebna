import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/home/home_bloc.dart';
import '../../../logic/home/home_event.dart';
import '../../../logic/home/home_state.dart';
import 'dart:math';
import '../../../core/services/translation_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const LoadHomeData()),
      child: BlocConsumer<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state.isError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.errorMessage ??
                      translationService.tr(
                          'home.error_occurred', {}, context))),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(const RefreshHomeData());
            },
            child: _buildContent(context, state),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
    if (state.isInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stadium manager welcome section
          _buildWelcomeCard(context),

          const SizedBox(height: 24),

          // Quick stats
          _buildStatsSection(context),

          const SizedBox(height: 24),

          // Recent bookings
          _buildRecentBookingsSection(context, state),

          const SizedBox(height: 24),

          // Revenue chart
          _buildRevenueChart(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(200),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 46,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translationService.tr(
                      'stadium_management.welcome_manager', {}, context),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  translationService.tr(
                      'stadium_management.welcome_message', {}, context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translationService.tr('stadium_management.quick_stats', {}, context),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.sports_soccer,
                title: translationService.tr(
                    'stadium_management.total_fields', {}, context),
                value: '5',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.event_available,
                title: translationService.tr(
                    'stadium_management.bookings_today', {}, context),
                value: '12',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.mark_email_unread,
                title: translationService.tr(
                    'stadium_management.pending_requests', {}, context),
                value: '5',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.payments,
                title: translationService.tr(
                    'stadium_management.revenue_today', {}, context),
                value: '2,800 SAR',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookingsSection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              translationService.tr(
                  'stadium_management.recent_bookings', {}, context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to match requests
                context.read<HomeBloc>().add(const ViewAllUpcomingMatches());
              },
              child:
                  Text(translationService.tr('common.view_all', {}, context)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3, // Show only 3 items
          itemBuilder: (context, index) {
            // Create some mock data with translations
            final List<String> fieldNames = [
              translationService.tr('home.field_names.field_a', {}, context),
              translationService.tr('home.field_names.field_b', {}, context),
              translationService.tr('home.field_names.field_c', {}, context),
            ];
            final List<String> times = [
              translationService.tr('home.times.time_1', {}, context),
              translationService.tr('home.times.time_2', {}, context),
              translationService.tr('home.times.time_3', {}, context),
            ];
            final List<String> clientNames = [
              translationService.tr('home.clients.client_1', {}, context),
              translationService.tr('home.clients.client_2', {}, context),
              translationService.tr('home.clients.client_3', {}, context),
            ];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  fieldNames[index],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${clientNames[index]} • ${times[index]}',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    width: 100, // Set a fixed width constraint
                    height: 35,
                    child: Center(
                      child: Text(
                        translationService.tr(
                            'home.status.confirmed', {}, context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title and period selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                translationService.tr(
                    'stadium_management.revenue_overview', {}, context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              DropdownButton<String>(
                value: 'weekly',
                underline: const SizedBox(),
                isDense: true,
                items: [
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(
                      translationService.translate(
                          'home.chart.weekly', {}, context),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(
                      translationService.translate(
                          'home.chart.monthly', {}, context),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  // In a real app, this would change the data period
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Y-axis label
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              translationService.translate('home.chart.revenue', {}, context),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // The chart
          SizedBox(
            height: 220,
            child: _buildMockChart(context),
          ),

          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend(
                context,
                color: Theme.of(context).colorScheme.primary,
                label: translationService.tr(
                    'stadium_management.this_week', {}, context),
              ),
              const SizedBox(width: 24),
              _buildChartLegend(
                context,
                color: Colors.blue.shade300,
                label: translationService.tr(
                    'stadium_management.last_week', {}, context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockChart(BuildContext context) {
    // This is a custom chart implementation using basic Flutter widgets
    // Create mock data for this week and last week
    final thisWeekData = _generateWeeklyRevenueData(isCurrentWeek: true);
    final lastWeekData = _generateWeeklyRevenueData(isCurrentWeek: false);

    // Find maximum value to scale accordingly
    final maxValue =
        [...thisWeekData, ...lastWeekData].reduce((a, b) => a > b ? a : b);
    // Use a smaller scale factor (0.8 of the original) to ensure there's always margin at the bottom
    final scaleFactor = (150 / maxValue) * 0.8;

    // Days of the week for labels
    final weekdays = [
      translationService.translate('home.chart.mon', {}, context),
      translationService.translate('home.chart.tue', {}, context),
      translationService.translate('home.chart.wed', {}, context),
      translationService.translate('home.chart.thu', {}, context),
      translationService.translate('home.chart.fri', {}, context),
      translationService.translate('home.chart.sat', {}, context),
      translationService.translate('home.chart.sun', {}, context),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Y-axis labels on the left
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150, // Same height as chart
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${(maxValue).round()}",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    Text(
                      "${(maxValue * 2 / 3).round()}",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    Text(
                      "${(maxValue * 1 / 3).round()}",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    Text(
                      "0",
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28), // Space for day labels
            ],
          ),

          const SizedBox(width: 8),

          // Chart container with bars and day labels
          Expanded(
            child: Column(
              children: [
                // Bar chart
                SizedBox(
                  height: 150,
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Divider(color: Colors.grey.shade200, height: 1),
                          Divider(color: Colors.grey.shade200, height: 1),
                          Divider(color: Colors.grey.shade200, height: 1),
                          Divider(color: Colors.grey.shade200, height: 1),
                        ],
                      ),

                      // Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (index) {
                          // Calculate height based on percentage of max value
                          final thisWeekHeight =
                              thisWeekData[index] * scaleFactor;
                          final lastWeekHeight =
                              lastWeekData[index] * scaleFactor;

                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // This week's bar
                                  Container(
                                    height: thisWeekHeight,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  // Last week's bar
                                  Container(
                                    height: lastWeekHeight,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade300,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Day labels
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays
                      .map((day) => Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to generate random revenue data with more reasonable values
  List<double> _generateWeeklyRevenueData({required bool isCurrentWeek}) {
    final random = Random();
    final multiplier = isCurrentWeek ? 1.0 : 0.8; // Last week is slightly lower

    return List.generate(7, (index) {
      // Calculate a reasonable revenue value based on day of week
      double baseValue;
      int maxRandomValue;

      // Lower values during weekdays, slightly higher on weekends
      if (index < 5) {
        // Weekdays (Mon-Fri)
        baseValue = 1000.0;
        maxRandomValue = 800;
      } else {
        // Weekends (Sat-Sun)
        baseValue = 1500.0; // Lower than before
        maxRandomValue = 600; // Smaller random component
      }

      return (baseValue + random.nextInt(maxRandomValue)) * multiplier;
    });
  }

  Widget _buildChartLegend(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
