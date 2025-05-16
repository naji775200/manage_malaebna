import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../logic/working_hours/working_hours_bloc.dart';
import '../../../logic/working_hours/working_hours_event.dart';
import '../../../logic/working_hours/working_hours_state.dart';
import '../../../logic/working_hours/time_off_bloc.dart';
import '../../../logic/working_hours/time_off_event.dart';
import '../../../logic/working_hours/time_off_state.dart';
import '../../../core/constants/theme.dart';
import '../../../core/services/translation_service.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_button.dart';
import '../../../data/repositories/working_hours_repository.dart';
import '../../../data/repositories/time_off_repository.dart';
import '../../../logic/auth/auth_bloc.dart';

class WorkingHoursScreen extends StatelessWidget {
  final String stadiumId;
  final String stadiumName;

  const WorkingHoursScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
  });

  @override
  Widget build(BuildContext context) {
    print(
        'WorkingHoursScreen: Building with passed stadium ID: $stadiumId, name: $stadiumName');

    // IMPORTANT: We'll use SharedPreferences to get the actual UUID directly
    // This is to avoid the issue where incorrect IDs are being passed to this screen
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = snapshot.data!;
        final actualStadiumId = prefs.getString(AuthBloc.keyUserId);

        // Print debug info
        print('=======================');
        print('Passed stadium ID: $stadiumId');
        print('SharedPreferences raw userId: $actualStadiumId');
        print('=======================');

        // If no valid ID found in SharedPreferences, show error
        if (actualStadiumId == null || actualStadiumId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                  '$stadiumName ${translationService.translate('working_hours.title', {}, context)}'),
            ),
            body: Center(
              child: Text(translationService.translate(
                  'working_hours.messages.login_required', {}, context)),
            ),
          );
        }

        // Use the actual stadium ID from SharedPreferences
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => WorkingHoursBloc(
                repository:
                    RepositoryProvider.of<WorkingHoursRepository>(context),
              )..add(LoadWorkingHoursEvent(stadiumId: actualStadiumId)),
            ),
            BlocProvider(
              create: (context) => TimeOffBloc(
                repository: RepositoryProvider.of<TimeOffRepository>(context),
              )..add(LoadTimeOffEvent(stadiumId: actualStadiumId)),
            ),
          ],
          child: DefaultTabController(
            length: 2,
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                title: Text(translationService.translate(
                    'working_hours.title', {}, context)),
                bottom: TabBar(
                  tabs: [
                    Tab(
                        text: translationService.translate(
                            'working_hours.title', {}, context)),
                    Tab(
                        text: translationService.translate(
                            'working_hours.time_off.title', {}, context)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _WorkingHoursTab(stadiumId: actualStadiumId),
                  _TimeOffTab(stadiumId: actualStadiumId),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to get stadium ID from SharedPreferences
  static Future<String?> getStadiumIdFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the userId with the correct key from AuthBloc
      final userId = prefs
          .getString(AuthBloc.keyUserId); // This is 'userId', not 'keyUserId'
      final userType = prefs.getString(AuthBloc.keyUserType);

      print(
          'WorkingHoursScreen: Retrieving stadium ID for user: $userId (type: $userType)');

      if (userId == null || userId.isEmpty) {
        print('WorkingHoursScreen: No user ID found in SharedPreferences');
        return null;
      }

      if (userType != 'stadium') {
        print(
            'WorkingHoursScreen: User is not a stadium manager (type: $userType)');
        return null;
      }

      // The stadium ID is exactly the same as the user ID
      // No need to format to UUID or convert - just use it directly
      print('WorkingHoursScreen: Using user ID as stadium ID: $userId');
      return userId;
    } catch (e) {
      print('WorkingHoursScreen: Error getting stadium ID from prefs: $e');
      return null;
    }
  }
}

class _WorkingHoursTab extends StatefulWidget {
  final String stadiumId;

  const _WorkingHoursTab({
    required this.stadiumId,
  });

  @override
  _WorkingHoursTabState createState() => _WorkingHoursTabState();
}

class _WorkingHoursTabState extends State<_WorkingHoursTab> {
  // Value notifiers for reactive UI
  final ValueNotifier<List<bool>> _isCheckedNotifier =
      ValueNotifier<List<bool>>([]);
  final ValueNotifier<List<TimeOfDay>> _startTimesNotifier =
      ValueNotifier<List<TimeOfDay>>([]);
  final ValueNotifier<List<TimeOfDay>> _endTimesNotifier =
      ValueNotifier<List<TimeOfDay>>([]);
  final ValueNotifier<bool> _hasUnsavedChanges = ValueNotifier<bool>(false);

  List<String> _daysOfWeek = [];

  @override
  void dispose() {
    _isCheckedNotifier.dispose();
    _startTimesNotifier.dispose();
    _endTimesNotifier.dispose();
    _hasUnsavedChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkingHoursBloc, WorkingHoursState>(
      listener: (context, state) {
        // Handle successful save
        if (state is WorkingHoursLoaded && _hasUnsavedChanges.value) {
          _hasUnsavedChanges.value = false;
          CustomSnackBar.showSuccess(
            context,
            translationService.translate(
                'working_hours.messages.saved', {}, context),
          );
        }

        // Handle error while saving
        if (state is WorkingHoursError) {
          CustomSnackBar.showError(
            context,
            '${translationService.translate('working_hours.messages.save_error', {}, context)}: ${state.message}',
          );
        }
      },
      builder: (context, state) {
        if (state is WorkingHoursLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorkingHoursError && state is! WorkingHoursSaving) {
          return Center(
              child: Text(
                  '${translationService.translate('working_hours.messages.error', {}, context)}: ${state.message}'));
        } else if (state is WorkingHoursLoaded || state is WorkingHoursSaving) {
          // Initialize notifiers if state is WorkingHoursLoaded
          if (state is WorkingHoursLoaded && _isCheckedNotifier.value.isEmpty) {
            _isCheckedNotifier.value = List<bool>.from(state.isChecked);
            _startTimesNotifier.value = List<TimeOfDay>.from(state.startTimes);
            _endTimesNotifier.value = List<TimeOfDay>.from(state.endTimes);
            _daysOfWeek = state.daysOfWeek;
          }

          return _buildWorkingHoursForm(context, state);
        }
        return Center(
            child: Text(translationService.translate(
                'common.not_available', {}, context)));
      },
    );
  }

  void updateDay(int index,
      {bool? checked, TimeOfDay? newStartTime, TimeOfDay? newEndTime}) {
    if (checked != null) {
      final newList = List<bool>.from(_isCheckedNotifier.value);
      newList[index] = checked;
      _isCheckedNotifier.value = newList;
      _hasUnsavedChanges.value = true;
    }

    if (newStartTime != null) {
      final newList = List<TimeOfDay>.from(_startTimesNotifier.value);
      newList[index] = newStartTime;
      _startTimesNotifier.value = newList;
      _hasUnsavedChanges.value = true;
    }

    if (newEndTime != null) {
      final newList = List<TimeOfDay>.from(_endTimesNotifier.value);
      newList[index] = newEndTime;
      _endTimesNotifier.value = newList;
      _hasUnsavedChanges.value = true;
    }
  }

  void saveChanges() {
    try {
      // Validate data before saving
      if (_isCheckedNotifier.value.isEmpty || _daysOfWeek.isEmpty) {
        print("Working hours data is invalid - No days found");
        CustomSnackBar.showError(
          context,
          translationService.translate(
              'working_hours.messages.invalid_data', {}, context),
        );
        return;
      }

      // Debug logs
      print("Saving working hours for stadium: ${widget.stadiumId}");
      print("Days of week: $_daysOfWeek");
      print("Is checked values: ${_isCheckedNotifier.value}");
      print(
          "Start times: ${_startTimesNotifier.value.map((t) => '${t.hour}:${t.minute}').join(', ')}");
      print(
          "End times: ${_endTimesNotifier.value.map((t) => '${t.hour}:${t.minute}').join(', ')}");

      // Dispatch the event
      final bloc = BlocProvider.of<WorkingHoursBloc>(context);
      bloc.add(
        UpdateWorkingHoursEvent(
          isChecked: _isCheckedNotifier.value,
          startTimes: _startTimesNotifier.value,
          endTimes: _endTimesNotifier.value,
          daysOfWeek: _daysOfWeek,
          stadiumId: widget.stadiumId,
        ),
      );
    } catch (e) {
      print("Error saving working hours: $e");
      CustomSnackBar.showError(
        context,
        "${translationService.translate('working_hours.messages.save_error', {}, context)}: $e",
      );
    }
  }

  Widget _buildWorkingHoursForm(BuildContext context, WorkingHoursState state) {
    final Map<String, String> translatedDays = {
      'Monday': translationService.translate(
          'working_hours.days.monday', {}, context),
      'Tuesday': translationService.translate(
          'working_hours.days.tuesday', {}, context),
      'Wednesday': translationService.translate(
          'working_hours.days.wednesday', {}, context),
      'Thursday': translationService.translate(
          'working_hours.days.thursday', {}, context),
      'Friday': translationService.translate(
          'working_hours.days.friday', {}, context),
      'Saturday': translationService.translate(
          'working_hours.days.saturday', {}, context),
      'Sunday': translationService.translate(
          'working_hours.days.sunday', {}, context),
    };

    // Check if currently saving
    final isSaving = state is WorkingHoursSaving;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translationService.translate(
                    'working_hours.subtitle', {}, context),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _daysOfWeek.length,
                  itemBuilder: (context, index) {
                    return ValueListenableBuilder<List<bool>>(
                      valueListenable: _isCheckedNotifier,
                      builder: (context, isChecked, _) {
                        return ValueListenableBuilder<List<TimeOfDay>>(
                          valueListenable: _startTimesNotifier,
                          builder: (context, startTimes, _) {
                            return ValueListenableBuilder<List<TimeOfDay>>(
                              valueListenable: _endTimesNotifier,
                              builder: (context, endTimes, _) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            translatedDays[
                                                    _daysOfWeek[index]] ??
                                                _daysOfWeek[index],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Checkbox(
                                          value: isChecked[index],
                                          onChanged: (value) {
                                            updateDay(index, checked: value);
                                          },
                                          activeColor: AppTheme.primaryColor,
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: GestureDetector(
                                            onTap: isChecked[index]
                                                ? () => _selectTime(
                                                      context,
                                                      startTimes[index],
                                                      (time) {
                                                        updateDay(index,
                                                            newStartTime: time);
                                                      },
                                                    )
                                                : null,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isChecked[index]
                                                    ? AppTheme
                                                        .lightBackgroundColor
                                                    : Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                startTimes[index]
                                                    .format(context),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isChecked[index]
                                                      ? Colors.black
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(translationService.translate(
                                            'working_hours.to', {}, context)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 4,
                                          child: GestureDetector(
                                            onTap: isChecked[index]
                                                ? () => _selectTime(
                                                      context,
                                                      endTimes[index],
                                                      (time) {
                                                        updateDay(index,
                                                            newEndTime: time);
                                                      },
                                                    )
                                                : null,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                                horizontal: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isChecked[index]
                                                    ? AppTheme
                                                        .lightBackgroundColor
                                                    : Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                endTimes[index].format(context),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isChecked[index]
                                                      ? Colors.black
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: _hasUnsavedChanges,
                builder: (context, hasChanges, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasChanges && !isSaving)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            translationService.translate(
                                'working_hours.unsaved_changes', {}, context),
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      CustomButton(
                        text: translationService.translate(
                            'common.save', {}, context),
                        variant: CustomButtonVariant.primary,
                        size: CustomButtonSize.large,
                        isFullWidth: true,
                        leadingIcon: Icons.save,
                        onPressed:
                            (hasChanges && !isSaving) ? saveChanges : null,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        // Overlay loading indicator when saving
        if (isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(translationService.translate(
                          'working_hours.messages.saving', {}, context)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      onTimeSelected(pickedTime);
    }
  }
}

class _TimeOffTab extends StatefulWidget {
  final String stadiumId;

  const _TimeOffTab({
    required this.stadiumId,
  });

  @override
  State<_TimeOffTab> createState() => _TimeOffTabState();
}

class _TimeOffTabState extends State<_TimeOffTab> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  DateTime? _specificDate;
  String _frequency = 'Once';
  String? _dayOfWeek;
  bool _isAddingTimeOff = false;
  bool _isDeletingTimeOff = false;

  // Add a list to track multiple selected days
  final List<bool> _selectedDays =
      List.generate(7, (_) => false); // [Monday to Sunday]
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TimeOffBloc, TimeOffState>(
      listener: (context, state) {
        if (state is TimeOffError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is TimeOffLoaded && _isAddingTimeOff) {
          // This means we've successfully added a time off (the state has loaded new data)
          _isAddingTimeOff = false;
          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(translationService.translate(
                  'working_hours.time_off.save_success', {}, context)),
              backgroundColor: Colors.green,
            ),
          );
          // Reset form fields
          _resetForm();
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title section
                Text(
                  translationService.translate(
                      'working_hours.time_off.subtitle', {}, context),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Form section
                _buildAddTimeOffForm(context, state),

                const SizedBox(height: 16),

                // List section
                if (state is TimeOffLoaded && state.timeOffs.isNotEmpty)
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.4, // Use fixed height for list
                    child: _buildTimeOffList(context, state),
                  ),

                if (state is TimeOffLoaded && state.timeOffs.isEmpty)
                  Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text(
                      translationService.translate(
                          'working_hours.time_off.no_time_off', {}, context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // Add some bottom padding for keyboard
                SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom > 0
                        ? 250
                        : 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTimeOffForm(BuildContext context, TimeOffState state) {
    bool isSaving = state is TimeOffSaving;

    return Column(
      mainAxisSize: MainAxisSize.min, // Use minimal height
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title input field
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: translationService.translate(
                'working_hours.time_off.title', {}, context),
            border: const OutlineInputBorder(),
            enabled: !isSaving,
          ),
        ),
        const SizedBox(height: 16),

        // Time selectors
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                context,
                translationService.translate(
                    'working_hours.time.start', {}, context),
                _startTime,
                (value) {
                  setState(() {
                    _startTime = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                context,
                translationService.translate(
                    'working_hours.time.end', {}, context),
                _endTime,
                (value) {
                  setState(() {
                    _endTime = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Frequency selector
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: translationService.translate(
                'working_hours.time_off.frequency', {}, context),
            border: const OutlineInputBorder(),
          ),
          value: _frequency,
          items: [
            DropdownMenuItem(
              value: 'Once',
              child: Text(
                translationService.translate(
                    'working_hours.frequency.once', {}, context),
              ),
            ),
            DropdownMenuItem(
              value: 'Daily',
              child: Text(
                translationService.translate(
                    'working_hours.frequency.daily', {}, context),
              ),
            ),
            DropdownMenuItem(
              value: 'Weekly',
              child: Text(
                translationService.translate(
                    'working_hours.frequency.weekly', {}, context),
              ),
            ),
          ],
          onChanged: isSaving
              ? null
              : (value) {
                  setState(() {
                    _frequency = value!;
                    // Reset conditional fields
                    _dayOfWeek = null;
                    _specificDate = null;

                    // Reset selected days when changing frequency
                    if (value != 'Weekly') {
                      for (int i = 0; i < _selectedDays.length; i++) {
                        _selectedDays[i] = false;
                      }
                    }
                  });
                },
        ),
        const SizedBox(height: 16),

        // Conditional fields based on frequency
        if (_frequency == 'Weekly')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                translationService.translate(
                    'working_hours.time_off.select_days', {}, context),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    _daysOfWeek.length,
                    (index) => FilterChip(
                      selected: _selectedDays[index],
                      label:
                          Text(_getTranslatedDay(context, _daysOfWeek[index])),
                      onSelected: (selected) {
                        setState(() {
                          _selectedDays[index] = selected;
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (_frequency == 'Once')
          _buildDateSelector(
            context,
            translationService.translate(
                'working_hours.time_off.date', {}, context),
            _specificDate ?? DateTime.now(),
            (date) {
              setState(() {
                _specificDate = date;
              });
            },
          ),

        const SizedBox(height: 24),

        // Save button
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text:
                translationService.translate('working_hours.save', {}, context),
            leadingIcon: Icons.add,
            isLoading: isSaving,
            onPressed: isSaving ? null : saveTimeOff,
            variant: CustomButtonVariant.primary,
            size: CustomButtonSize.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeOffList(BuildContext context, TimeOffState state) {
    if (state is TimeOffLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is TimeOffError) {
      return Center(
          child: Text(
              '${translationService.translate('working_hours.messages.error', {}, context)}: ${state.message}'));
    } else if (state is TimeOffLoaded) {
      final timeOffs = state.timeOffs;
      if (timeOffs.isEmpty) {
        return Center(
            child: Text(translationService.translate(
                'working_hours.time_off.empty_state', {}, context)));
      }
      return ListView.builder(
        itemCount: timeOffs.length,
        itemBuilder: (context, index) {
          final timeOff = timeOffs[index];

          // Debug log days of week for this time off
          print(
              'TimeOffScreen: Time off "${timeOff.title}" has days: ${timeOff.daysOfWeek}');

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(timeOff.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${translationService.translate('working_hours.time.start', {}, context)}: ${DateFormat.jm().format(
                      DateTime(2022, 1, 1, timeOff.startTimeOff.hour,
                          timeOff.startTimeOff.minute),
                    )} ${translationService.translate('to', {}, context)} ${DateFormat.jm().format(
                      DateTime(2022, 1, 1, timeOff.endTimeOff.hour,
                          timeOff.endTimeOff.minute),
                    )}',
                  ),
                  Text(
                      '${translationService.translate('working_hours.time_off.frequency', {}, context)}: ${_getTranslatedFrequency(context, timeOff.frequency)}'),
                  // Display days of week for weekly frequency
                  if (timeOff.frequency == 'Weekly')
                    Text(
                      '${translationService.translate('working_hours.time_off.days_of_week', {}, context)}: ${_formatDaysOfWeek(context, timeOff.daysOfWeek)}',
                    ),
                  // Display single day for other frequencies if available
                  if (timeOff.frequency != 'Weekly' &&
                      timeOff.daysOfWeek.isNotEmpty)
                    Text(
                      '${translationService.translate('working_hours.time_off.day_of_week', {}, context)}: ${_getTranslatedDay(context, timeOff.daysOfWeek.first)}',
                    ),
                  if (timeOff.specificDate != null)
                    Text(
                        '${translationService.translate('working_hours.time_off.date', {}, context)}: ${DateFormat.yMMMd().format(timeOff.specificDate!)}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: AppTheme.secondaryColor),
                tooltip: translationService.translate('delete', {}, context),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(translationService.translate(
                          'common.delete', {}, context)),
                      content: Text(translationService.translate(
                          'working_hours.time_off.delete_confirm',
                          {},
                          context)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(translationService.translate(
                              'common.cancel', {}, context)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            // Set the flag to indicate we're deleting a time off
                            _isDeletingTimeOff = true;
                            BlocProvider.of<TimeOffBloc>(context).add(
                              DeleteTimeOffEvent(
                                stadiumId: widget.stadiumId,
                                timeOffId: timeOff.ID,
                              ),
                            );
                          },
                          child: Text(translationService.translate(
                              'common.delete', {}, context)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    }
    return Center(
        child: Text(
            translationService.translate('common.not_available', {}, context)));
  }

  String _getTranslatedFrequency(BuildContext context, String frequency) {
    switch (frequency) {
      case 'Once':
        return translationService.translate(
            'working_hours.frequency.once', {}, context);
      case 'Daily':
        return translationService.translate(
            'working_hours.frequency.daily', {}, context);
      case 'Weekly':
        return translationService.translate(
            'working_hours.frequency.weekly', {}, context);
      default:
        return frequency;
    }
  }

  String _getTranslatedDay(BuildContext context, String day) {
    switch (day) {
      case 'Monday':
        return translationService.translate(
            'working_hours.days.monday', {}, context);
      case 'Tuesday':
        return translationService.translate(
            'working_hours.days.tuesday', {}, context);
      case 'Wednesday':
        return translationService.translate(
            'working_hours.days.wednesday', {}, context);
      case 'Thursday':
        return translationService.translate(
            'working_hours.days.thursday', {}, context);
      case 'Friday':
        return translationService.translate(
            'working_hours.days.friday', {}, context);
      case 'Saturday':
        return translationService.translate(
            'working_hours.days.saturday', {}, context);
      case 'Sunday':
        return translationService.translate(
            'working_hours.days.sunday', {}, context);
      default:
        return day;
    }
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          onTimeSelected(pickedTime);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime date,
    Function(DateTime) onDateSelected,
  ) {
    return GestureDetector(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(DateFormat.yMMMd().format(date)),
      ),
    );
  }

  saveTimeOff() {
    try {
      if (_titleController.text.isEmpty) {
        CustomSnackBar.showWarning(
            context,
            translationService.translate(
                'working_hours.validation.enter_title', {}, context));
        return;
      }

      if (_frequency == 'Weekly') {
        // Check if any day is selected
        bool anyDaySelected = _selectedDays.any((day) => day);
        if (!anyDaySelected) {
          CustomSnackBar.showWarning(
              context,
              translationService.translate(
                  'working_hours.validation.select_day', {}, context));
          return;
        }
      }

      if (_frequency == 'Once' && _specificDate == null) {
        CustomSnackBar.showWarning(
            context,
            translationService.translate(
                'working_hours.validation.select_date', {}, context));
        return;
      }

      // Debug logs
      print("Saving time off for stadium: ${widget.stadiumId}");
      print("Title: ${_titleController.text}");
      print("Frequency: $_frequency");
      print("Start time: ${_startTime.format(context)}");
      print("End time: ${_endTime.format(context)}");

      // Set the flag to indicate we're adding a time off
      _isAddingTimeOff = true;

      // For Weekly frequency, collect all selected days
      List<String> selectedDaysList = [];
      if (_frequency == 'Weekly') {
        for (int i = 0; i < _selectedDays.length; i++) {
          if (_selectedDays[i]) {
            selectedDaysList.add(_daysOfWeek[i]);
          }
        }
        print("Selected days: $selectedDaysList");
      }

      // Create a single SaveTimeOffEvent with all the necessary data
      BlocProvider.of<TimeOffBloc>(context).add(
        SaveTimeOffEvent(
          stadiumId: widget.stadiumId,
          title: _titleController.text,
          startTime: _startTime,
          endTime: _endTime,
          frequency: _frequency,
          dayOfWeek: _frequency == 'Weekly'
              ? null
              : _dayOfWeek, // Only used for non-Weekly frequencies
          specificDate: _specificDate,
          selectedDays: _frequency == 'Weekly'
              ? selectedDaysList
              : [], // Pass all selected days for Weekly frequency
        ),
      );

      _resetForm();
    } catch (e) {
      print("Error saving time off: $e");
      CustomSnackBar.showError(
        context,
        "${translationService.translate('working_hours.messages.save_error', {}, context)}: $e",
      );
    }
  }

  void _resetForm() {
    _titleController.clear();
    setState(() {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _frequency = 'Once';
      _dayOfWeek = null;
      _specificDate = null;
      // Reset selected days
      for (int i = 0; i < _selectedDays.length; i++) {
        _selectedDays[i] = false;
      }
    });
  }

  // Add a method to format days of week for display
  String _formatDaysOfWeek(BuildContext context, List<String> days) {
    if (days.isEmpty) {
      return translationService.translate(
          'working_hours.time_off.no_days_selected', {}, context);
    }

    return days.map((day) => _getTranslatedDay(context, day)).join(', ');
  }
}
