import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/gate/data/data_source/gate_remote_data_source.dart';
import 'package:navo/features/gate/domain/model/gate_models.dart';
import 'package:navo/features/gate/domain/repository/gate_repository.dart';

class GateRepositoryImpl implements GateRepository {
  final GateRemoteDataSource remote;
  GateRepositoryImpl({required this.remote});

  @override
  Future<GateStudent> scan(String qrToken) async {
    try {
      final json = await remote.scan(qrToken);
      return GateStudent.fromJson(Map<String, dynamic>.from(json['student'] as Map));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  @override
  Future<GateEntry> assignToken(String qrToken, String tokenNumber) async {
    try {
      final json = await remote.assignToken(qrToken, tokenNumber);
      return GateEntry.fromJson(Map<String, dynamic>.from(json['entry'] as Map));
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
