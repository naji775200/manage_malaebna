import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/match_model.dart';
import '../../../data/models/field_model.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/field_repository.dart';
import '../../../data/repositories/match_history_repository.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../logic/match_requests/match_requests_bloc.dart';
import '../../../logic/match_requests/match_requests_event.dart';
import '../../../logic/match_requests/match_requests_state.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_snackbar.dart';

class MatchRequestsScreen extends StatelessWidget {
  const MatchRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MatchRequestsBloc(
        matchRepository: context.read<MatchRepository>(),
        bookingRepository: context.read<BookingRepository>(),
        matchHistoryRepository: context.read<MatchHistoryRepository>(),
        fieldRepository: context.read<FieldRepository>(),
      )..add(const LoadMatchRequests()),
      child: const DefaultTabController(
        length: 5,
        child: Scaffold(
          body: Column(
            children: [
              SafeArea(child: _MatchRequestsTabs()),
              Expanded(
                child: TabBarView(
                  children: [
                    _MatchRequestsTab(status: 'Pending'),
                    _MatchRequestsTab(status: 'Accepted'),
                    _MatchRequestsTab(status: 'Completed'),
                    _MatchRequestsTab(status: 'Rejected'),
                    _MatchRequestsTab(status: 'Canceled'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRequestsTabs extends StatelessWidget {
  const _MatchRequestsTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: TabBar(
        isScrollable: true, // Allow tabs to scroll if needed
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
        ),
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          Tab(
            child: Text(
              translationService.tr(
                'stadium_management.tabs.pending',
                {},
                context,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Tab(
            child: Text(
              translationService.tr(
                'stadium_management.tabs.accepted',
                {},
                context,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Tab(
            child: Text(
              translationService.tr(
                'stadium_management.tabs.completed',
                {},
                context,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Tab(
            child: Text(
              translationService.tr(
                'stadium_management.tabs.rejected',
                {},
                context,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Tab(
            child: Text(
              translationService.tr(
                'stadium_management.tabs.canceled',
                {},
                context,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRequestsTab extends StatelessWidget {
  final String status;

  const _MatchRequestsTab({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchRequestsBloc, MatchRequestsState>(
      builder: (context, state) {
        if (state.isLoading && !state.hasMatchRequestsWithStatus(status)) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter requests by status
        final filteredRequests = _getItemsForStatus(state, status);

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_available,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  translationService.tr(
                      'stadium_management.no_${status.toLowerCase()}_matches',
                      {},
                      context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  translationService.tr(
                      'stadium_management.no_${status.toLowerCase()}_matches_desc',
                      {},
                      context),
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

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MatchRequestsBloc>().add(
                  const RefreshMatchRequests(),
                );
            // Wait for refresh to complete
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final item = filteredRequests[index];
              if ((status == 'Pending' ||
                      status == 'Rejected' ||
                      status == 'Canceled') &&
                  item is Booking) {
                return _buildBookingRequestCard(context, item);
              } else if (item is Match) {
                return _buildMatchCard(context, item);
              }
              return const SizedBox.shrink(); // Fallback
            },
          ),
        );
      },
    );
  }

  // Helper method to get the right list based on status
  List<dynamic> _getItemsForStatus(MatchRequestsState state, String status) {
    switch (status) {
      case 'Pending':
        return state.pendingBookings;
      case 'Rejected':
        return state.rejectedBookings;
      case 'Canceled':
        return state.canceledBookings;
      case 'Accepted':
        return state.acceptedMatches;
      case 'Completed':
        return state.matchesWithHistory;
      default:
        return [];
    }
  }

  Widget _buildBookingRequestCard(BuildContext context, Booking booking) {
    final isRightToLeft = Directionality.of(context) == TextDirection.RTL;

    return FutureBuilder<Match?>(
        future: context.read<MatchRepository>().getMatchById(booking.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final match = snapshot.data;
          if (match == null) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Match header with color band
                Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, status),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_soccer,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.description ?? 'Match',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status == 'Pending'
                              ? translationService.tr(
                                  'match_requests.pending_review', {}, context)
                              : status == 'Rejected'
                                  ? translationService.tr(
                                      'stadium_management.reject', {}, context)
                                  : status == 'Canceled'
                                      ? translationService.tr(
                                          'common.cancel', {}, context)
                                      : status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Match details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Match information
                      Row(
                        children: [
                          _buildMatchInfoItem(
                            context,
                            Icons.calendar_today,
                            translationService.tr(
                                'stadium_management.match_date', {}, context),
                            DateFormat.yMMMd().format(match.date),
                          ),
                          _buildMatchInfoItem(
                            context,
                            Icons.access_time,
                            translationService.tr(
                                'stadium_management.match_time', {}, context),
                            '${match.startTime.format(context)} - ${match.endTime.format(context)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<Field?>(
                              future: context
                                  .read<FieldRepository>()
                                  .getFieldById(match.fieldId),
                              builder: (context, fieldSnapshot) {
                                if (fieldSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Row(
                                    children: [
                                      Icon(
                                        Icons.sports_soccer,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              translationService.tr(
                                                  'stadium_management.match_field',
                                                  {},
                                                  context),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                final field = fieldSnapshot.data;
                                final fieldName =
                                    field?.name ?? 'Unknown Field';

                                return Row(
                                  children: [
                                    Icon(
                                      Icons.sports_soccer,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            translationService.tr(
                                                'stadium_management.match_field',
                                                {},
                                                context),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            fieldName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          _buildMatchInfoItem(
                            context,
                            Icons.people,
                            translationService.tr(
                                'stadium_management.match_players',
                                {},
                                context),
                            '${match.currentPlayers} / ${match.playersNeeded}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Requester information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              radius: 20,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translationService.tr(
                                        'stadium_management.requested_by',
                                        {},
                                        context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.playerId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${booking.numberOfPlayers} Players',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // For rejected bookings, show rejection reason
                      if (status == 'Rejected' &&
                          booking.status.toLowerCase() == 'rejected')
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        translationService.tr(
                                            'stadium_management.rejection_reason',
                                            {},
                                            context),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    booking.cancellation?.reason ??
                                        'No reason provided',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // For canceled bookings, show cancellation details
                      if (status == 'Canceled' && booking.cancellation != null)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.event_busy,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        translationService.tr(
                                            'common.cancel', {}, context),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              translationService.tr(
                                                  'stadium_management.rejection_reason',
                                                  {},
                                                  context),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              booking.cancellation!.reason,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              translationService.tr(
                                                  'stadium_management.refund_amount',
                                                  {},
                                                  context),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${booking.cancellation!.refundAmount} SAR',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              translationService.tr(
                                                  'stadium_management.canceled_date',
                                                  {},
                                                  context),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat.yMMMd().format(booking
                                                  .cancellation!.canceledAt),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
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

                      const SizedBox(height: 16),

                      // Action buttons - only show for pending requests
                      if (status == 'Pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _showRejectBookingDialog(context, booking);
                                },
                                icon: const Icon(Icons.close),
                                label: Text(translationService.tr(
                                    'stadium_management.reject', {}, context)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showApproveBookingDialog(
                                      context, booking, match);
                                },
                                icon: const Icon(Icons.check),
                                label: Text(translationService.tr(
                                    'stadium_management.approve', {}, context)),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildMatchCard(BuildContext context, Match match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Match header with color band
          Container(
            decoration: BoxDecoration(
              color: _getStatusColor(context, status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.description ?? 'Match',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Match details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Match information in a grid
                Row(
                  children: [
                    _buildMatchInfoItem(
                      context,
                      Icons.calendar_today,
                      translationService.tr(
                          'stadium_management.match_date', {}, context),
                      DateFormat.yMMMd().format(match.date),
                    ),
                    _buildMatchInfoItem(
                      context,
                      Icons.access_time,
                      translationService.tr(
                          'stadium_management.match_time', {}, context),
                      '${match.startTime.format(context)} - ${match.endTime.format(context)}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<Field?>(
                        future: context
                            .read<FieldRepository>()
                            .getFieldById(match.fieldId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Row(
                              children: [
                                Icon(
                                  Icons.sports_soccer,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        translationService.tr(
                                            'stadium_management.match_field',
                                            {},
                                            context),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          final field = snapshot.data;
                          final fieldName = field?.name ?? 'Unknown Field';

                          return Row(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      translationService.tr(
                                          'stadium_management.match_field',
                                          {},
                                          context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fieldName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _buildMatchInfoItem(
                      context,
                      Icons.people,
                      translationService.tr(
                          'stadium_management.match_players', {}, context),
                      '${match.currentPlayers} / ${match.playersNeeded}',
                    ),
                  ],
                ),

                if (match.history != null && match.history!.result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          radius: 20,
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                translationService.tr(
                                    'stadium_management.match_result',
                                    {},
                                    context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                match.history!.result!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      case 'Canceled':
        return Colors.orange;
      case 'Pending':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildMatchInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveBookingDialog(
      BuildContext context, Booking booking, Match match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translationService.tr(
            'stadium_management.approve_match', {}, context)),
        content: Text(
          translationService.tr(
              'stadium_management.approve_match_confirmation',
              {
                'matchName': match.description ?? 'Match',
                'fieldName': match.fieldId,
              },
              context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(translationService.tr('common.cancel', {}, context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Show success message
              CustomSnackBar.showSuccess(
                  context,
                  translationService.tr(
                      'stadium_management.match_approved', {}, context));

              // Add the approval event
              context.read<MatchRequestsBloc>().add(
                    ApproveMatchRequest(
                      bookingId: booking.id,
                      matchId: match.id,
                    ),
                  );
            },
            child: Text(translationService.tr(
                'stadium_management.approve', {}, context)),
          ),
        ],
      ),
    );
  }

  void _showRejectBookingDialog(BuildContext context, Booking booking) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(translationService.tr(
            'stadium_management.reject_match', {}, context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translationService.tr(
                  'stadium_management.reject_match_confirmation',
                  {
                    'matchName': 'Booking',
                  },
                  context),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: translationService.tr(
                    'stadium_management.rejection_reason', {}, context),
                border: const OutlineInputBorder(),
                hintText: translationService.tr(
                    'stadium_management.rejection_reason_hint', {}, context),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(translationService.tr('common.cancel', {}, context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Show success message
              CustomSnackBar.showSuccess(
                  context,
                  translationService.tr(
                      'stadium_management.match_rejected', {}, context));

              // Add the rejection event
              context.read<MatchRequestsBloc>().add(
                    RejectMatchRequest(
                      bookingId: booking.id,
                      reason: reasonController.text,
                    ),
                  );
            },
            child: Text(translationService.tr(
                'stadium_management.reject', {}, context)),
          ),
        ],
      ),
    );
  }
}
