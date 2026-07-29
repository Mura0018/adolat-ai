import 'ai_runtime_config.dart';

/// Admin tomonidan saqlangan konfiguratsiyani DINAMIK yuklovchi CHEGARA
/// (Module 5, Phase 5A talabi: "AI Runtime Configuration") -- **faqat
/// interfeys, hech qanday implementatsiya yo'q** (`AISafetyService`
/// konventsiyasi, Phase 1'dan beri).
///
/// Haqiqiy implementatsiya (masalan Supabase jadvalidan o'qiydigan,
/// yoki admin panel real vaqtda o'zgartirganda push qiladigan) kelgusi
/// bosqichda qo'shiladi -- bu ATAYLAB, talab: "Only build the control
/// architecture", haqiqiy saqlash/yetkazish mexanizmi emas.
abstract interface class AIRuntimeConfigProvider {
  /// Joriy konfiguratsiyani BIR MARTA yuklaydi -- masalan
  /// `AIServiceLocator`ni qurishdan oldin.
  Future<AIRuntimeConfig> load();

  /// Konfiguratsiya o'zgargan sari YANGI suratlarni chiqaruvchi oqim --
  /// masalan admin panel provayderni o'chirib qo'yganda, ishlab
  /// turgan backend jarayoni QAYTA ISHGA TUSHIRILMASDAN moslashishi
  /// uchun. Implementatsiya hech qachon o'zgarmasa ham, bo'sh
  /// (hech qachon hodisa chiqarmaydigan) oqim qaytarish yetarli --
  /// chaqiruvchi buni albatta hisobga olishi shart emas.
  Stream<AIRuntimeConfig> watch();
}
