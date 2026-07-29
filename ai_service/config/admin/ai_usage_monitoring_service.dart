import '../../domain/entities/ai_provider_id.dart';
import '../domain/ai_usage_summary.dart';

/// Admin panelning "Usage Monitoring" ekrani chaqirishi mo'ljallangan
/// shartnoma (Module 5, Phase 5A talabi: "Admin Control Architecture
/// -- usage monitoring") -- **faqat interfeys, hech qanday
/// implementatsiya yo'q**, UI yo'q.
///
/// Haqiqiy implementatsiya (kelgusi bosqich) `domain/accounting/
/// AITokenAccountingSink` (Module 4, Phase 4C) orqali yozilgan xom
/// yozuvlarni [AIUsageSummary]ga AGREGATSIYA qilishi mo'ljallangan --
/// bu interfeys agregatsiya QANDAY bajarilishini (SQL/in-memory)
/// belgilamaydi, faqat natija shaklini.
abstract interface class AIUsageMonitoringService {
  Future<AIUsageSummary> getUsageSummary({
    required AIProviderId providerId,
    required DateTime periodStart,
    required DateTime periodEnd,
  });

  Future<List<AIUsageSummary>> getUsageSummaryForAllProviders({
    required DateTime periodStart,
    required DateTime periodEnd,
  });
}
