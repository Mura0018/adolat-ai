/// Uzoq davom etadigan AI so'rovini tashqaridan bekor qilish uchun
/// oddiy token (Module 4 talabi: "Cancellation support").
///
/// Freezed bilan emas — bu klass ataylab **o'zgaruvchan** (mutable) va
/// dinamik tinglovchilarga ega, immutable domain entity'lar naqshiga
/// mos kelmaydi (`AIMessage`/`AIConversation` kabi). Bitta so'rov
/// hayoti davomida bitta marta yaratiladi va tashlab yuboriladi —
/// qayta ishlatilmaydi.
class AICancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _isCancelled;

  /// Bekor qilingandan xabardor bo'lish uchun tinglovchi qo'shadi
  /// (masalan provayder adapter'i HTTP so'rovini to'xtatish uchun).
  void onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return;
    }
    _listeners.add(listener);
  }

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }
}
