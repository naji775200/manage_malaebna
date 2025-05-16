import 'package:equatable/equatable.dart';
import '../../data/models/field_model.dart';

enum FieldsStatus { initial, loading, success, failure }

class FieldsState extends Equatable {
  final FieldsStatus status;
  final List<Field> fields;
  final String? errorMessage;
  final bool isRefreshing;

  const FieldsState({
    this.status = FieldsStatus.initial,
    this.fields = const [],
    this.errorMessage,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
        status,
        fields,
        errorMessage,
        isRefreshing,
      ];

  FieldsState copyWith({
    FieldsStatus? status,
    List<Field>? fields,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return FieldsState(
      status: status ?? this.status,
      fields: fields ?? this.fields,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  // Helper getters
  bool get isInitial => status == FieldsStatus.initial;
  bool get isLoading => status == FieldsStatus.loading;
  bool get isSuccess => status == FieldsStatus.success;
  bool get isError => status == FieldsStatus.failure;
  bool get hasFields => fields.isNotEmpty;
}
