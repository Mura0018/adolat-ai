import 'ai_connectivity_status.dart';

/// Ulanish holatini kuzatish uchun abstrakt shartnoma (Module 4, Phase
/// 4A talabi: "Offline Handling -- prepare the architecture for future
/// offline detection, no real connectivity implementation").
///
/// **Ko'lam: faqat interfeys, implementatsiyasiz.** Haqiqiy tarmoq
/// holatini tekshiruvchi konkret klass (masalan `connectivity_plus`
/// paketi ustiga qurilgan) Module 4, Phase 4A doirasidan tashqarida --
/// bu backend hamkasbi `AIConnectivityMonitor`
/// (`ai_service/gateway/connectivity/ai_connectivity_monitor.dart`)
/// bilan bir xil, ataylab qilingan tanlov.
///
/// `AiRequestPipeline` (`../ai_request_pipeline.dart`) bu monitorni
/// IXTIYORIY bog'liqlik sifatida qabul qiladi -- `null` bo'lsa (hozirgi
/// standart holat), hech qanday oflayn tekshiruvi qilinmaydi va so'rov
/// har doim yuborishga urinadi (joriy xatti-harakat o'zgarmaydi). Haqiqiy
/// implementatsiya qo'shilganda, pipeline'ning o'zini o'zgartirmasdan
/// shu joyga in'ektsiya qilinadi.
abstract interface class AiConnectivityMonitor {
  AiConnectivityStatus get currentStatus;

  Stream<AiConnectivityStatus> get statusChanges;
}
