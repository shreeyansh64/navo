part of 'gate_bloc.dart';

enum GateStatus { scanning, verifying, scanFailed, verified, assigning, assigned }

class GateState {
  final GateStatus status;
  final String? qrToken;
  final GateStudent? student;
  final GateEntry? entry;
  final ApiException? error;

  const GateState({this.status = GateStatus.scanning, this.qrToken, this.student, this.entry, this.error});

  bool get busy => status == GateStatus.verifying || status == GateStatus.assigning;
}
