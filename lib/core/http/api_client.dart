import 'package:dio/dio.dart';
import '../config/env.dart';
import '../errors/app_exception.dart';
import 'providers.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required this.dio});

  factory ApiClient.create({required TokenProvider tokenProvider}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenProvider.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );

    return ApiClient(dio: dio);
  }

  AppException mapDioError(DioException e, {String fallback = 'Erro ao comunicar com o servidor.'}) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String? msg;
    if (data is Map) {
      final message = data['message'];
      final error = data['error'];
      if (message is String && message.trim().isNotEmpty) msg = message;
      if (msg == null && error is String && error.trim().isNotEmpty) msg = error;
    }
    msg ??= e.message;
    msg ??= fallback;

    return AppException(msg, statusCode: status, cause: e);
  }
}
