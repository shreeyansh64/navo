import 'package:dio/dio.dart';

/// Error codes from the API contract. Branch on these, never on [ApiException.message].
class ApiErrorCode {
  static const validation = 'validation_error';
  static const accountExists = 'account_exists';
  static const invalidCredentials = 'invalid_credentials';
  static const invalidOtp = 'invalid_otp';
  static const otpExpired = 'otp_expired';
  static const otpCooldown = 'otp_cooldown';
  static const otpSendLimit = 'otp_send_limit';
  static const otpAttemptLimit = 'otp_attempt_limit';
  static const otpDeliveryFailed = 'otp_delivery_failed';
  static const throttled = 'throttled';
  static const invalidRequest = 'invalid_request';
  static const tokenNotValid = 'token_not_valid';
  static const notAuthenticated = 'not_authenticated';
  static const profileExists = 'profile_exists';
  static const profileIncomplete = 'profile_incomplete';
  static const studentNumberTaken = 'student_number_taken';
  static const invalidQr = 'invalid_qr';
  static const gateTokenExists = 'gate_token_exists';
  static const permissionDenied = 'permission_denied';

  // Client-side codes, never sent by the server.
  static const network = 'network_error';
  static const unknown = 'unknown_error';
}

class ApiException implements Exception {
  final int? status;
  final String code;
  final String message;
  final Map<String, List<String>> fields;
  final Map<String, dynamic> meta;

  const ApiException({
    this.status,
    required this.code,
    required this.message,
    this.fields = const {},
    this.meta = const {},
  });

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res == null) {
      return const ApiException(
        code: ApiErrorCode.network,
        message: 'Could not reach the server. Check your connection.',
      );
    }
    final data = res.data;
    final error = data is Map && data['error'] is Map ? data['error'] as Map : null;
    if (error == null) {
      return ApiException(
        status: res.statusCode,
        code: ApiErrorCode.unknown,
        message: 'Something went wrong (${res.statusCode}).',
      );
    }
    final rawFields = error['fields'];
    return ApiException(
      status: res.statusCode,
      code: error['code']?.toString() ?? ApiErrorCode.unknown,
      message: error['message']?.toString() ?? 'Something went wrong.',
      fields: rawFields is Map
          ? rawFields.map((k, v) => MapEntry(
              k.toString(), v is List ? v.map((e) => e.toString()).toList() : [v.toString()]))
          : const {},
      meta: error['meta'] is Map ? Map<String, dynamic>.from(error['meta']) : const {},
    );
  }

  static ApiException from(Object e) {
    if (e is ApiException) return e;
    if (e is DioException) return ApiException.fromDio(e);
    return ApiException(code: ApiErrorCode.unknown, message: e.toString());
  }

  String? field(String name) => fields[name]?.join('\n');
  int? get retryAfter => (meta['retry_after'] as num?)?.toInt();
  int? get attemptsRemaining => (meta['attempts_remaining'] as num?)?.toInt();

  /// User-facing text. Known codes get a fixed message, others fall back to the server's.
  String get displayMessage {
    switch (code) {
      case ApiErrorCode.validation:
        final first = fields.entries.isEmpty ? null : fields.entries.first;
        return first == null ? message : first.value.join(' ');
      case ApiErrorCode.invalidOtp:
        final left = attemptsRemaining;
        return left == null ? 'Incorrect code.' : 'Incorrect code. $left attempts left.';
      case ApiErrorCode.otpExpired:
        return 'This code has expired. Request a new one.';
      case ApiErrorCode.otpCooldown:
        return 'Please wait ${retryAfter ?? 60}s before requesting another code.';
      case ApiErrorCode.otpSendLimit:
        return 'Too many codes requested. Try again in an hour.';
      case ApiErrorCode.otpAttemptLimit:
        return 'Too many wrong attempts. Request a new code.';
      case ApiErrorCode.otpDeliveryFailed:
        return 'We could not send the email right now. Try again shortly.';
      case ApiErrorCode.throttled:
        return 'Too many requests. Please slow down.';
      case ApiErrorCode.accountExists:
        return 'An account with this email already exists. Please log in.';
      case ApiErrorCode.invalidCredentials:
        return 'Incorrect email or password.';
      case ApiErrorCode.profileExists:
        return 'Your profile is already complete.';
      case ApiErrorCode.studentNumberTaken:
        return 'This student number is already registered.';
      case ApiErrorCode.invalidQr:
        return 'Invalid or revoked QR code.';
      case ApiErrorCode.gateTokenExists:
        return message.isNotEmpty ? message : 'This token is already assigned.';
      case ApiErrorCode.permissionDenied:
        return 'Your account is not allowed to do this.';
      default:
        return message;
    }
  }

  @override
  String toString() => 'ApiException($status, $code): $message';
}
