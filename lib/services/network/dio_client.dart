import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  // FAQAT debug rejimida loglanadi (`docs/DEVELOPMENT_RULES.md`, 11-band:
  // "Release build'da debug loglar ishlamasligi shart").
  //
  // `requestBody`/`responseBody` release'da ham `false` edi, ya'ni so'rov
  // TANASI hech qachon chiqmagan -- lekin so'rov URL'lari, sarlavhalar va
  // status kodlari release build konsoliga ham tushardi. Huquqiy/shaxsiy
  // ma'lumot bilan ishlaydigan ilovada URL'ning o'zi ham ma'lumot
  // (masalan `/appeals/<uuid>`) -- shuning uchun butun interceptor
  // release'da umuman QO'SHILMAYDI, sozlamasi yumshatilmaydi.
  //
  // `kDebugMode` -- kompilyatsiya vaqtidagi konstanta: release build'da
  // tree-shaking bu blokni va `LogInterceptor`ga bo'lgan havolani
  // butunlay olib tashlaydi (runtime tekshiruv qolmaydi).
  //
  // Bir xil naqsh: `lib/services/supabase/supabase_exception_mapper.dart`
  // va `lib/core/ai_client/logging/ai_diagnostics_logger.dart`.
  // Regressiyadan himoya: `test/core/release_logging_safety_test.dart`.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  return dio;
});
