import 'package:navo/core/api/api_client.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/gate/data/data_source/gate_remote_data_source.dart';
import 'package:navo/features/gate/data/repository/gate_repository_impl.dart';
import 'package:navo/features/gate/domain/repository/gate_repository.dart';
import 'package:navo/features/gate/presentation/bloc/gate/gate_bloc.dart';

void setupGate() {
  getIt
    ..registerLazySingleton(() => GateRemoteDataSource(dio: getIt<ApiClient>().dio))
    ..registerLazySingleton<GateRepository>(() => GateRepositoryImpl(remote: getIt()))
    ..registerFactory(() => GateBloc(repository: getIt()));
}
