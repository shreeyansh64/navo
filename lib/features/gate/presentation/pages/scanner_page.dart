import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:navo/core/di/injection.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/widgets/logout_button.dart';
import 'package:navo/features/gate/domain/model/gate_models.dart';
import 'package:navo/features/gate/presentation/bloc/gate/gate_bloc.dart';
import 'package:navo/features/gate/presentation/pages/student_details_page.dart';

/// Admin home: scan a student's QR, verify it, then assign a gate token.
class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<GateBloc>(), child: const _ScannerView());
  }
}

class _ScannerView extends StatefulWidget {
  const _ScannerView();

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final bloc = context.read<GateBloc>();
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || bloc.state.status != GateStatus.scanning) return;
    _controller.pause();
    bloc.add(GateQrScanned(raw));
  }

  Future<void> _openStudent(BuildContext context) async {
    final bloc = context.read<GateBloc>();
    final entry = await Navigator.of(context).push<GateEntry>(MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: bloc, child: const StudentDetailsPage()),
    ));
    if (entry != null && context.mounted) {
      showSnack(context, 'Token ${entry.tokenNumber} assigned to ${entry.studentNumber}', error: false);
    }
    bloc.add(GateReset());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate scanner'),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _controller.toggleTorch,
          ),
          const LogoutButton(),
        ],
      ),
      body: BlocConsumer<GateBloc, GateState>(
        listenWhen: (prev, cur) =>
            // A failed assign also lands on `verified`, but from `assigning`, so open only after a scan.
            (prev.status == GateStatus.verifying && cur.status == GateStatus.verified) ||
            (prev.status != GateStatus.scanning && cur.status == GateStatus.scanning),
        listener: (context, state) {
          if (state.status == GateStatus.verified) _openStudent(context);
          if (state.status == GateStatus.scanning) _controller.start();
        },
        builder: (context, state) => Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => _CameraError(error: error),
            ),
            const _ScanFrame(),
            Positioned(left: 16, right: 16, bottom: 24, child: _StatusCard(state: state)),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black45, spreadRadius: 2000)],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final GateState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Widget child = switch (state.status) {
      GateStatus.verifying => const Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Text('Verifying pass…'),
          ],
        ),
      GateStatus.scanFailed => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(child: Text(state.error?.displayMessage ?? 'Scan failed.')),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.read<GateBloc>().add(GateReset()),
              child: const Text('Scan again'),
            ),
          ],
        ),
      _ => const Row(
          children: [
            Icon(Icons.qr_code_scanner_rounded),
            SizedBox(width: 16),
            Expanded(child: Text("Point the camera at a student's pass")),
          ],
        ),
    };
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _CameraError extends StatelessWidget {
  final MobileScannerException error;
  const _CameraError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            denied
                ? 'Camera permission is needed to scan passes. Enable it in Settings.'
                : 'Camera unavailable: ${error.errorCode.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
