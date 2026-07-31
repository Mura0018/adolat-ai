import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supabase_client.dart';

/// Joriy foydalanuvchi identifikatorini beruvchi funksiya.
///
/// **Nega funksiya qaytariladi, `String?` emas:** qiymat vaqt
/// o'tishi bilan o'zgaradi (kirish/chiqish), lekin uni iste'mol
/// qiluvchi obyektlar (masalan `OfflineFirstAppealsRepository`) bir
/// marta quriladi. Funksiya har chaqiruvda joriy holatni o'qiydi,
/// ya'ni repozitoriyni qayta qurish shart emas.
///
/// **Nega alohida provayder:** Module 7D DI testlari ko'rsatdiki,
/// `SupabaseService.client`ni repozitoriy quruvchi kod ichida
/// TO'G'RIDAN-TO'G'RI chaqirish kompozitsiyani sinovdan o'tkazib
/// bo'lmaydigan qiladi — Supabase ishga tushirilmagan muhitda
/// (ya'ni har qanday testda) u assertion bilan yiqiladi. Provayder
/// orqali esa u override qilinadi va offline qatlamining ulanishi
/// haqiqiy backend'siz tekshiriladi.
final currentUserIdProvider = Provider<String? Function()>((ref) {
  return () => SupabaseService.client.auth.currentUser?.id;
});
