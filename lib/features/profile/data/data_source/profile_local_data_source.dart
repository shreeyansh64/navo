import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the last QR so the pass still opens without network.
/// Lives in the same secure storage as the tokens, so logout wipes it too.
class ProfileLocalDataSource {
  static const _qrKey = 'cached_qr_data_uri';

  final FlutterSecureStorage storage;
  ProfileLocalDataSource({required this.storage});

  Future<String?> readQr() => storage.read(key: _qrKey);
  Future<void> saveQr(String dataUri) => storage.write(key: _qrKey, value: dataUri);
}
