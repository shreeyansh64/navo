import 'package:dio/dio.dart';
import 'package:navo/core/constants/api_endpoints.dart';

class ProfileRemoteDataSource {
  final Dio dio;
  ProfileRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> completeProfile(FormData form) async {
    final res = await dio.post(ApiEndpoints.completeProfile, data: form);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await dio.get(ApiEndpoints.me);
    return Map<String, dynamic>.from(res.data as Map);
  }
}
