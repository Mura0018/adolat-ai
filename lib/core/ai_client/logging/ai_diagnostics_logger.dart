import 'package:flutter/foundation.dart';

import '../domain/ai_client_stream_event.dart';
import '../protocol/ai_request_envelope.dart';

/// AI so'rov pipeline'i uchun ICHKI diagnostika logging shartnomasi
/// (Module 4, Phase 4A talabi: "Logging -- internal diagnostic logging
/// interfaces, no analytics provider").
///
/// **Bu analitika (analytics) EMAS:** bu interfeys foydalanuvchi
/// xatti-harakatini kuzatish/hisobotlash uchun emas -- faqat
/// ishlab chiquvchiga AI so'rov pipeline'ining ICHKI holatini
/// (so'rov yuborildi/hodisa keldi/xatolik) diagnostika qilishga
/// yordam beradi. Hech qanday tashqi provayder (Firebase Analytics,
/// Sentry va h.k.) bu qatlamga ulanmaydi -- ulansa ham, faqat shu
/// interfeysni amalga oshiruvchi YANGI klass orqali, `AiRequestPipeline`
/// o'zgarishisiz.
abstract interface class AiDiagnosticsLogger {
  void logRequestSent(AiRequestEnvelope request);

  void logStreamEvent(AiClientStreamEvent event);

  void logError(String message, {Object? error, StackTrace? stackTrace});
}

/// Standart, "analitika bo'lmagan" implementatsiya -- faqat debug
/// rejimida (`kDebugMode`) konsolga yozadi
/// (`services/supabase/supabase_exception_mapper.dart`dagi bir xil
/// konventsiya). Production build'da hech narsa qilmaydi, hech qayerga
/// yubormaydi.
class DebugConsoleAiDiagnosticsLogger implements AiDiagnosticsLogger {
  const DebugConsoleAiDiagnosticsLogger();

  @override
  void logRequestSent(AiRequestEnvelope request) {
    if (!kDebugMode) return;
    debugPrint(
      '[AiClient] so\'rov yuborildi: requestId=${request.requestId} '
      'conversationId=${request.conversationId}',
    );
  }

  @override
  void logStreamEvent(AiClientStreamEvent event) {
    if (!kDebugMode) return;
    debugPrint('[AiClient] oqim hodisasi: ${event.runtimeType} (requestId=${event.requestId})');
  }

  @override
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    debugPrint('[AiClient] xatolik: $message${error != null ? ' -- $error' : ''}');
  }
}
