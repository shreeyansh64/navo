import 'package:navo/core/api/api_client.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:navo/features/auth/data/repository/auth_repository_impl.dart';
import 'package:navo/features/auth/domain/repository/auth_repository.dart';
import 'package:navo/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:navo/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:navo/features/auth/presentation/bloc/register/register_bloc.dart';

void setupAuth() {
  getIt
    ..registerLazySingleton(() => AuthRemoteDataSource(dio: getIt<ApiClient>().dio))
    ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remote: getIt(), tokenStorage: getIt()))
    ..registerFactory(() => LoginBloc(repository: getIt()))
    ..registerFactory(() => RegisterBloc(repository: getIt()))
    ..registerFactory(() => ForgotPasswordBloc(repository: getIt()));
}
