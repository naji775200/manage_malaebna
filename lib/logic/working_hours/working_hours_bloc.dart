import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/working_hours_repository.dart';
import '../../data/models/working_hour_model.dart';
import '../../core/utils/auth_utils.dart';
import 'working_hours_event.dart';
import 'working_hours_state.dart';

class WorkingHoursBloc extends Bloc<WorkingHoursEvent, WorkingHoursState> {
  final WorkingHoursRepository _repository;
  String? _currentStadiumId;
  final _uuid = const Uuid();

  WorkingHoursBloc({required WorkingHoursRepository repository})
      : _repository = repository,
        super(WorkingHoursInitial()) {
    on<LoadWorkingHoursEvent>(_onLoadWorkingHours);
    on<UpdateWorkingHoursEvent>(_onUpdateWorkingHours);
  }

  void _onLoadWorkingHours(
      LoadWorkingHoursEvent event, Emitter<WorkingHoursState> emit) async {
    try {
      emit(WorkingHoursLoading());

      // If a stadiumId is provided, use it; otherwise, try to get it from SharedPreferences
      String? stadiumId;
      if (event.stadiumId.isNotEmpty) {
        stadiumId = await AuthUtils.ensureValidUuid(event.stadiumId);
      } else {
        stadiumId = await AuthUtils.getStadiumIdFromAuth();
      }

      if (stadiumId == null || stadiumId.isEmpty) {
        emit(const WorkingHoursError(message: 'Invalid or missing stadium ID'));
        return;
      }

      // Store the current stadium ID for later use
      _currentStadiumId = stadiumId;
      print('Working with stadium ID: $stadiumId');

      // Initialize default values for each day of the week
      final List<String> daysOfWeek = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];

      List<bool> isChecked = List.filled(daysOfWeek.length, false);
      List<TimeOfDay> startTimes =
          List.filled(daysOfWeek.length, const TimeOfDay(hour: 9, minute: 0));
      List<TimeOfDay> endTimes =
          List.filled(daysOfWeek.length, const TimeOfDay(hour: 17, minute: 0));

      // Get working hours from repository
      final workingHoursList =
          await _repository.getWorkingHoursByStadiumId(stadiumId);

      // Update the lists based on repository data
      for (var workingHours in workingHoursList) {
        // Find the index of the day in our daysOfWeek list
        int dayIndex = daysOfWeek.indexOf(workingHours.dayOfWeek);
        if (dayIndex != -1) {
          isChecked[dayIndex] = true;
          startTimes[dayIndex] = workingHours.startTime;
          endTimes[dayIndex] = workingHours.endTime;
        }
      }

      emit(WorkingHoursLoaded(
        isChecked: isChecked,
        startTimes: startTimes,
        endTimes: endTimes,
        daysOfWeek: daysOfWeek,
      ));
    } catch (e) {
      emit(WorkingHoursError(message: 'Failed to load working hours: $e'));
    }
  }

  void _onUpdateWorkingHours(
      UpdateWorkingHoursEvent event, Emitter<WorkingHoursState> emit) async {
    try {
      emit(WorkingHoursSaving(
        isChecked: event.isChecked,
        startTimes: event.startTimes,
        endTimes: event.endTimes,
        daysOfWeek: event.daysOfWeek,
      ));

      // Get stadium ID - try all possible sources
      String? stadiumId;

      // First check if we got a valid stadium ID from the event
      if (event.stadiumId != null && event.stadiumId!.isNotEmpty) {
        stadiumId = await AuthUtils.ensureValidUuid(event.stadiumId!);
      }
      // Otherwise use the stored ID
      else if (_currentStadiumId != null && _currentStadiumId!.isNotEmpty) {
        stadiumId = _currentStadiumId;
      }
      // If still no stadium ID, try to get it from auth
      else {
        stadiumId = await AuthUtils.getStadiumIdFromAuth();
      }

      // Final validation
      if (stadiumId == null || stadiumId.isEmpty) {
        emit(const WorkingHoursError(message: 'Stadium ID is required'));
        return;
      }

      print('Updating working hours for stadium ID: $stadiumId');

      // Create or update working hours for each day
      for (int i = 0; i < event.daysOfWeek.length; i++) {
        if (event.isChecked[i]) {
          // First try to get existing working hours for this day
          try {
            final existingWorkingHours =
                await _repository.getWorkingHoursByStadiumIdAndDay(
                    stadiumId, event.daysOfWeek[i]);

            if (existingWorkingHours != null) {
              // Update existing working hours
              final updatedWorkingHours = existingWorkingHours.copyWith(
                startTime: event.startTimes[i],
                endTime: event.endTimes[i],
              );
              await _repository.updateWorkingHours(updatedWorkingHours);
              print('Updated working hours for ${event.daysOfWeek[i]}');
            } else {
              // Create new working hours if none exist
              final uuid = AuthUtils.generateUuid();
              final newWorkingHours = WorkingHours(
                id: uuid,
                stadiumId: stadiumId,
                dayOfWeek: event.daysOfWeek[i],
                startTime: event.startTimes[i],
                endTime: event.endTimes[i],
              );
              await _repository.createWorkingHours(newWorkingHours);
              print(
                  'Created new working hours for ${event.daysOfWeek[i]} with ID: $uuid');
            }
          } catch (e) {
            // Create new working hours if there was an error
            final uuid = AuthUtils.generateUuid();
            final newWorkingHours = WorkingHours(
              id: uuid,
              stadiumId: stadiumId,
              dayOfWeek: event.daysOfWeek[i],
              startTime: event.startTimes[i],
              endTime: event.endTimes[i],
            );
            await _repository.createWorkingHours(newWorkingHours);
            print(
                'Created new working hours (after error) for ${event.daysOfWeek[i]} with ID: $uuid');
          }
        } else {
          // Delete working hours for unchecked days
          try {
            final existingWorkingHours =
                await _repository.getWorkingHoursByStadiumIdAndDay(
                    stadiumId, event.daysOfWeek[i]);

            if (existingWorkingHours != null) {
              await _repository.deleteWorkingHours(existingWorkingHours.id);
              print('Deleted working hours for ${event.daysOfWeek[i]}');
            }
          } catch (e) {
            // Ignore errors for deletion of non-existent records
            print('No working hours to delete for ${event.daysOfWeek[i]}');
          }
        }
      }

      // Reload working hours
      add(LoadWorkingHoursEvent(stadiumId: stadiumId));
    } catch (e) {
      emit(WorkingHoursError(message: 'Failed to update working hours: $e'));
    }
  }

  // Helper method to save working hours to both database and SharedPreferences
  Future<void> _saveWorkingHoursToDatabase(
    String stadiumId,
    List<String> daysOfWeek,
    List<bool> isChecked,
    List<TimeOfDay> startTimes,
    List<TimeOfDay> endTimes,
  ) async {
    print('Saving working hours to database for stadium ID: $stadiumId');

    try {
      // First get existing working hours to update or delete
      final existingWorkingHours =
          await _repository.getWorkingHoursByStadiumId(stadiumId);
      final existingWorkingHoursMap = {
        for (var wh in existingWorkingHours) wh.dayOfWeek: wh
      };

      // For each day of the week
      for (int i = 0; i < daysOfWeek.length; i++) {
        final dayOfWeek = daysOfWeek[i];
        final isActive = isChecked[i];
        final startTime = startTimes[i];
        final endTime = endTimes[i];

        // If the day is active, create or update the working hour
        if (isActive) {
          print('Processing working hours for $dayOfWeek: $startTime-$endTime');

          if (existingWorkingHoursMap.containsKey(dayOfWeek)) {
            // Update existing working hour
            final existingWorkingHour = existingWorkingHoursMap[dayOfWeek]!;
            final updatedWorkingHour = existingWorkingHour.copyWith(
              startTime: startTime,
              endTime: endTime,
            );

            print('Updating existing working hour: ${updatedWorkingHour.id}');
            await _repository.updateWorkingHours(updatedWorkingHour);
          } else {
            // Create new working hour with a proper UUID
            final newWorkingHour = WorkingHours(
              id: AuthUtils.generateUuid(), // Use AuthUtils to generate UUID
              stadiumId: stadiumId,
              startTime: startTime,
              endTime: endTime,
              dayOfWeek: dayOfWeek,
            );

            print(
                'Creating new working hour for $dayOfWeek with UUID: ${newWorkingHour.id}');
            await _repository.createWorkingHours(newWorkingHour);
          }
        } else if (existingWorkingHoursMap.containsKey(dayOfWeek)) {
          // If day is not active but exists in database, delete it
          print('Deleting working hour for $dayOfWeek');
          await _repository
              .deleteWorkingHours(existingWorkingHoursMap[dayOfWeek]!.id);
        }
      }

      print('Successfully saved all working hours to database');
    } catch (e) {
      print('Error saving working hours to database: $e');
      rethrow;
    }
  }

  // Helper method for backward compatibility
  Future<void> _saveToSharedPreferences(
    String stadiumId,
    List<bool> isChecked,
    List<TimeOfDay> startTimes,
    List<TimeOfDay> endTimes,
  ) async {
    try {
      final Map<String, dynamic> data = {
        'isChecked': isChecked,
        'startTimes': startTimes
            .map((t) => {'hour': t.hour, 'minute': t.minute})
            .toList(),
        'endTimes':
            endTimes.map((t) => {'hour': t.hour, 'minute': t.minute}).toList(),
      };

      final prefs = await SharedPreferences.getInstance();
      final key = 'stadium_working_hours_$stadiumId';
      final String jsonData = jsonEncode(data);
      await prefs.setString(key, jsonData);
      print('Also saved to SharedPreferences for backward compatibility');
    } catch (e) {
      print('Error saving to SharedPreferences: $e');
      // Don't rethrow as this is just for backward compatibility
    }
  }
}
