import '../next_step_kind.dart';

/// `RecommendationEngine` qaytaradigan BITTA tavsiya (Module 5, Phase
/// 5C talabi: "Recommendation engine abstraction").
///
/// **Bu HUQUQIY MASLAHAT EMAS** (talab: "No final legal advice") --
/// tavsiya faqat JARAYON qadamini bildiradi ([kind], `NextStepKind`ga
/// qarang): qaysi ma'lumotni berish kerak, qachon ko'rib chiqish
/// kerak, qachon odam-mutaxassisga murojaat qilish kerak. Ishning
/// huquqiy istiqboli/natijasi haqida hech narsa aytilmaydi.
class Recommendation {
  const Recommendation({
    required this.id,
    required this.kind,
    required this.message,
    required this.order,
    this.requirementId,
  }) : assert(order >= 1, 'order 1 dan boshlanadi');

  final String id;
  final NextStepKind kind;

  /// Agar tavsiya aynan bitta ma'lumot bo'lagini to'ldirishga
  /// qaratilgan bo'lsa -- shu bo'lakning `InformationRequirement.id`si,
  /// aks holda `null`.
  ///
  /// Bu ishora ATAYLAB `id`dan alohida: chaqiruvchi (UI/backend)
  /// javobni to'g'ri kalit bilan yozishi uchun `id` matnini
  /// "ajratib olishi" (parsing) kerak bo'lmasin.
  final String? requirementId;

  /// Foydalanuvchiga ko'rsatiladigan matn -- **jarayon tili**
  /// ("... ma'lumotni to'ldiring"), huquqiy xulosa tili emas.
  final String message;

  /// 1'dan boshlanadigan MUHIMLIK/ketma-ketlik tartibi --
  /// `ActionPlanBuilder` aynan shu tartibga tayanadi (talab:
  /// "ordered next-step structure").
  final int order;

  /// Yetishmayotgan ma'lumot bo'lagi bilan bog'liq tavsiyami --
  /// `ActionPlanStep`ni progress bilan bog'lashda ishlatiladi.
  bool get isInformationRequest => kind == NextStepKind.collectInformation;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Recommendation &&
            other.id == id &&
            other.kind == kind &&
            other.message == message &&
            other.order == order &&
            other.requirementId == requirementId);
  }

  @override
  int get hashCode => Object.hash(id, kind, message, order, requirementId);

  @override
  String toString() => 'Recommendation(id: $id, kind: ${kind.name}, order: $order)';
}
