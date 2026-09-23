import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../notifications/notification_service.dart';
import 'session.dart';

class AuthState extends ChangeNotifier {
  AuthState(this.session) {
    api = ApiClient(session, onAuthLost: () {
      me = null;
      notifyListeners();
    });
  }

  final Session session;
  late final ApiClient api;

  Map<String, dynamic>? me;
  bool ready = false;
  bool elderlyMode = true; // senior app always uses larger type

  Future<void> bootstrap() async {
    await session.load();
    if (session.hasSession) {
      try {
        me = await api.me();
        elderlyMode = true;
        // Notification registration is non-critical; don't block or crash on failure
        _registerNotificationsAsync();
      } catch (_) {
        await session.clear();
        me = null;
      }
    }
    ready = true;
    notifyListeners();
  }

  /// Register notifications asynchronously without blocking startup.
  void _registerNotificationsAsync() {
    Future(() async {
      try {
        await NotificationService.instance.registerWithApi(api);
        await NotificationService.instance.syncFromApi(api);
      } catch (e) {
        debugPrint('Notification registration skipped: $e');
      }
    });
  }

  bool get isLoggedIn => session.hasSession;

  /// Senior app skips multi-step onboarding — login is enough.
  bool get profileComplete => isLoggedIn;

  Future<void> afterLogin(Map<String, dynamic> verifyResponse) async {
    await session.setTokens(
      verifyResponse['accessToken'] as String,
      verifyResponse['refreshToken'] as String?,
    );
    me = await api.me();
    elderlyMode = true;
    // Soft-enable elderly mode on the server; ignore failures.
    try {
      await api.updatePreferences({'elderlyMode': true});
      me = await api.me();
    } catch (_) {}
    // Notification registration is non-critical; don't block or crash on failure
    _registerNotificationsAsync();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    me = await api.me();
    elderlyMode = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    me = null;
    elderlyMode = true;
    notifyListeners();
  }

  void setElderly(bool value) {
    elderlyMode = true;
    notifyListeners();
  }
}
