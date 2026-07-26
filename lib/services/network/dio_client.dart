import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env_config.dart';

/// Butun ilova bo'ylab ishlatiladigan bitta Dio instance'ini taqdim etadi.
///
/// Bu yerda hech qanday endpoint chaqiruvi yo'q — faqat bazaviy sozlamalar
/// va umumiy interceptorlar. Aniq so'rovlar `features/<nom>/data/datasources/`
/// ichida shu provider orqali olingan `Dio` instance'idan foydalanadi.
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    LogInterceptor(requestBody: false, responseBody: false),
  );

  return dio;
});
