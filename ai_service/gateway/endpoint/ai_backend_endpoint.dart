/// Backend tomonidan taqdim etilishi kerak bo'lgan MANTIQIY
/// amallarning to'liq ro'yxati (Module 4, Phase 4B talabi: "Backend
/// endpoint definitions").
///
/// **Nega HTTP yo'l/method emas:** `AITransport` (`gateway/transport/`,
/// Phase 3B) bilan bir xil sabab -- bu ro'yxat transportdan
/// (HTTP/WebSocket/gRPC) butunlay mustaqil, faqat QAYSI amallar
/// mavjudligini va ularning autentifikatsiya/rate-limit/idempotency
/// xususiyatlarini belgilaydi. Haqiqiy route/method/handler (masalan
/// `POST /v1/conversations`) hali YO'Q -- bu ATAYLAB, chunki bu
/// bosqichda HTTP umuman implementatsiya qilinmaydi (`docs/
/// AI_ARCHITECTURE.md`, "Backend Contract (Module 4, Phase 4B)"
/// bo'limi).
///
/// **Ko'lam:** `AIRequestEnvelope`/`AIResponseEnvelope` (Phase 3A)
/// faqat [sendMessage]ni ifodalaydi -- qolgan amallar (suhbat
/// boshlash/bekor qilish/yopish, fayl yuklash, versiya kelishuvi,
/// kvota so'rovi) uchun ko'pchilik hali mos konvert turiga ega emas.
/// Bu fayl avval FAQAT nomlab qo'yiladigan bo'shliqni to'ldiradi --
/// konvert turi mavjud bo'lgan amallar shu bosqichning boshqa
/// fayllarida qo'shildi (masalan `protocol/ai_attachment_upload_
/// contract.dart` -- [requestAttachmentUpload] uchun).
enum AIBackendEndpointId {
  startConversation,
  sendMessage,
  cancelConversation,
  closeConversation,
  requestAttachmentUpload,
  negotiateProtocolVersion,
  getUsageQuota,
}

/// Bitta endpoint haqidagi TAVSIFIY (descriptive) metadata --
/// bajariladigan mantiq emas, faqat xususiyatlar. Kelgusi HTTP/
/// WebSocket kirish nuqtasi shu metadatadan (masalan
/// [requiresAuthentication]) qaror qabul qiladi, lekin buni QANDAY
/// amalga oshirish (masalan qaysi middleware) bu klassning
/// mas'uliyati emas -- `gateway/auth/ai_authenticator.dart`,
/// `gateway/ratelimit/ai_rate_limiter.dart` kabi interfeyslarning
/// ishi.
class AIBackendEndpointDescriptor {
  const AIBackendEndpointDescriptor({
    required this.id,
    required this.requiresAuthentication,
    required this.isRateLimited,
    required this.isIdempotent,
    required this.description,
  });

  final AIBackendEndpointId id;

  /// `false` bo'lgan yagona hol -- [AIBackendEndpointId.negotiateProtocolVersion]:
  /// versiya kelishuvi mantiqan autentifikatsiyadan OLDIN sodir
  /// bo'lishi kerak (ilova ishga tushganda, foydalanuvchi hali login
  /// qilmagan bo'lsa ham, klient va backend qaysi protokol versiyasida
  /// gaplashishini kelishib olishi kerak).
  final bool requiresAuthentication;

  /// `docs/SECURITY.md`, "Rate Limiting" bo'limi ("AI tahlil
  /// so'rovlari... foydalanuvchi bo'yicha cheklanadi") va
  /// `docs/adr/ADR-004-ai-cost-governance.md`ga mos -- resurs
  /// sarflaydigan (AI so'rovi yuboradigan yoki fayl yuklashga olib
  /// keladigan) amallar `true`.
  final bool isRateLimited;

  /// Bir xil so'rovni (bir xil parametr bilan) qayta yuborish
  /// natijani o'zgartirmaydimi. Masalan allaqachon bekor qilingan
  /// suhbatga qayta [cancelConversation] chaqiruvi xavfsiz, natija bir
  /// xil qoladi -- shuning uchun `true`. [sendMessage] esa har
  /// chaqiruvda yangi assistant javobi ishlab chiqarishi mumkin
  /// bo'lgani uchun `false`.
  final bool isIdempotent;

  final String description;

  @override
  String toString() => 'AIBackendEndpointDescriptor(id: $id)';
}

/// Yagona haqiqat manbai (single source of truth) -- har bir
/// [AIBackendEndpointId] uchun bitta [AIBackendEndpointDescriptor].
/// Ro'yxatning to'liqligi (`AIBackendEndpointId.values`ning har biri
/// ro'yxatda borligi) `test/ai_service/ai_backend_endpoint_test.dart`da
/// tekshiriladi.
class AIBackendEndpointRegistry {
  AIBackendEndpointRegistry._();

  static const Map<AIBackendEndpointId, AIBackendEndpointDescriptor> _all = {
    AIBackendEndpointId.startConversation: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.startConversation,
      requiresAuthentication: true,
      isRateLimited: false,
      isIdempotent: false,
      description: 'Yangi suhbat yaratadi.',
    ),
    AIBackendEndpointId.sendMessage: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.sendMessage,
      requiresAuthentication: true,
      isRateLimited: true,
      isIdempotent: false,
      description: 'Suhbatga xabar yuboradi, AI javobini oqim sifatida qaytaradi.',
    ),
    AIBackendEndpointId.cancelConversation: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.cancelConversation,
      requiresAuthentication: true,
      isRateLimited: false,
      isIdempotent: true,
      description: "Suhbat bo'yicha joriy faol so'rovni bekor qiladi.",
    ),
    AIBackendEndpointId.closeConversation: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.closeConversation,
      requiresAuthentication: true,
      isRateLimited: false,
      isIdempotent: true,
      description: 'Suhbatni yopadi.',
    ),
    AIBackendEndpointId.requestAttachmentUpload: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.requestAttachmentUpload,
      requiresAuthentication: true,
      isRateLimited: true,
      isIdempotent: false,
      description: "Fayl yuklash uchun oldindan ruxsat (ticket) so'raydi.",
    ),
    AIBackendEndpointId.negotiateProtocolVersion: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.negotiateProtocolVersion,
      requiresAuthentication: false,
      isRateLimited: false,
      isIdempotent: true,
      description: "Klient va backend qo'llab-quvvatlaydigan protokol versiyasini kelishadi.",
    ),
    AIBackendEndpointId.getUsageQuota: AIBackendEndpointDescriptor(
      id: AIBackendEndpointId.getUsageQuota,
      requiresAuthentication: true,
      isRateLimited: false,
      isIdempotent: true,
      description: "Joriy foydalanuvchining kunlik AI so'rov kvotasi holatini qaytaradi.",
    ),
  };

  static AIBackendEndpointDescriptor describe(AIBackendEndpointId id) => _all[id]!;

  static Iterable<AIBackendEndpointDescriptor> get all => _all.values;
}
