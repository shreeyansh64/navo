import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:navo/core/api/api_client.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/storage/token_storage.dart';

void setupCore() {
  getIt
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton(() => TokenStorage(storage: getIt()))
    ..registerLazySingleton(() => ApiClient(tokenStorage: getIt()));
}
