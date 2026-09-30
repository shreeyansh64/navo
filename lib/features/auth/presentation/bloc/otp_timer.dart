import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/auth/domain/model/auth_models.dart';

/// OTP resend/attempt bookkeeping shared by the register and forgot-password flows.
class OtpTimer {
  /// Seconds until "resend" is allowed, counted from the latest [round].
  final int resendAfter;

  /// Bumped on each (re)send so the UI restarts its countdown.
  final int round;
  final int? attemptsRemaining;

  const OtpTimer({this.resendAfter = 60, this.round = 0, this.attemptsRemaining});

  OtpTimer sent(OtpInfo info) =>
      OtpTimer(resendAfter: info.resendAfter, round: round + 1, attemptsRemaining: info.attemptsRemaining);

  OtpTimer afterError(ApiException e) {
    switch (e.code) {
      case ApiErrorCode.otpCooldown:
        return OtpTimer(
            resendAfter: e.retryAfter ?? resendAfter, round: round + 1, attemptsRemaining: attemptsRemaining);
      case ApiErrorCode.otpAttemptLimit:
        return OtpTimer(resendAfter: resendAfter, round: round, attemptsRemaining: 0);
      default:
        return OtpTimer(
            resendAfter: resendAfter, round: round, attemptsRemaining: e.attemptsRemaining ?? attemptsRemaining);
    }
  }

  bool get locked => attemptsRemaining == 0;
}
