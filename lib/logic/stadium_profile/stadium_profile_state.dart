import 'package:equatable/equatable.dart';
import '../../data/models/stadium_model.dart';
import '../../data/models/address_model.dart';
import '../../data/models/service_model.dart';

enum StadiumProfileStatus { initial, loading, success, failure }

class StadiumProfileState extends Equatable {
  final StadiumProfileStatus status;
  final Stadium? stadium;
  final Address? address;
  final String? errorMessage;
  final bool isRefreshing;
  final bool updateComplete;
  final List<Service> searchResults;
  final bool isSearching;
  final String searchQuery;
  final String? profileImageUrl;
  final bool isUploadingImage;

  const StadiumProfileState({
    this.status = StadiumProfileStatus.initial,
    this.stadium,
    this.address,
    this.errorMessage,
    this.isRefreshing = false,
    this.updateComplete = false,
    this.searchResults = const [],
    this.isSearching = false,
    this.searchQuery = '',
    this.profileImageUrl,
    this.isUploadingImage = false,
  });

  @override
  List<Object?> get props => [
        status,
        stadium,
        address,
        errorMessage,
        isRefreshing,
        updateComplete,
        searchResults,
        isSearching,
        searchQuery,
        profileImageUrl,
        isUploadingImage,
      ];

  StadiumProfileState copyWith({
    StadiumProfileStatus? status,
    Stadium? stadium,
    Address? address,
    String? errorMessage,
    bool? isRefreshing,
    bool? updateComplete,
    List<Service>? searchResults,
    bool? isSearching,
    String? searchQuery,
    String? profileImageUrl,
    bool? isUploadingImage,
  }) {
    return StadiumProfileState(
      status: status ?? this.status,
      stadium: stadium ?? this.stadium,
      address: address ?? this.address,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      updateComplete: updateComplete ?? this.updateComplete,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }

  // Helper getters
  bool get isInitial => status == StadiumProfileStatus.initial;
  bool get isLoading => status == StadiumProfileStatus.loading;
  bool get isSuccess => status == StadiumProfileStatus.success;
  bool get isError => status == StadiumProfileStatus.failure;
  bool get hasStadium => stadium != null;
  bool get hasAddress => address != null;
  bool get hasSearchResults => searchResults.isNotEmpty;
}
