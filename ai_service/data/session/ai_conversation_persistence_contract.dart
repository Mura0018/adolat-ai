import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_conversation_status.dart';
import '../../domain/entities/ai_message.dart';

/// `AIConversation`/`AIMessage`ning DURABLE (barqaror, xotiradan
/// tashqari) saqlash shakli (Module 4, Phase 4B talabi: "Conversation
/// persistence contract").
///
/// **Nega hozir kerak:** `InMemoryConversationRepository` (Phase 2A)
/// bitta process instance ichida ishlaydi -- suhbat holati server
/// qayta ishga tushganda yo'qoladi. Bu ATAYLAB, foundation bosqichi
/// uchun yetarli edi -- lekin haqiqiy backend qurilganda
/// `ConversationRepository`ning DB-asosli implementatsiyasi kerak
/// bo'ladi. Bu fayl o'sha kelgusi implementatsiya mos kelishi kerak
/// bo'lgan saqlash SHAKLINI oldindan belgilaydi -- `docs/DATABASE.md`
/// konventsiyalariga muvofiq (mutually exclusive FK naqsh, egalik
/// asosidagi RLS andozasi), lekin hali hech qanday SQL/migratsiya
/// yozilmagan (talab: "Do NOT implement Edge Functions/HTTP").
///
/// **`docs/DATABASE.md`da HALI YO'Q jadvallar:** `ai_analyses`
/// (8-jadval) faqat AI tahlilining YAKUNIY natijasini saqlaydi --
/// to'liq suhbat tarixini (savol-javob ketma-ketligi) emas. Shu
/// sababli bu kontrakt ikkita YANGI (hali migratsiya qilinmagan)
/// jadval shaklini nazarda tutadi: `ai_conversations` va
/// `ai_conversation_messages` -- amalga oshirilganda `docs/DATABASE.md`ga
/// rasmiy jadval sifatida qo'shilishi shart (`DEVELOPMENT_RULES.md`,
/// 9-band: "Har bir API va Database o'zgarishi hujjatlashtiriladi").
class AIConversationRecord {
  const AIConversationRecord({
    required this.id,
    required this.userId,
    this.appealId,
    this.disputeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(
         appealId == null || disputeId == null,
         'appealId va disputeId bir vaqtda to\'ldirilishi mumkin emas -- '
         'docs/DATABASE.md, "Mutually exclusive FK" naqshi',
       );

  final String id;

  /// Suhbat egasi -- RLS ("faqat egasi ko'radi", `docs/DATABASE.md`,
  /// "RLS umumiy strategiyasi") uchun majburiy. `AIConversation`ning
  /// o'zida yo'q (`domain/entities/ai_conversation.dart`: "bu klass
  /// shaxsan qaysi appeal/disputega tegishli ekanligini bilmaydi" bilan
  /// bir xil sabab -- egalik domain entity emas, saqlash qatlami
  /// mas'uliyati).
  final String userId;

  /// Ixtiyoriy -- suhbat umumiy (hech qanday murojaat/nizoga
  /// bog'lanmagan) bo'lishi mumkin, xuddi `CaseContext`ning o'zi ham
  /// ixtiyoriy bo'lgani kabi (`ContextAssembler`, Phase 2B).
  final String? appealId;
  final String? disputeId;

  final AIConversationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  String toString() => 'AIConversationRecord(id: $id, userId: $userId, status: $status)';
}

class AIConversationMessageRecord {
  const AIConversationMessageRecord({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.sequence,
    required this.createdAt,
  }) : assert(sequence >= 0, 'sequence manfiy bo\'lishi mumkin emas');

  final String id;
  final String conversationId;
  final AIMessageRole role;
  final String content;

  /// Suhbat ichidagi tartib -- `AIConversation.messages`ning ro'yxat
  /// tartibi DBda `ORDER BY created_at`ga tayanmasligi uchun (bir xil
  /// millisekundda ikkita yozuv kelib qolishi mumkin) aniq ustun
  /// sifatida saqlanadi.
  final int sequence;
  final DateTime createdAt;

  @override
  String toString() =>
      'AIConversationMessageRecord(id: $id, conversationId: $conversationId, sequence: $sequence)';
}

/// `AIConversation`/`AIMessage` (domain, xotiradagi shakl) <->
/// [AIConversationRecord]/[AIConversationMessageRecord] (durable
/// saqlash shakli) orasidagi tarjima CHEGARASI -- **faqat interfeys,
/// hech qanday implementatsiya yo'q** (`AISafetyService` konventsiyasi,
/// Phase 1'dan beri).
///
/// Haqiqiy `ConversationRepository` implementatsiyasi (masalan
/// Supabase-asosli) bu tarjimani ICHKI ravishda ishlatishi
/// mo'ljallangan -- `ConversationRepository`ning o'zi
/// (`domain/repositories/conversation_repository.dart`) hech qachon bu
/// turlarni bilmaydi, faqat domain entity bilan ishlaydi (Clean
/// Architecture: saqlash tafsiloti domain qatlamiga sizib chiqmaydi).
abstract interface class AIConversationPersistenceMapper {
  AIConversationRecord toRecord(
    AIConversation conversation, {
    required String userId,
    String? appealId,
    String? disputeId,
  });

  AIConversation fromRecord(
    AIConversationRecord record,
    List<AIConversationMessageRecord> messages,
  );
}
