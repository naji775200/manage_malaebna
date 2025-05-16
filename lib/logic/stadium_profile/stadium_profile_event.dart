import 'package:equatable/equatable.dart';
import '../../data/models/stadium_model.dart';
import '../../data/models/address_model.dart';
import 'dart:io';

abstract class StadiumProfileEvent extends Equatable {
  const StadiumProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadStadiumProfile extends StadiumProfileEvent {
  final String? stadiumId;

  const LoadStadiumProfile({this.stadiumId});

  @override
  List<Object?> get props => [stadiumId];
}

class RefreshStadiumProfile extends StadiumProfileEvent {
  const RefreshStadiumProfile();
}

class UpdateStadiumProfile extends StadiumProfileEvent {
  final Stadium stadium;
  final Address? address;

  const UpdateStadiumProfile({
    required this.stadium,
    this.address,
  });

  @override
  List<Object?> get props => [stadium, address];
}

class UpdateStadiumAddress extends StadiumProfileEvent {
  final Address address;

  const UpdateStadiumAddress({
    required this.address,
  });

  @override
  List<Object?> get props => [address];
}

class UpdateStadiumProfileImage extends StadiumProfileEvent {
  final String stadiumId;
  final File imageFile;

  const UpdateStadiumProfileImage({
    required this.stadiumId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [stadiumId, imageFile];
}

class SearchServices extends StadiumProfileEvent {
  final String query;

  const SearchServices({required this.query});

  @override
  List<Object?> get props => [query];
}

class PerformSearchAction extends StadiumProfileEvent {
  final String query;

  const PerformSearchAction({required this.query});

  @override
  List<Object?> get props => [query];
}

class AddStadiumService extends StadiumProfileEvent {
  final String stadiumId;
  final String serviceId;

  const AddStadiumService({
    required this.stadiumId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [stadiumId, serviceId];
}

class RemoveStadiumService extends StadiumProfileEvent {
  final String stadiumId;
  final String serviceId;

  const RemoveStadiumService({
    required this.stadiumId,
    required this.serviceId,
  });

  @override
  List<Object?> get props => [stadiumId, serviceId];
}
