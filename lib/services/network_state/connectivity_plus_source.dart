import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_source.dart';

/// `ConnectivitySource`ning `connectivity_plus` ustidagi
/// implementatsiyasi (`docs/adr/ADR-008-network-signal-source.md`).
///
/// **Ataylab imkon qadar YUPQA.** Bu — loyihadagi yagona joy bo'lib,
/// u `connectivity_plus` paketini biladi. Butun qolgan mantiq
/// (holatlarni birlashtirish, o'tishlarni aniqlash, sinxronizatsiyani
/// ishga tushirish) paketdan mustaqil va testlar bilan qoplangan.
/// Paket kelajakda almashtirilsa, o'zgaradigan yagona fayl — shu.
///
/// **Sinov qamrovidan tashqarida:** bu klass platforma kanaliga
/// tayanadi, shuning uchun `flutter test` (emulatorsiz) uni ishga
/// tushira olmaydi. Shu sababli u yerda hech qanday QAROR qabul
/// qilinmaydi — faqat `List<ConnectivityResult>` → `bool` xaritalash
/// bor, va u bitta ifodaga jamlangan.
class ConnectivityPlusSource implements ConnectivitySource {
  ConnectivityPlusSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Ro'yxatda `none`dan boshqa biror natija bo'lsa — interfeys
  /// ko'tarilgan.
  ///
  /// `connectivity_plus` 6+ versiyalarida bir vaqtda bir nechta
  /// natija qaytishi mumkin (masalan Wi-Fi + mobil), shuning uchun
  /// ro'yxat tekshiriladi, bitta qiymat emas.
  static bool _isUp(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Future<bool> isInterfaceUp() async {
    return _isUp(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get interfaceChanges {
    return _connectivity.onConnectivityChanged.map(_isUp);
  }
}
