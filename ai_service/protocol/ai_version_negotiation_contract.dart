import 'ai_protocol_version.dart';

/// Klient va backend qaysi simli protokol versiyasida gaplashishini
/// kelishib olish shartnomasi (Module 4, Phase 4B talabi: "Version
/// negotiation contract") -- `gateway/endpoint/ai_backend_endpoint.dart`dagi
/// `AIBackendEndpointId.negotiateProtocolVersion` amali shu turlar
/// bilan ishlaydi.
///
/// **`AIProtocolVersion` (Phase 3A) bilan munosabati:** o'sha klass
/// FAQAT "qaysi versiya" degan qiymatni ifodalaydi (`current`, hozircha
/// `v1`) -- versiyalar orasida QANDAY KELISHISH kerakligi haqida hech
/// narsa aytmaydi ("Backend bir vaqtning o'zida bir nechta versiyani
/// qo'llab-quvvatlashi mumkin" deb hujjatlashtirilgan, lekin bu
/// qo'llab-quvvatlashni ANIQLASH mexanizmi yo'q edi). Bu fayl aynan
/// shu bo'shliqni to'ldiradi.
///
/// **Nega alohida endpoint, `AIRequestEnvelope.protocolVersion`
/// yetarli emas:** so'rovning o'zi ALLAQACHON bitta versiyada
/// shakllangan bo'lishi kerak -- agar backend o'sha versiyani
/// qo'llab-quvvatlamasa, `AIRequestEnvelope`ning o'zini deserializatsiya
/// qilishning iloji bo'lmasligi mumkin (masalan maydon nomi butunlay
/// boshqacha). Versiya kelishuvi shuning uchun MUSTAQIL, YENGIL
/// (har doim bir xil minimal shaklda) amal sifatida ilova ishga
/// tushganda OLDINDAN bajarilishi mo'ljallangan -- shuning uchun
/// `gateway/endpoint/ai_backend_endpoint.dart`da
/// `requiresAuthentication: false`.
enum AIVersionNegotiationStatus {
  /// Klient va backend qo'llab-quvvatlaydigan versiyalar to'plami
  /// kesishadi -- [AIVersionNegotiationResult.negotiatedVersion] majburiy.
  negotiated,

  /// Kesishma yo'q -- klient ilovasi backend qo'llab-quvvatlaydigan
  /// HECH BIR versiyani bilmaydi (masalan juda eski/juda yangi ilova).
  /// `DEVELOPMENT_RULES.md`, 17-band ("No Dead End Rule") talabiga
  /// muvofiq, klient bu holatda aniq "ilovani yangilang" xabarini
  /// ko'rsatishi kutiladi.
  unsupported,
}

class AIVersionNegotiationRequest {
  // Const konstruktor emas -- `List.isNotEmpty` doimiy (const)
  // ifodalarda qo'llab-quvvatlanmaydi.
  AIVersionNegotiationRequest({required this.clientSupportedVersions})
    : assert(
        clientSupportedVersions.isNotEmpty,
        'clientSupportedVersions bo\'sh bo\'lishi mumkin emas',
      );

  /// Klient ilovasi bila oladigan barcha versiyalar -- odatda bittadan
  /// ko'p emas, lekin migratsiya davrida (ilova yangilanmoqda, eski
  /// va yangi sxemani ham tushunadi) bir nechta bo'lishi mumkin.
  final List<AIProtocolVersion> clientSupportedVersions;

  Map<String, dynamic> toJson() => {
    'clientSupportedVersions': clientSupportedVersions.map((v) => v.toJson()).toList(),
  };

  factory AIVersionNegotiationRequest.fromJson(Map<String, dynamic> json) {
    return AIVersionNegotiationRequest(
      clientSupportedVersions: (json['clientSupportedVersions'] as List)
          .map((v) => AIProtocolVersion.fromJson(v))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIVersionNegotiationRequest) return false;
    if (other.clientSupportedVersions.length != clientSupportedVersions.length) return false;
    for (var i = 0; i < clientSupportedVersions.length; i++) {
      if (other.clientSupportedVersions[i] != clientSupportedVersions[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(clientSupportedVersions);

  @override
  String toString() =>
      'AIVersionNegotiationRequest(clientSupportedVersions: $clientSupportedVersions)';
}

class AIVersionNegotiationResult {
  const AIVersionNegotiationResult({required this.status, this.negotiatedVersion})
    : assert(
        status != AIVersionNegotiationStatus.negotiated || negotiatedVersion != null,
        'status == negotiated bo\'lsa, negotiatedVersion majburiy',
      ),
      assert(
        status == AIVersionNegotiationStatus.negotiated || negotiatedVersion == null,
        'negotiatedVersion faqat status == negotiated bo\'lganda berilishi mumkin',
      );

  final AIVersionNegotiationStatus status;
  final AIProtocolVersion? negotiatedVersion;

  Map<String, dynamic> toJson() => {
    'status': status.name,
    if (negotiatedVersion != null) 'negotiatedVersion': negotiatedVersion!.toJson(),
  };

  factory AIVersionNegotiationResult.fromJson(Map<String, dynamic> json) {
    return AIVersionNegotiationResult(
      status: AIVersionNegotiationStatus.values.byName(json['status'] as String),
      negotiatedVersion: json['negotiatedVersion'] == null
          ? null
          : AIProtocolVersion.fromJson(json['negotiatedVersion']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIVersionNegotiationResult &&
            other.status == status &&
            other.negotiatedVersion == negotiatedVersion);
  }

  @override
  int get hashCode => Object.hash(status, negotiatedVersion);

  @override
  String toString() =>
      'AIVersionNegotiationResult(status: $status, negotiatedVersion: $negotiatedVersion)';
}

/// Xolis (pure) kelishuv funksiyasi -- klient e'lon qilgan versiyalar
/// va backend qo'llab-quvvatlaydigan versiyalar orasidan ENG YANGI
/// mos versiyani tanlaydi. Hech qanday tarmoq/holat yo'q -- haqiqiy
/// HTTP/WebSocket kirish nuqtasi bu funksiyani chaqirishi
/// mo'ljallangan (hali yo'q, talab: "Do NOT implement HTTP").
AIVersionNegotiationResult negotiateProtocolVersion({
  required AIVersionNegotiationRequest request,
  required Set<AIProtocolVersion> serverSupportedVersions,
}) {
  final mutuallySupported = request.clientSupportedVersions
      .where(serverSupportedVersions.contains)
      .toList();

  if (mutuallySupported.isEmpty) {
    return const AIVersionNegotiationResult(status: AIVersionNegotiationStatus.unsupported);
  }

  mutuallySupported.sort((a, b) => a.value.compareTo(b.value));
  return AIVersionNegotiationResult(
    status: AIVersionNegotiationStatus.negotiated,
    negotiatedVersion: mutuallySupported.last,
  );
}
