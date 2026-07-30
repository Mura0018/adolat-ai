/// Ilova nuqtai nazaridan tarmoq holati (`docs/ARCHITECTURE.md`,
/// "Network State Handling").
///
/// **Nega faqat ikkita qiymat:** hujjat aniq belgilaydi — *"ilova
/// kamida ikkita asosiy holatni farqlaydi"*, va *"qurilmaning
/// tarmoqqa umuman ulanmagani"* hamda *"qurilma ulangan-u, ammo
/// backend'ga yeta olmayotgani"* — **ikkalasi ham bir xil "hozircha
/// yuborib bo'lmaydi" xatti-harakatini talab qiladi**. Shuning uchun
/// bu yerda "wifi/mobil/ethernet" kabi TEXNIK tafsilot ataylab
/// modellashtirilmagan: u ilova xatti-harakatiga ta'sir qilmaydi va
/// faqat noto'g'ri qarorlarga yo'l ochardi (masalan "wifi bor, demak
/// server ham bor" degan taxminga).
enum NetworkStatus {
  /// Tarmoq mavjud va backend'ga so'rov yuborish mumkin deb
  /// hisoblanadi.
  online,

  /// Tarmoq yo'q YOKI backend'ga yetib bo'lmayapti — ikkalasi ham
  /// bir xil xatti-harakat.
  offline;

  bool get isOnline => this == NetworkStatus.online;

  bool get isOffline => this == NetworkStatus.offline;
}

/// Tarmoq holatining O'ZGARISHI — nimadan nimaga.
///
/// Alohida tur sifatida mavjud, chunki `docs/ARCHITECTURE.md`
/// ("Network State Handling" → *"Holat o'zgarishiga reaksiya"*)
/// reaksiyani aynan O'TISHGA bog'laydi: sinxronizatsiya "hozir
/// onlayn" bo'lgani uchun emas, **oflayndan onlaynga o'tgani** uchun
/// ishga tushadi. Bu farq muhim — aks holda har bir holat xabari
/// keraksiz sinxronizatsiya sikliga sabab bo'lardi.
class NetworkStatusChange {
  const NetworkStatusChange({required this.previous, required this.current});

  final NetworkStatus previous;
  final NetworkStatus current;

  /// Oflayndan onlaynga o'tildi — Sync Engine'ni ishga tushirish
  /// uchun YAGONA tarmoq sababi.
  bool get isRestored => previous.isOffline && current.isOnline;

  /// Onlayndan oflaynga o'tildi.
  bool get isLost => previous.isOnline && current.isOffline;

  /// Holat aslida o'zgardimi.
  bool get isChanged => previous != current;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NetworkStatusChange &&
            other.previous == previous &&
            other.current == current);
  }

  @override
  int get hashCode => Object.hash(previous, current);

  @override
  String toString() => 'NetworkStatusChange(${previous.name} -> ${current.name})';
}
