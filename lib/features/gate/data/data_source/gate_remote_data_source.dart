import 'package:dio/dio.dart';
import 'package:navo/core/constants/api_endpoints.dart';

class GateRemoteDataSource {
  final Dio dio;
  GateRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> scan(String qrToken) async {
    final res = await dio.post(ApiEndpoints.gateScan, data: {'qr_token': qrToken});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> assignToken(String qrToken, String tokenNumber) async {
    final res = await dio.post(ApiEndpoints.gateAssignToken,
        data: {'qr_token': qrToken, 'token_number': tokenNumber});
    return Map<String, dynamic>.from(res.data as Map);
  }
}
