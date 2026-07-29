import '../domain/ai_credential_reference.dart';

/// [AICredentialReference]ni HAQIQIY qiymatga aylantiruvchi CHEGARA --
/// Module 5, Phase 5A'ning eng xavfsizlik-nozik nuqtasi. **Faqat
/// interfeys, hech qanday implementatsiya yo'q** (`AISafetyService`
/// konventsiyasi).
///
/// **Bu -- butun `ai_service/` ichida xom API kalit qiymati birinchi
/// marta PAYDO BO'LADIGAN yagona joy** (kelgusida haqiqiy
/// implementatsiya qo'shilganda). Shu sababli:
/// - Implementatsiya HECH QACHON `lib/` (Flutter ilovasi) tomonidan
///   chaqirilmasligi shart -- `ai_service/README.md`, "Nega alohida"
///   bilan bir xil chegara, endi credential hal qilish uchun ham.
/// - `resolve()`ning natijasi (xom kalit) hech qachon logga
///   yozilmasligi, xatolik xabariga qo'shilmasligi kerak
///   (`AIBackendCredential.toString()`, Module 4, Phase 4B bilan bir
///   xil ehtiyotkorlik).
/// - Implementatsiya [AICredentialReference.storeKind]ga qarab mos
///   do'kondan (environment o'zgaruvchisi/Supabase Vault/tashqi
///   maxfiy ma'lumot boshqaruvchisi) o'qishi kutiladi.
abstract interface class AICredentialResolver {
  Future<String> resolve(AICredentialReference reference);
}
