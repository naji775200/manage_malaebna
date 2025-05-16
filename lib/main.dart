import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'logic/localization_bloc.dart';
import 'logic/onboarding/onboarding_bloc.dart';
import 'logic/theme/theme_bloc.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/auth/auth_event.dart';
import 'logic/auth/auth_state.dart';
import 'core/constants/theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/network_info.dart';
import 'presentation/routes/app_routes.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/main_screen.dart';
import 'core/services/localization_service.dart';
import 'core/services/translation_service.dart';
import 'core/utils/security_helper.dart';
import 'data/repositories/working_hours_repository.dart';
import 'data/repositories/time_off_repository.dart';
import 'data/repositories/match_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/match_history_repository.dart';
import 'data/repositories/field_repository.dart';
import 'data/repositories/entity_images_repository.dart';
import 'data/local/working_hours_local_data_source.dart';
import 'data/local/time_off_local_data_source.dart';
import 'data/local/match_local_data_source.dart';
import 'data/local/booking_local_data_source.dart';
import 'data/local/match_history_local_data_source.dart';
import 'data/local/field_local_data_source.dart';
import 'data/remote/working_hours_remote_data_source.dart';
import 'data/remote/time_off_remote_data_source.dart';
import 'data/remote/match_remote_data_source.dart';
import 'data/remote/booking_remote_data_source.dart';
import 'data/remote/match_history_remote_data_source.dart';
import 'data/remote/field_remote_data_source.dart';
import 'data/repositories/payment_repository.dart';
import 'data/remote/payment_remote_data_source.dart';
import 'data/local/payment_local_data_source.dart';
import 'data/repositories/service_repository.dart';
import 'data/repositories/stadium_services_repository.dart';
import 'data/repositories/stadium_repository.dart';
import 'data/repositories/address_repository.dart';
import 'data/remote/service_remote_data_source.dart';
import 'data/local/service_local_data_source.dart';
import 'data/remote/stadium_services_remote_data_source.dart';
import 'data/local/stadium_services_local_data_source.dart';
import 'data/remote/entity_images_remote_data_source.dart';

// Add a BlocObserver for debugging
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (bloc is AuthBloc) {
      print(
          '🔐 AuthBloc state changed: ${change.currentState} -> ${change.nextState}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('⚠️ Bloc error: $error');
    super.onError(bloc, error, stackTrace);
  }
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set up the BlocObserver for debugging
  if (!kReleaseMode) {
    Bloc.observer = AppBlocObserver();
  }

  if (kReleaseMode) {
    // Only initialize Sentry in release mode
    await SentryFlutter.init(
      (options) {
        options.dsn =
            'https://f08a0f9192ba233576994b69bf421a11@o4509162206199808.ingest.de.sentry.io/4509163025530960';
        // Adds request headers and IP for users
        options.sendDefaultPii = true;
        // Set a custom release name
        options.release = 'manage_malaebna@1.0.0';
        // Enable performance tracking
        options.tracesSampleRate = 1.0;

        // Configure Session Replay
        options.experimental.replay.sessionSampleRate = 1.0;
        options.experimental.replay.onErrorSampleRate = 1.0;
      },
      appRunner: () async {
        // Initialize Supabase
        await Supabase.initialize(
          url: AppConstants.supabaseUrl,
          anonKey: AppConstants.supabaseAnonKey,
        );

        // Initialize localization service
        await LocalizationService().init();

        // Initialize translation service
        await TranslationService().init();

        // Initialize security helper to ensure data filtering by stadium
        await SecurityHelper.init();

        runApp(SentryWidget(child: MyApp()));
      },
    );
  } else {
    // In debug mode, just run the app normally
    // Initialize Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    // Initialize localization service
    await LocalizationService().init();

    // Initialize translation service
    await TranslationService().init();

    // Initialize security helper to ensure data filtering by stadium
    await SecurityHelper.init();

    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = Supabase.instance.client;
    final connectivity = Connectivity();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) {
            try {
              return ThemeBloc()..add(ThemeInitialEvent());
            } catch (e) {
              print('❌ Error initializing ThemeBloc: $e');
              // Fallback to a default theme if there's an error
              return ThemeBloc();
            }
          },
        ),
        BlocProvider<LocalizationBloc>(
          create: (context) =>
              LocalizationBloc()..add(LocalizationInitialEvent()),
        ),
        BlocProvider<OnboardingBloc>(
          create: (context) =>
              OnboardingBloc()..add(OnboardingCheckCompletionEvent()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            // Print debug info about AuthBloc creation
            print('🔐 Creating AuthBloc and dispatching initial event');
            final bloc = AuthBloc();
            // Initialize with check login status event to ensure authentication state is loaded
            bloc.add(const AuthCheckLoginStatusEvent());
            return bloc;
          },
        ),
      ],
      child: MultiRepositoryProvider(
        providers: _registerRepositories(supabaseClient, connectivity),
        child: const AppWrapper(),
      ),
    );
  }

  // Register all repositories for dependency injection
  List<RepositoryProvider> _registerRepositories(
      SupabaseClient supabaseClient, Connectivity connectivity) {
    return [
      // Payment Repository
      RepositoryProvider<PaymentRepository>(
        create: (context) => PaymentRepository(
          remoteDataSource: PaymentRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: PaymentLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Service Repository
      RepositoryProvider<ServiceRepository>(
        create: (context) => ServiceRepository(
          remoteDataSource: ServiceRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: ServiceLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Stadium Services Repository
      RepositoryProvider<StadiumServicesRepository>(
        create: (context) => StadiumServicesRepository(
          remoteDataSource: StadiumServicesRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: StadiumServicesLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Stadium Repository
      RepositoryProvider<StadiumRepository>(
        create: (context) => StadiumRepository(),
      ),

      // Address Repository
      RepositoryProvider<AddressRepository>(
        create: (context) => AddressRepository(),
      ),

      // Working Hours Repository
      RepositoryProvider<WorkingHoursRepository>(
        create: (context) => WorkingHoursRepository(
          remoteDataSource: WorkingHoursRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: WorkingHoursLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Time Off Repository
      RepositoryProvider<TimeOffRepository>(
        create: (context) => TimeOffRepository(
          remoteDataSource: TimeOffRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: TimeOffLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Match Repository
      RepositoryProvider<MatchRepository>(
        create: (context) => MatchRepository(
          remoteDataSource: MatchRemoteDataSource(),
          localDataSource: MatchLocalDataSource(),
        ),
      ),

      // Booking Repository
      RepositoryProvider<BookingRepository>(
        create: (context) => BookingRepository(
          remoteDataSource: BookingRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: BookingLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Match History Repository
      RepositoryProvider<MatchHistoryRepository>(
        create: (context) => MatchHistoryRepository(
          remoteDataSource: MatchHistoryRemoteDataSource(),
          localDataSource: MatchHistoryLocalDataSource(),
        ),
      ),

      // Field Repository
      RepositoryProvider<FieldRepository>(
        create: (context) => FieldRepository(
          remoteDataSource: FieldRemoteDataSource(
            supabaseClient: supabaseClient,
          ),
          localDataSource: FieldLocalDataSource(),
          connectivity: connectivity,
        ),
      ),

      // Entity Images Repository
      RepositoryProvider<EntityImagesRepository>(
        create: (context) => EntityImagesRepository(
          remoteDataSource: EntityImagesRemoteDataSource(
            supabaseClient: supabaseClient,
            networkInfo: NetworkInfo(connectivity),
            tableName: 'entity_images',
          ),
        ),
      ),
    ];
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Sync images from Supabase on app start
    _syncImagesFromSupabase();
  }

  Future<void> _syncImagesFromSupabase() async {
    // Delay slightly to let the app finish initializing
    await Future.delayed(const Duration(seconds: 2));

    try {
      print('Initializing image sync from Supabase');
      final authBloc = context.read<AuthBloc>();

      // Only sync if the user is authenticated
      if (authBloc.state.isAuthenticated && authBloc.state.userId != null) {
        final stadiumId = authBloc.state.userId;
        final entityImagesRepository = context.read<EntityImagesRepository>();

        // Sync images for the current stadium
        if (stadiumId != null) {
          print('Syncing images for stadium: $stadiumId');
          await entityImagesRepository.syncAllStadiumImages([stadiumId]);
        }
      } else {
        print('Skipping image sync - user not authenticated');
      }
    } catch (e) {
      print('Error during image sync initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, localizationState) {
            return MaterialApp(
              title: 'Manage Malaebna',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getLightTheme(),
              darkTheme: AppTheme.getDarkTheme(),
              themeMode: themeState.themeMode,
              locale: localizationState.locale,
              supportedLocales: const [
                Locale('en'), // English
                Locale('ar'), // Arabic
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return child ?? const SizedBox.shrink();
              },
              navigatorObservers: const [],
              home: BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, onboardingState) {
                  return BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, authState) {
                      if (!onboardingState.isCompleted) {
                        return const OnboardingScreen();
                      } else if (authState.isAuthenticated) {
                        return const MainScreen();
                      } else {
                        return const LoginScreen();
                      }
                    },
                  );
                },
              ),
              routes: AppRoutes.routes,
              onGenerateRoute: AppRoutes.onGenerateRoute,
            );
          },
        );
      },
    );
  }
}
