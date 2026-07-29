/// Haqiqiy API kalitining o'zi EMAS, uni QAYERDAN topish mumkinligiga
/// ISHORA (Module 5, Phase 5A talabi: "API credential reference").
///
/// **Loyihaning markaziy xavfsizlik qoidasi:** *"API keys must NEVER
/// exist inside the Flutter application. They must be managed through
/// backend/admin configuration only."* Bu klass shu qoidani TUR
/// DARAJASIDA (type-level) mumkin qadar ta'minlaydi -- [referenceKey]
/// hech qachon xom kalit qiymatini o'zida saqlamaydi, faqat kalit
/// QAYERDA (qaysi environment o'zgaruvchisi/vault yozuvi) yotganini
/// ko'rsatadi. Haqiqiy qiymatni HAL QILISH (resolve) -- butunlay
/// alohida, backend-ichki qadam (`runtime/ai_credential_resolver.dart`,
/// **faqat interfeys, implementatsiyasiz**) -- bu klassning o'zi
/// hech qachon shu qadamni bajarmaydi.
///
/// `data/providers/*_adapter.dart` (Module 4, Phase 1)dagi `apiKey`
/// maydonlari bilan ADASHTIRILMASIN: o'shalar allaqachon HAL QILINGAN
/// (resolved) qiymatni oladi -- kim/qanday hal qilishini Phase 5A
/// belgilaydi, adapterlarning o'zi o'zgarmaydi.
enum AICredentialStoreKind {
  /// Backend jarayoni (Edge Function yoki alohida Dart xizmati)ning
  /// environment o'zgaruvchisi -- `docs/adr/ADR-005-ai-vendor-fallback.md`da
  /// tasvirlangan ikkala joylashtirish (deployment) variantida ham
  /// mavjud, eng sodda.
  environmentVariable,

  /// Supabase Vault (`vault.secrets`) -- Supabase Edge Function
  /// joylashtirish varianti uchun tabiiy tanlov.
  supabaseVault,

  /// Tashqi maxfiy ma'lumot boshqaruvchisi (masalan AWS Secrets
  /// Manager, GCP Secret Manager) -- alohida Dart xizmati joylashtirish
  /// varianti uchun.
  externalSecretsManager,
}

class AICredentialReference {
  const AICredentialReference({required this.storeKind, required this.referenceKey});

  final AICredentialStoreKind storeKind;

  /// Maxfiy ma'lumot DO'KONI ichidagi NOM/kalit (masalan
  /// `"OPENAI_API_KEY"` yoki `"projects/x/secrets/openai-key"") --
  /// haqiqiy qiymat EMAS, faqat qayerga qarash kerakligi.
  final String referenceKey;

  Map<String, dynamic> toJson() => {'storeKind': storeKind.name, 'referenceKey': referenceKey};

  factory AICredentialReference.fromJson(Map<String, dynamic> json) {
    return AICredentialReference(
      storeKind: AICredentialStoreKind.values.byName(json['storeKind'] as String),
      referenceKey: json['referenceKey'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AICredentialReference &&
            other.storeKind == storeKind &&
            other.referenceKey == referenceKey);
  }

  @override
  int get hashCode => Object.hash(storeKind, referenceKey);

  @override
  String toString() =>
      'AICredentialReference(storeKind: $storeKind, referenceKey: $referenceKey)';
}
