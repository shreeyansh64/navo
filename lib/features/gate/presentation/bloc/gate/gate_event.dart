part of 'gate_bloc.dart';

sealed class GateEvent {}

class GateQrScanned extends GateEvent {
  final String qrToken;
  GateQrScanned(this.qrToken);
}

class GateTokenSubmitted extends GateEvent {
  final String tokenNumber;
  GateTokenSubmitted(this.tokenNumber);
}

/// Back to scanning the next student.
class GateReset extends GateEvent {}
