/// Ish bo'yicha ALLAQACHON to'plangan ma'lumot -- `InformationRequirement.id`
/// → foydalanuvchi javobi (Module 5, Phase 5C talabi: "Progress
/// tracking -- show what information is complete").
///
/// O'zgarmas (immutable), `CaseTimeline` (Module 5, Phase 5B) bilan
/// bir xil naqsh: har bir yangilanish YANGI nusxa qaytaradi.
///
/// **Xavfsizlik:** [entries]ning QIYMATLARI -- foydalanuvchining xom
/// matni, sezgir bo'lishi mumkin. [toString] shu sababli na qiymatni,
/// na kalitni chiqaradi (faqat SONI) -- `Case.toString()`ning
/// `problemSummary`ni yashirishi (Module 5, Phase 5B) va
/// `AIBackendCredential.toString()`ning tokenni maskalashi (Module 4,
/// Phase 4B) bilan bir xil intizom.
class CollectedInformation {
  const CollectedInformation({this.entries = const {}});

  /// `InformationRequirement.id` → javob matni.
  final Map<String, String> entries;

  /// Bo'lak to'ldirilganmi -- **bo'sh/faqat probel matn "to'ldirilgan"
  /// HISOBLANMAYDI**, aks holda foydalanuvchi bo'sh javob yuborib
  /// progressni sun'iy ravishda "to'liq" qilib qo'yishi mumkin edi.
  bool has(String requirementId) {
    final value = entries[requirementId];
    return value != null && value.trim().isNotEmpty;
  }

  String? valueFor(String requirementId) => entries[requirementId];

  int get filledCount => entries.keys.where(has).length;

  bool get isEmpty => filledCount == 0;

  /// Yangi bo'lak bilan **yangi** nusxa qaytaradi (mavjud kalit
  /// ustiga yozadi -- foydalanuvchi javobini tuzatishi mumkin).
  CollectedInformation withEntry(String requirementId, String value) {
    return CollectedInformation(entries: {...entries, requirementId: value});
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CollectedInformation) return false;
    if (other.entries.length != entries.length) return false;
    for (final entry in entries.entries) {
      if (other.entries[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    // Map'ning tartibi kafolatlanmagani uchun kalitlar bo'yicha
    // saralangan holda hisoblanadi -- bir xil mazmunli ikki nusxa
    // bir xil hash beradi.
    final sortedKeys = entries.keys.toList()..sort();
    return Object.hashAll([for (final key in sortedKeys) ...[key, entries[key]]]);
  }

  @override
  String toString() => 'CollectedInformation($filledCount filled)';
}
