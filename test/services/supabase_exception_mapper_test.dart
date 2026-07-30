import 'dart:async';
import 'dart:io';

import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/core/error/failure_presentation.dart';
import 'package:adolat_ai/services/supabase/supabase_exception_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `mapSupabaseExceptionToFailure` -- butun ilovadagi HAR BIR repository
/// metodining `catch` blokida chaqiriladigan yagona funksiya, ya'ni
/// foydalanuvchi ko'radigan xatolik xabarining boshlanish nuqtasi.
/// Shunga qaramay 2026-07-30 auditigacha testsiz edi.
///
/// Nega muhim: qaytadigan `Failure` TURI `failure_presentation.dart`da
/// foydalanuvchiga ko'rsatiladigan matnni va shu bilan "keyingi qadam"ni
/// belgilaydi (`DEVELOPMENT_RULES.md`, 17–19-band). Noto'g'ri tur --
/// masalan RLS rad etishini `unknown` deb belgilash -- foydalanuvchiga
/// noto'g'ri yo'l ko'rsatadi.
void main() {
  group('tarmoq xatoliklari', () {
    test('SocketException -> NetworkFailure', () {
      expect(
        mapSupabaseExceptionToFailure(const SocketException('ulanmadi')),
        isA<NetworkFailure>(),
      );
    });

    test('TimeoutException -> NetworkFailure', () {
      expect(
        mapSupabaseExceptionToFailure(TimeoutException('kutish vaqti tugadi')),
        isA<NetworkFailure>(),
      );
    });
  });

  group('Postgrest (RLS va server) xatoliklari', () {
    test('42501 (insufficient_privilege) -> PermissionDeniedFailure', () {
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );

      expect(failure, isA<PermissionDeniedFailure>());
    });

    test('PGRST301 -> PermissionDeniedFailure', () {
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      );

      expect(failure, isA<PermissionDeniedFailure>());
    });

    test('boshqa Postgrest kodi -> ServerFailure, kod saqlanadi', () {
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: 'duplicate key', code: '23505'),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, '23505');
    });

    test('kodsiz Postgrest xatoligi ham ServerFailure bo\'ladi', () {
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: 'noma\'lum'),
      );

      expect(failure, isA<ServerFailure>());
    });
  });

  group('Storage va Auth xatoliklari', () {
    test('StorageException -> StorageFailure', () {
      expect(
        mapSupabaseExceptionToFailure(const StorageException('fayl juda katta')),
        isA<StorageFailure>(),
      );
    });

    test('AuthException -> ServerFailure, statusCode saqlanadi', () {
      final failure = mapSupabaseExceptionToFailure(
        const AuthException('Invalid login credentials', statusCode: '400'),
      );

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).code, '400');
    });
  });

  group('zaxira (fallback) yo\'li', () {
    test('notanish xatolik -> UnknownFailure', () {
      expect(mapSupabaseExceptionToFailure(StateError('kutilmagan')), isA<UnknownFailure>());
    });

    test('har qanday kirish uchun HAR DOIM Failure qaytaradi, hech qachon tashlamaydi', () {
      final inputs = <Object>[
        'oddiy matn',
        42,
        Exception('umumiy'),
        StateError('holat'),
        const SocketException('tarmoq'),
      ];

      for (final input in inputs) {
        expect(
          () => mapSupabaseExceptionToFailure(input),
          returnsNormally,
          reason: '$input uchun mapper xatolik tashlamasligi kerak',
        );
      }
    });
  });

  group('xavfsizlik: xom matn foydalanuvchiga chiqmaydi', () {
    test('xom backend xabari userMessage orqali almashtiriladi', () {
      // docs/SECURITY.md, "API Security": DB struktura/stack trace
      // foydalanuvchiga ko'rsatilmaydi.
      const rawLeak = 'relation "public.appeals" does not exist at character 15';
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: rawLeak, code: '42P01'),
      );

      expect((failure as ServerFailure).message, rawLeak); // ichkarida saqlanadi
      expect(failure.userMessage, isNot(contains('public.appeals')));
      expect(failure.userMessage, isNotEmpty);
    });

    test('RLS rad etishi foydalanuvchiga tushunarli xabar beradi', () {
      final failure = mapSupabaseExceptionToFailure(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );

      expect(failure.userMessage, isNotEmpty);
      expect(failure.userMessage, isNot(contains('42501')));
    });
  });
}
