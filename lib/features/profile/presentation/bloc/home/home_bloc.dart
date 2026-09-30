import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/profile/domain/repository/profile_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileRepository repository;

  HomeBloc({required this.repository}) : super(const HomeState()) {
    on<HomeLoadRequested>((event, emit) async {
      // Show the cached pass straight away, then replace it with a fresh one.
      final cached = state.qrDataUri ?? await repository.cachedQr();
      emit(HomeState(qrDataUri: cached));
      try {
        final pass = await repository.getMe();
        emit(HomeState(status: HomeStatus.loaded, qrDataUri: pass.qrDataUri));
      } on ApiException catch (e) {
        if (e.code == ApiErrorCode.profileIncomplete) {
          return emit(const HomeState(status: HomeStatus.profileIncomplete));
        }
        emit(HomeState(
          status: cached != null ? HomeStatus.offline : HomeStatus.failure,
          qrDataUri: cached,
          error: e,
        ));
      }
    });
  }
}
