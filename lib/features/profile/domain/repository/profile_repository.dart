import 'dart:io';

import 'package:navo/features/profile/domain/model/student_profile.dart';

/// All methods throw ApiException on failure.
abstract class ProfileRepository {
  Future<QrPass> completeProfile({
    required String fullName,
    required String section,
    required String year,
    required String branch,
    required String studentNumber,
    required File image,
  });

  /// Fetches the current pass and caches its QR for offline use.
  Future<QrPass> getMe();

  /// Last QR data URI saved by [getMe] or [completeProfile], if any.
  Future<String?> cachedQr();
}
