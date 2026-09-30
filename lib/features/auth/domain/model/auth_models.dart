enum UserRole {
  student,
  admin;

  static UserRole parse(String? value) => value == 'admin' ? admin : student;
}

/// Outcome of a successful login, enough to decide where to go next.
class LoginResult {
  final UserRole role;
  final bool hasProfile;

  const LoginResult({required this.role, required this.hasProfile});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    // The contract doesn't pin down where the role lives, so check the likely spots.
    final role = json['role'] ??
        (json['user'] is Map ? json['user']['role'] : null) ??
        (profile is Map ? profile['role'] : null);
    final isStaff = json['is_staff'] == true || (json['user'] is Map && json['user']['is_staff'] == true);
    return LoginResult(
      role: isStaff ? UserRole.admin : UserRole.parse(role?.toString()),
      hasProfile: profile is Map,
    );
  }
}

/// Returned by the endpoints that email an OTP.
class OtpInfo {
  final int expiresIn;
  final int resendAfter;
  final int attemptsRemaining;

  const OtpInfo({this.expiresIn = 600, this.resendAfter = 60, this.attemptsRemaining = 5});

  factory OtpInfo.fromJson(Map<String, dynamic> json) => OtpInfo(
        expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
        resendAfter: (json['resend_after'] as num?)?.toInt() ?? 60,
        attemptsRemaining: (json['attempts_remaining'] as num?)?.toInt() ?? 5,
      );
}
