import 'dart:io';

import 'package:dio/dio.dart';
import 'package:navo/core/api/api_error.dart';
import 'package:navo/features/profile/data/data_source/profile_local_data_source.dart';
import 'package:navo/features/profile/data/data_source/profile_remote_data_source.dart';
import 'package:navo/features/profile/domain/model/student_profile.dart';
import 'package:navo/features/profile/domain/repository/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  final ProfileLocalDataSource local;

  ProfileRepositoryImpl({required this.remote, required this.local});

  @override
  Future<QrPass> completeProfile({
    required String fullName,
    required String section,
    required String studentNumber,
    File? image,
  }) async {
    try {
      final form = FormData.fromMap({
        'full_name': fullName,
        'section': section,
        'student_number': studentNumber,
        if (image != null)
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.path.split(RegExp(r'[\/]')).last,
            contentType: _mediaType(image.path),
          ),
      });
      final pass = QrPass.fromJson(await remote.completeProfile(form));
      await local.saveQr(pass.qrDataUri);
      return pass;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  @override
  Future<QrPass> getMe() async {
    try {
      final pass = QrPass.fromJson(await remote.me());
      await local.saveQr(pass.qrDataUri);
      return pass;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  @override
  Future<String?> cachedQr() => local.readQr();

  DioMediaType _mediaType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      _ => DioMediaType('image', 'jpeg'),
    };
  }
}
