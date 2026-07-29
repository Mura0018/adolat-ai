import '../../domain/quota/ai_usage_quota.dart';
import '../../protocol/ai_usage_quota_contract.dart';

/// Admin panelning "Quota Management" ekrani chaqirishi mo'ljallangan
/// shartnoma (Module 5, Phase 5A talabi: "Admin Control Architecture
/// -- quota management") -- **faqat interfeys, hech qanday
/// implementatsiya yo'q**, UI yo'q.
///
/// **Module 4, Phase 4B/4C bilan bog'liq:** `AIUsageQuotaPolicy`/
/// `AIUsageQuotaStatus` allaqachon mavjud (`domain/quota/`, `protocol/`)
/// -- shu interfeys ularni ADMIN tomonidan o'qish/yangilashga ochadi.
/// Boshqacha aytganda: Phase 4B/4C kvota MEXANIZMINI qurdi (siyosat,
/// hisoblash, `AIGatewayImpl` tekshiruvi), Phase 5A esa shu mexanizmni
/// KIM BOSHQARISHI (admin) uchun kirish nuqtasini belgilaydi.
abstract interface class AIQuotaManagementService {
  /// Joriy, GLOBAL (barcha foydalanuvchilar uchun bir xil) kvota
  /// siyosati -- `AIGatewayImpl.quotaPolicy` (Phase 4C) shu qiymatdan
  /// kelib chiqishi mo'ljallangan.
  Future<AIUsageQuotaPolicy> getPolicy();

  Future<void> updatePolicy(AIUsageQuotaPolicy policy);

  /// Bitta foydalanuvchining joriy kvota holati -- admin "kim
  /// chegaraga yaqinlashib qolgan" savoliga javob topishi uchun.
  Future<AIUsageQuotaStatus> getUsageStatusForUser(String userId);
}
