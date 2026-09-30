import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/gate/domain/model/gate_models.dart';
import 'package:navo/features/gate/domain/repository/gate_repository.dart';

part 'gate_event.dart';
part 'gate_state.dart';

class GateBloc extends Bloc<GateEvent, GateState> {
  final GateRepository repository;

  GateBloc({required this.repository}) : super(const GateState()) {
    on<GateQrScanned>((event, emit) async {
      // Ignore detections while a scan is in flight or a student is on screen.
      if (state.status != GateStatus.scanning) return;
      emit(GateState(status: GateStatus.verifying, qrToken: event.qrToken));
      try {
        final student = await repository.scan(event.qrToken);
        emit(GateState(status: GateStatus.verified, qrToken: event.qrToken, student: student));
      } on ApiException catch (e) {
        emit(GateState(status: GateStatus.scanFailed, qrToken: event.qrToken, error: e));
      }
    });

    on<GateTokenSubmitted>((event, emit) async {
      final qr = state.qrToken!;
      final student = state.student;
      emit(GateState(status: GateStatus.assigning, qrToken: qr, student: student));
      try {
        final entry = await repository.assignToken(qr, event.tokenNumber);
        emit(GateState(status: GateStatus.assigned, qrToken: qr, student: student, entry: entry));
      } on ApiException catch (e) {
        emit(GateState(status: GateStatus.verified, qrToken: qr, student: student, error: e));
      }
    });

    on<GateReset>((event, emit) => emit(const GateState()));
  }
}
