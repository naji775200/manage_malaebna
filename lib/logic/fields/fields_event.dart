import 'package:equatable/equatable.dart';

abstract class FieldsEvent extends Equatable {
  const FieldsEvent();

  @override
  List<Object> get props => [];
}

class LoadFields extends FieldsEvent {
  const LoadFields();
}

class RefreshFields extends FieldsEvent {
  const RefreshFields();
}

class AddField extends FieldsEvent {
  final Map<String, dynamic> fieldData;

  const AddField(this.fieldData);

  @override
  List<Object> get props => [fieldData];
}

class UpdateField extends FieldsEvent {
  final dynamic fieldId;
  final Map<String, dynamic> fieldData;

  const UpdateField(this.fieldId, this.fieldData);

  @override
  List<Object> get props => [fieldId, fieldData];
}

class DeleteField extends FieldsEvent {
  final dynamic fieldId;

  const DeleteField(this.fieldId);

  @override
  List<Object> get props => [fieldId];
}
