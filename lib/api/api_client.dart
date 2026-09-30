import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../auth/session.dart';
import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.session, {void Function()? onAuthLost})
      : _onAuthLost = onAuthLost {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = session.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final cfg = error.requestOptions;
          final status = error.response?.statusCode;
          final path = cfg.path;
          final isAuth = path.startsWith('/auth/');
          if (status == 401 &&
              !isAuth &&
              cfg.extra['retried'] != true &&
              session.refreshToken != null) {
            try {
              await refreshAccess();
              final opts = cfg.copyWith(
                headers: Map<String, dynamic>.from(cfg.headers)
                  ..['Authorization'] = 'Bearer ${session.accessToken}',
                extra: Map<String, dynamic>.from(cfg.extra)..['retried'] = true,
              );
              final res = await _dio.fetch(opts);
              return handler.resolve(res);
            } catch (_) {
              await session.clear();
              _onAuthLost?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Session session;
  final void Function()? _onAuthLost;
  late final Dio _dio;
  Future<void>? _refreshing;

  Future<void> refreshAccess() {
    _refreshing ??= () async {
      final r = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': session.refreshToken},
      );
      await session.setTokens(
        r.data['accessToken'] as String,
        r.data['refreshToken'] as String?,
      );
    }()
        .whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map &&
        data['error'] is Map &&
        data['error']['message'] != null) {
      return data['error']['message'].toString();
    }
    return e.message ?? 'Something went wrong';
  }

  Future<T> _wrap<T>(Future<Response> Function() call) async {
    try {
      final r = await call();
      return r.data as T;
    } on DioException catch (e) {
      throw ApiException(_msg(e));
    }
  }

  Future<Map<String, dynamic>> post(String path,
          [Map<String, dynamic>? body]) =>
      _wrap(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? body]) =>
      _wrap(() => _dio.put(path, data: body));

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _wrap(() => _dio.get(path, queryParameters: query));

  Future<void> delete(String path) => _wrap(() => _dio.delete(path));

  // ---- Auth / me ----
  Future<Map<String, dynamic>> sendOtp(String phone) =>
      post('/auth/otp/send', {'phone': phone});

  Future<Map<String, dynamic>> verifyOtp(String otpToken, String otpCode) =>
      post('/auth/otp/verify', {'otpToken': otpToken, 'otpCode': otpCode});

  Future<void> logout() async {
    try {
      if (session.refreshToken != null) {
        await post('/auth/logout', {'refreshToken': session.refreshToken});
      }
    } catch (_) {}
    await session.clear();
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String platform,
    String? pushToken,
  }) =>
      post('/devices', {
        'deviceId': deviceId,
        'platform': platform,
        if (pushToken != null) 'pushToken': pushToken,
      });

  Future<Map<String, dynamic>> me() => get('/me');
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      put('/me/profile', body);
  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) =>
      put('/me/preferences', body);

  // ---- Senior care ----
  Future<Map<String, dynamic>> seniorHome() => get('/senior/home');
  Future<Map<String, dynamic>> seniorToday({String? date}) =>
      get('/senior/today', query: {if (date != null) 'date': date});
  Future<Map<String, dynamic>> completeSeniorSlot(
    String slotId, {
    String? date,
    bool skipped = false,
    String? note,
  }) =>
      post('/senior/today/slots/$slotId/complete', {
        if (date != null) 'date': date,
        'skipped': skipped,
        if (note != null) 'note': note,
      });

  Future<Map<String, dynamic>> seniorContent({
    String? category,
    String? kind,
    String? access,
    String? cursor,
    int limit = 20,
  }) =>
      get('/senior/content', query: {
        'limit': limit,
        if (category != null) 'category': category,
        if (kind != null) 'kind': kind,
        if (access != null) 'access': access,
        if (cursor != null) 'cursor': cursor,
      });

  Future<Map<String, dynamic>> seniorContentDetail(String id) =>
      get('/senior/content/$id');
  Future<Map<String, dynamic>> playSeniorContent(String id) =>
      get('/senior/content/$id/play');

  /// Optional engagement sync; failures are ignored client-side.
  Future<void> submitContentEngagement(
    String contentId, {
    bool? liked,
    String? comment,
    Map<String, int>? reactions,
  }) async {
    try {
      await post('/senior/content/$contentId/engagement', {
        if (liked != null) 'liked': liked,
        if (comment != null) 'comment': comment,
        if (reactions != null) 'reactions': reactions,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> seniorReminders(String date) =>
      get('/senior/reminders', query: {'date': date});
  Future<Map<String, dynamic>> createSeniorReminder(
          Map<String, dynamic> body) =>
      post('/senior/reminders', body);
  Future<
      Map<String,
          dynamic>> markSeniorReminderDone(String instanceKey) => post(
      '/senior/reminders/instances/${Uri.encodeComponent(instanceKey)}/done');

  // Aliases used by reminders screen
  Future<Map<String, dynamic>> reminders(String date) => seniorReminders(date);
  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> body) =>
      createSeniorReminder(body);
  Future<Map<String, dynamic>> updateReminder(
    String id,
    Map<String, dynamic> body,
  ) =>
      put('/reminders/$id', body);
  Future<void> deleteReminder(String id) => delete('/reminders/$id');
  Future<Map<String, dynamic>> markReminderDone(String instanceKey) =>
      markSeniorReminderDone(instanceKey);

  Future<Map<String, dynamic>> seniorQuiz(String id) =>
      get('/senior/quizzes/$id');
  Future<Map<String, dynamic>> submitSeniorQuiz(
    String id,
    List<Map<String, dynamic>> answers,
  ) =>
      post('/senior/quizzes/$id/attempts', {'answers': answers});

  Future<Map<String, dynamic>> seniorGames() => get('/senior/games');
  Future<Map<String, dynamic>> seniorQuote({String? date}) =>
      get('/senior/quote', query: {if (date != null) 'date': date});
  Future<Map<String, dynamic>> seniorDeity({String? date}) =>
      get('/senior/deity-of-day', query: {if (date != null) 'date': date});

  Future<Map<String, dynamic>> seniorPrograms() => get('/senior/programs');
  Future<Map<String, dynamic>> seniorProgram(String id) =>
      get('/senior/programs/$id');
  Future<Map<String, dynamic>> enrollSeniorProgram(String id) =>
      post('/senior/programs/$id/enroll');
  Future<Map<String, dynamic>> mockPay(String orderId) =>
      post('/orders/$orderId/mock-pay', {'method': 'upi'});

  Future<Map<String, dynamic>> seniorTips() => get('/senior/tips');
  Future<Map<String, dynamic>> seniorProducts() => get('/senior/products');

  // ---- Media (optional avatar / family share) ----
  Future<Map<String, dynamic>> createUpload({
    required String contentType,
    required String purpose,
    required int sizeBytes,
    String kind = 'photo',
  }) =>
      post('/media/uploads', {
        'kind': kind,
        'purpose': purpose,
        'mime': contentType,
        'sizeBytes': sizeBytes,
      });

  Future<Map<String, dynamic>> completeUpload(String mediaId) =>
      post('/media/$mediaId/complete');

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String contentType,
    required String purpose,
  }) async {
    final up = await createUpload(
      contentType: contentType,
      purpose: purpose,
      sizeBytes: bytes.length,
    );
    final uploadUrl = up['uploadUrl'] as String;
    final mediaId = up['mediaId'] as String;
    final putDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
    await putDio.put(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          Headers.contentTypeHeader: contentType,
          Headers.contentLengthHeader: bytes.length.toString(),
        },
        contentType: contentType,
        responseType: ResponseType.plain,
      ),
    );
    await completeUpload(mediaId);
    return mediaId;
  }
}
