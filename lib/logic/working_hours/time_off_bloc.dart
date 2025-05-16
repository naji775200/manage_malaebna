import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/time_off_model.dart' as model;
import '../../data/repositories/time_off_repository.dart';
import '../../core/utils/auth_utils.dart';
import 'time_off_event.dart';
import 'time_off_state.dart';

class TimeOffBloc extends Bloc<TimeOffEvent, TimeOffState> {
  final TimeOffRepository _repository;
  final _uuid = const Uuid();
  String? _currentStadiumId;

  TimeOffBloc({required TimeOffRepository repository})
      : _repository = repository,
        super(TimeOffInitial()) {
    on<LoadTimeOffEvent>(_onLoadTimeOff);
    on<SaveTimeOffEvent>(_onSaveTimeOff);
    on<DeleteTimeOffEvent>(_onDeleteTimeOff);
  }

  void _onLoadTimeOff(
      LoadTimeOffEvent event, Emitter<TimeOffState> emit) async {
    try {
      emit(TimeOffLoading());

      // If a stadiumId is provided, use it; otherwise, try to get it from SharedPreferences
      String? stadiumId;
      if (event.stadiumId.isNotEmpty) {
        stadiumId = await AuthUtils.ensureValidUuid(event.stadiumId);
      } else {
        stadiumId = await AuthUtils.getStadiumIdFromAuth();
      }

      if (stadiumId == null || stadiumId.isEmpty) {
        emit(const TimeOffError(message: 'Invalid or missing stadium ID'));
        return;
      }

      // Store the current stadium ID for reuse
      _currentStadiumId = stadiumId;
      print('TimeOffBloc: Working with stadium ID: $stadiumId');

      // Get time offs from repository
      final timeOffs = await _repository.getTimeOffsByStadiumId(stadiumId);
      print('TimeOffBloc: Loaded ${timeOffs.length} time off records');

      // Debug log all time offs days of week
      for (var timeOff in timeOffs) {
        print(
            'TimeOffBloc: Time off "${timeOff.title}" has days: ${timeOff.daysOfWeek}');
      }

      // Convert model TimeOff objects to state TimeOff objects
      final stateTimeOffs = timeOffs.map((timeOff) {
        return TimeOff(
          ID: timeOff.id,
          title: timeOff.title,
          startTimeOff: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            timeOff.startTime.hour,
            timeOff.startTime.minute,
          ),
          endTimeOff: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            timeOff.endTime.hour,
            timeOff.endTime.minute,
          ),
          frequency: timeOff.frequency,
          // Pass the full list of days instead of just the first one
          daysOfWeek: timeOff.daysOfWeek,
          specificDate: timeOff.specificDate,
        );
      }).toList();

      emit(TimeOffLoaded(timeOffs: stateTimeOffs));
    } catch (e) {
      emit(TimeOffError(message: 'Failed to load time off: $e'));
      print('TimeOffBloc: Error loading time off: $e');
    }
  }

  void _onSaveTimeOff(
      SaveTimeOffEvent event, Emitter<TimeOffState> emit) async {
    try {
      emit(TimeOffSaving());

      // Use provided stadium ID if valid
      String stadiumId = event
          .stadiumId; // This is never null since it's required in the event
      print('TimeOffBloc: Saving time off for stadium ID: $stadiumId');

      // Generate a new UUID for the time off record
      final id = AuthUtils.generateUuid();
      print('TimeOffBloc: Generated time off ID: $id');

      // Determine the days of week to use
      List<String> daysOfWeekList = [];
      if (event.frequency == 'Weekly') {
        // For Weekly frequency, use the provided selectedDays list
        daysOfWeekList =
            event.selectedDays.map((day) => day.toString()).toList();
        print(
            'TimeOffBloc: Weekly frequency with selected days: $daysOfWeekList');
      } else if (event.dayOfWeek != null) {
        // For other frequencies, use the dayOfWeek field if available
        daysOfWeekList = [event.dayOfWeek!];
        print('TimeOffBloc: Single day frequency with day: ${event.dayOfWeek}');
      } else {
        print(
            'TimeOffBloc: No days selected for frequency: ${event.frequency}');
      }

      // Validate the list is not null
      if (daysOfWeekList.isEmpty && event.frequency == 'Weekly') {
        print('TimeOffBloc: WARNING - No days selected for weekly frequency!');
      }

      // Create a model TimeOff object
      final modelTimeOff = model.TimeOff(
        id: id,
        stadiumId: stadiumId,
        startTime: event.startTime,
        endTime: event.endTime,
        frequency: event.frequency,
        daysOfWeek: daysOfWeekList,
        specificDate: event.specificDate,
        title: event.title,
      );

      // Debug log for the time off object
      print('TimeOffBloc: Creating time off with:');
      print('- ID: ${modelTimeOff.id}');
      print('- Stadium ID: ${modelTimeOff.stadiumId}');
      print('- Title: ${modelTimeOff.title}');
      print('- Frequency: ${modelTimeOff.frequency}');
      print('- Days of Week: ${modelTimeOff.daysOfWeek}');
      print('- Specific Date: ${modelTimeOff.specificDate}');

      // Save to repository
      await _repository.createTimeOff(modelTimeOff);
      print(
          'TimeOffBloc: Time off saved successfully with days: ${daysOfWeekList.join(", ")}');

      // Reload time offs
      add(LoadTimeOffEvent(stadiumId: stadiumId));
    } catch (e) {
      emit(TimeOffError(message: 'Failed to save time off: $e'));
      print('TimeOffBloc: Error saving time off: $e');
    }
  }

  void _onDeleteTimeOff(
      DeleteTimeOffEvent event, Emitter<TimeOffState> emit) async {
    try {
      emit(TimeOffLoading());

      // Use provided stadium ID from event
      String stadiumId = event
          .stadiumId; // This is never null since it's required in the event

      print(
          'TimeOffBloc: Deleting time off (ID: ${event.timeOffId}) for stadium ID: $stadiumId');

      // Delete from repository
      await _repository.deleteTimeOff(event.timeOffId);
      print('TimeOffBloc: Time off deleted successfully');

      // Reload time offs
      add(LoadTimeOffEvent(stadiumId: stadiumId));
    } catch (e) {
      emit(TimeOffError(message: 'Failed to delete time off: $e'));
      print('TimeOffBloc: Error deleting time off: $e');
    }
  }
}
