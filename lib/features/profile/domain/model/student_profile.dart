import 'dart:convert';
import 'dart:typed_data';

class StudentProfile {
  final String fullName;
  final String section;
  final String? year;
  final String? branch;
  final String studentNumber;
  final String? email;
  final String? imageUrl;

  const StudentProfile({
    required this.fullName,
    required this.section,
    this.year,
    this.branch,
    required this.studentNumber,
    this.email,
    this.imageUrl,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        fullName: json['full_name']?.toString() ?? '',
        section: json['section']?.toString() ?? '',
        year: json['year']?.toString(),
        branch: json['branch']?.toString(),
        studentNumber: json['student_number']?.toString() ?? '',
        email: json['email']?.toString(),
        imageUrl: (json['image'] ?? json['image_url'])?.toString(),
      );
}

/// Response of /auth/complete-profile/ and /me/.
class QrPass {
  final StudentProfile? profile;
  final String qrToken;
  final String qrDataUri;

  const QrPass({this.profile, required this.qrToken, required this.qrDataUri});

  factory QrPass.fromJson(Map<String, dynamic> json) => QrPass(
        profile: json['profile'] is Map
            ? StudentProfile.fromJson(Map<String, dynamic>.from(json['profile']))
            : null,
        qrToken: json['qr_token']?.toString() ?? '',
        qrDataUri: json['qr_code_data_uri'] as String,
      );
}

/// PNG bytes from a `data:image/png;base64,...` URI.
Uint8List qrBytes(String dataUri) => base64Decode(dataUri.split(',').last);
