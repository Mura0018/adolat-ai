import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';

/// `data` qatlamidan kelgan Supabase-ga xos exception'larni umumiy,
/// backend'dan mustaqil `Failure`ga aylantiradi (docs/ARCHITECTURE.md,
/// "Ichki Kod Arxitekturasi" bo'limidagi `Exception → Failure`
/// konventsiyasiga muvofiq).
///
/// Ataylab `core/error/`da emas, shu yerda (`services/supabase/`) —
/// `core/` backend'dan mustaqil bo'lib qolishi kerak (`docs/architecture.md`
/// va'da qilingan "Supabase o'rniga boshqa backend kerak bo'lsa, faqat
/// data/ qatlami o'zgaradi" tamoyili); Supabase-ga xos xatolik turlarini
/// bilish esa aynan shu integratsiya qatlamining mas'uliyati.
///
/// Xom xatolik matni (`error`) faqat shu funksiyaga kiradi va faqat
/// **debug** rejimida (`kDebugMode`) konsolga chiqariladi — natijada
/// qaytadigan `Failure`ning o'zi xom matnni saqlashi mumkin (masalan
/// `ServerFailure.message`), lekin bu matn UI'da hech qachon to'g'ridan-
/// to'g'ri ko'rsatilmasligi shart (`core/error/failure_presentation.dart`,
/// `FailureUserMessage.userMessage` orqali xavfsiz muqobili ishlatiladi —
/// docs/SECURITY.md, "API Security" bo'limi).
Failure mapSupabaseExceptionToFailure(Object error) {
  if (kDebugMode) {
    debugPrint('Supabase exception ushlandi: $error');
  }

  if (error is SocketException || error is TimeoutException) {
    return const Failure.network();
  }

  if (error is PostgrestException) {
    // Postgres RLS rad etganda odatda '42501' (insufficient_privilege)
    // yoki PostgREST'ning o'z kodlaridan biri bilan keladi.
    if (error.code == '42501' || error.code == 'PGRST301') {
      return Failure.permissionDenied(message: error.message);
    }
    return Failure.server(message: error.message, code: error.code);
  }

  if (error is StorageException) {
    return Failure.storage(message: error.message);
  }

  if (error is AuthException) {
    return Failure.server(
      message: error.message,
      code: error.statusCode?.toString(),
    );
  }

  return Failure.unknown(message: error.toString());
}
