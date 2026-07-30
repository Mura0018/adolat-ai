import '../information_requirement.dart';

/// Aniqlashtiruvchi savollar oqimidagi BITTA qadam (Module 5, Phase 5C
/// talabi: "Clarification workflow -- structured question flow").
///
/// **Nega shunchaki savol matni emas:** "structured" degani -- oqimning
/// UZUNLIGI va JORIY o'rni ham bilinishi kerak ([stepNumber] /
/// [totalSteps]), aks holda foydalanuvchiga "3-savol, jami 5 ta"
/// ko'rinishidagi progressni ko'rsatib bo'lmaydi (`DEVELOPMENT_RULES.md`,
/// 19-band -- "har bir muhim amal uchun keyingi qadam aniq
/// ko'rsatiladi").
class ClarificationStep {
  const ClarificationStep({
    required this.requirement,
    required this.stepNumber,
    required this.totalSteps,
  }) : assert(stepNumber >= 1, 'stepNumber 1 dan boshlanadi'),
       assert(stepNumber <= totalSteps, 'stepNumber totalSteps dan katta bo\'lishi mumkin emas');

  /// Shu qadam TO'LDIRADIGAN ma'lumot bo'lagi -- savol matni
  /// (`requirement.question`) va javob yozilishi kerak bo'lgan kalit
  /// (`requirement.id`) shu yerdan olinadi.
  final InformationRequirement requirement;

  /// 1'dan boshlanadigan joriy o'rin (QOLGAN savollar ichida, jami
  /// savollar ichida emas -- foydalanuvchi allaqachon javob berganlari
  /// oqimda qayta ko'rsatilmaydi).
  final int stepNumber;

  /// Shu daqiqada QOLGAN savollarning umumiy soni.
  final int totalSteps;

  bool get isFinal => stepNumber == totalSteps;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ClarificationStep &&
            other.requirement == requirement &&
            other.stepNumber == stepNumber &&
            other.totalSteps == totalSteps);
  }

  @override
  int get hashCode => Object.hash(requirement, stepNumber, totalSteps);

  @override
  String toString() =>
      'ClarificationStep(${requirement.id}, $stepNumber/$totalSteps)';
}
