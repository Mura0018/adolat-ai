/// Bitta so'rov uchun autentifikatsiya natijasi (Module 4, Phase 3B
/// talabi: "Authentication Boundary").
///
/// `AIAuthenticator.authenticate()`ning qaytish qiymati -- transport
/// darajasidagi xom hisob ma'lumoti (masalan HTTP `Authorization`
/// sarlavhasi) allaqachon TEKSHIRILGANDAN keyingi natija. `gateway/`
/// ichkarisida (masalan `AIRequestDispatcher`) shu klass orqali
/// ishlaydi -- xom token/JWT haqida hech narsa bilmaydi.
class AIAuthContext {
  const AIAuthContext({
    required this.isAuthenticated,
    this.userId,
    this.claims = const {},
  });

  /// Muvaffaqiyatsiz autentifikatsiya uchun qulaylik konstantasi.
  static const unauthenticated = AIAuthContext(isAuthenticated: false);

  final bool isAuthenticated;

  /// `isAuthenticated == true` bo'lganda majburiy ma'noda to'ldiriladi
  /// (lekin turi darajasida majburlanmagan -- `AIAuthenticator`
  /// implementatsiyasi buni kafolatlashi kerak).
  final String? userId;

  /// Kelgusida rol/ruxsat kabi qo'shimcha da'volar (claims) uchun
  /// kengaytiriladigan joy -- hozircha hech kim to'ldirmaydi/o'qimaydi.
  final Map<String, dynamic> claims;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIAuthContext) return false;
    return other.isAuthenticated == isAuthenticated &&
        other.userId == userId &&
        other.claims.toString() == claims.toString();
  }

  @override
  int get hashCode => Object.hash(isAuthenticated, userId, claims.toString());

  @override
  String toString() =>
      'AIAuthContext(isAuthenticated: $isAuthenticated, userId: $userId)';
}
