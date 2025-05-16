import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationTabChanged extends NavigationEvent {
  final int tabIndex;

  const NavigationTabChanged(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}

class NavigateToHomeTab extends NavigationEvent {}

class NavigateToFieldsTab extends NavigationEvent {}

class NavigateToRequestsTab extends NavigationEvent {}

class NavigateToReportsTab extends NavigationEvent {}

class NavigateToProfileTab extends NavigationEvent {}
