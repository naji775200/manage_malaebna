import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/translation_service.dart';
import '../../../core/utils/auth_utils.dart';
import '../../../data/repositories/price_repository.dart';
import '../../../data/repositories/field_repository.dart';
import '../../../data/local/price_local_data_source.dart';
import '../../../data/remote/price_remote_data_source.dart';
import '../../../data/local/field_local_data_source.dart';
import '../../../data/remote/field_remote_data_source.dart';
import '../../../data/repositories/coupon_repository.dart';
import '../../../data/local/coupon_local_data_source.dart';
import '../../../data/remote/coupon_remote_data_source.dart';
import '../../../logic/prices/prices_bloc.dart';
import '../../../logic/coupons/coupons_bloc.dart';
import '../../../logic/coupons/coupons_event.dart';
import 'prices_tab.dart';
import 'coupons_tab.dart';

class PricesCouponsScreen extends StatefulWidget {
  final String stadiumId;
  final String stadiumName;

  const PricesCouponsScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
  });

  @override
  State<PricesCouponsScreen> createState() => _PricesCouponsScreenState();
}

class _PricesCouponsScreenState extends State<PricesCouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _validStadiumId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchValidStadiumId();
  }

  Future<void> _fetchValidStadiumId() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Try to get stadium ID from authentication
      final authStadiumId = await AuthUtils.getStadiumIdFromAuth();

      if (authStadiumId != null && authStadiumId.isNotEmpty) {
        print(
            '🔑 PricesCouponsScreen: Using stadium ID from auth: $authStadiumId');
        _validStadiumId = authStadiumId;
      } else {
        // Fallback to the passed ID if auth fails
        print(
            '🔑 PricesCouponsScreen: Auth failed, using passed stadium ID: ${widget.stadiumId}');
        _validStadiumId = widget.stadiumId;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ PricesCouponsScreen ERROR: Failed to get valid stadium ID: $e');
      // Fallback to passed stadium ID on error
      _validStadiumId = widget.stadiumId;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supabase = Supabase.instance.client;

    // Show loading indicator while fetching stadium ID
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "${translationService.tr('prices_coupons.title', {}, context)}",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Make sure we have a valid stadium ID
    final effectiveStadiumId = _validStadiumId ?? widget.stadiumId;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<FieldRepository>(
          create: (context) => FieldRepository(
            remoteDataSource: FieldRemoteDataSource(supabaseClient: supabase),
            localDataSource: FieldLocalDataSource(),
            connectivity: Connectivity(),
          ),
        ),
        RepositoryProvider<PriceRepository>(
          create: (context) => PriceRepository(
            remoteDataSource: PriceRemoteDataSource(supabaseClient: supabase),
            localDataSource: PriceLocalDataSource(),
            connectivity: Connectivity(),
          ),
        ),
        RepositoryProvider<CouponRepository>(
          create: (context) => CouponRepository(
            remoteDataSource: CouponRemoteDataSource(supabaseClient: supabase),
            localDataSource: CouponLocalDataSource(),
            connectivity: Connectivity(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider<PricesBloc>(
              create: (context) => PricesBloc(
                priceRepository:
                    RepositoryProvider.of<PriceRepository>(context),
              ),
            ),
            BlocProvider<CouponsBloc>(
              create: (context) => CouponsBloc(
                couponRepository:
                    RepositoryProvider.of<CouponRepository>(context),
              )..add(CouponsLoadEvent(stadiumId: effectiveStadiumId)),
            ),
          ],
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                "${translationService.tr('prices_coupons.title', {}, context)}",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                      text: translationService.tr(
                          'prices_coupons.prices.tab_title', {}, context)),
                  Tab(
                      text: translationService.tr(
                          'prices_coupons.coupons.tab_title', {}, context)),
                ],
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor:
                    theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                PricesTab(stadiumId: effectiveStadiumId),
                CouponsTab(stadiumId: effectiveStadiumId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
