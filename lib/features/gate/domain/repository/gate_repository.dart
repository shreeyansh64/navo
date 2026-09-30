import 'package:navo/features/gate/domain/model/gate_models.dart';

/// All methods throw ApiException on failure.
abstract class GateRepository {
  Future<GateStudent> scan(String qrToken);
  Future<GateEntry> assignToken(String qrToken, String tokenNumber);
}
