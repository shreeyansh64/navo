import 'package:navo/core/api/api_client.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/profile/data/data_source/profile_local_data_source.dart';
import 'package:navo/features/profile/data/data_source/profile_remote_data_source.dart';
import 'package:navo/features/profile/data/repository/profile_repository_impl.dart';
import 'package:navo/features/profile/domain/repository/profile_repository.dart';
import 'package:navo/features/profile/presentation/bloc/complete_profile/complete_profile_bloc.dart';
import 'package:navo/features/profile/presentation/bloc/home/home_bloc.dart';

void setupProfile() {
  getIt
    ..registerLazySingleton(() => ProfileRemoteDataSource(dio: getIt<ApiClient>().dio))
    ..registerLazySingleton(() => ProfileLocalDataSource(storage: getIt()))
    ..registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(remote: getIt(), local: getIt()))
    ..registerFactory(() => CompleteProfileBloc(repository: getIt()))
    ..registerFactory(() => HomeBloc(repository: getIt()));
}
