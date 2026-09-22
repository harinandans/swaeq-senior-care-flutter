import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  Session({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'swaeq_access';
  static const _refreshKey = 'swaeq_refresh';

  final FlutterSecureStorage _storage;
  String? accessToken;
  String? refreshToken;

  Future<void> load() async {
    accessToken = await _storage.read(key: _accessKey);
    refreshToken = await _storage.read(key: _refreshKey);
  }

  Future<void> setTokens(String access, String? refresh) async {
    accessToken = access;
    await _storage.write(key: _accessKey, value: access);
    if (refresh != null) {
      refreshToken = refresh;
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  bool get hasSession =>
      (accessToken != null && accessToken!.isNotEmpty) ||
      (refreshToken != null && refreshToken!.isNotEmpty);
}
