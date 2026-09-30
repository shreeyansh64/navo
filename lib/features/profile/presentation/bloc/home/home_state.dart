part of 'home_bloc.dart';

enum HomeStatus { loading, loaded, offline, profileIncomplete, failure }

class HomeState {
  final HomeStatus status;

  /// `data:image/png;base64,...`, fresh when [HomeStatus.loaded], cached when offline.
  final String? qrDataUri;
  final StudentProfile? profile;
  final ApiException? error;

  const HomeState({
    this.status = HomeStatus.loading,
    this.qrDataUri,
    this.profile,
    this.error,
  });
}
