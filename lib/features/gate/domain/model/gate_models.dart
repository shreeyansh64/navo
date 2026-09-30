/// Student returned by /gate/scan/. Unknown extra keys are ignored.
class GateStudent {
  final String fullName;
  final String studentNumber;
  final String? year;
  final String? branch;
  final String section;
  final String? email;
  final String? imageUrl;
  final String? gateToken;

  const GateStudent({
    required this.fullName,
    required this.studentNumber,
    this.year,
    this.branch,
    required this.section,
    this.email,
    this.imageUrl,
    this.gateToken,
  });

  factory GateStudent.fromJson(Map<String, dynamic> json) => GateStudent(
        fullName: json['full_name']?.toString() ?? '',
        studentNumber: json['student_number']?.toString() ?? '',
        year: json['year']?.toString(),
        branch: json['branch']?.toString(),
        section: json['section']?.toString() ?? '',
        email: json['email']?.toString(),
        imageUrl: (json['image'] ?? json['image_url'])?.toString(),
        gateToken: (json['gate_token'] ?? json['token_number'])?.toString(),
      );
}

/// Entry created by /gate/assign-token/.
class GateEntry {
  final int id;
  final String studentNumber;
  final String tokenNumber;
  final DateTime? scannedAt;

  const GateEntry({required this.id, required this.studentNumber, required this.tokenNumber, this.scannedAt});

  factory GateEntry.fromJson(Map<String, dynamic> json) => GateEntry(
        id: (json['id'] as num).toInt(),
        studentNumber: json['student_number']?.toString() ?? '',
        tokenNumber: json['token_number']?.toString() ?? '',
        scannedAt: DateTime.tryParse(json['scanned_at']?.toString() ?? ''),
      );
}
