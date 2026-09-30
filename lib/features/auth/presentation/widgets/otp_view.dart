import 'dart:async';

import 'package:flutter/material.dart';
import 'package:navo/core/theme/app_theme.dart';
import 'package:navo/features/auth/presentation/bloc/otp_timer.dart';
import 'package:navo/features/auth/presentation/widgets/auth_shell.dart';
import 'package:pinput/pinput.dart';

/// Full-screen 6-digit OTP entry with a resend countdown. Used by registration and password reset.
class OtpView extends StatefulWidget {
  final String email;
  final OtpTimer timer;
  final bool loading;
  final String? errorText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onResend;

  const OtpView({
    super.key,
    required this.email,
    required this.timer,
    required this.loading,
    required this.onSubmit,
    required this.onResend,
    this.errorText,
  });

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _controller = TextEditingController();
  Timer? _ticker;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(OtpView old) {
    super.didUpdateWidget(old);
    if (old.timer.round != widget.timer.round) {
      _controller.clear();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _ticker?.cancel();
    _secondsLeft = widget.timer.resendAfter;
    if (_secondsLeft <= 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length == 6) widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pin = PinTheme(
      width: 50,
      height: 58,
      textStyle: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    final locked = widget.timer.locked;
    final attempts = widget.timer.attemptsRemaining;

    return AuthShell(
      icon: Icons.mark_email_read_outlined,
      title: 'Check your email',
      subtitle: 'Enter the 6-digit code we sent to ${widget.email}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pinput(
            length: 6,
            controller: _controller,
            autofocus: true,
            enabled: !locked && !widget.loading,
            defaultPinTheme: pin,
            focusedPinTheme: pin.copyBorderWith(border: Border.all(color: scheme.primary, width: 1.5)),
            errorPinTheme: pin.copyBorderWith(border: Border.all(color: scheme.error)),
            forceErrorState: widget.errorText != null,
            errorText: widget.errorText,
            onCompleted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          if (attempts != null)
            Text(
              locked ? 'No attempts left for this code.' : '$attempts attempts remaining',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: locked ? scheme.error : scheme.onSurfaceVariant),
            ),
          const SizedBox(height: 28),
          LoadingButton(label: 'Verify', loading: widget.loading, onPressed: locked ? null : _submit),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _secondsLeft > 0 || widget.loading ? null : widget.onResend,
            child: Text(_secondsLeft > 0 ? 'Resend code in ${_secondsLeft}s' : 'Resend code'),
          ),
        ],
      ),
    );
  }
}
