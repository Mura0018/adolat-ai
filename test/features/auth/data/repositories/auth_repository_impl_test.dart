import 'dart:async';
import 'dart:io';

import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/features/auth/data/models/organization_profile_model.dart';
import 'package:adolat_ai/features/auth/data/models/profile_model.dart';
import 'package:adolat_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:adolat_ai/features/auth/domain/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/fake_auth_remote_datasource.dart';
import '../../../../helpers/result_matchers.dart';
import '../../../../helpers/supabase_fixtures.dart';

/// `AuthRepositoryImpl` -- `lib/features/`dagi eng mantiq zich qatlam
/// (219 qator): ikkita jadvalni bitta entity'ga birlashtirish, xom
/// exception'ni `Failure`ga aylantirish va sessiya holatini talqin
/// qilish shu yerda sodir bo'ladi.
///
/// 2026-07-30 auditining 2-topilmasi ("`lib/features/` uchun bitta ham
/// test yo'q") aynan shu qatlamdan boshlab yopiladi -- delegatsiyadan
/// iborat usecase'lardan emas, chunki xato qilish MUMKIN bo'lgan joy
/// shu yer.
ProfileModel _profile({String role = 'citizen'}) {
  return ProfileModel(
    id: 'user-1',
    role: role,
    fullName: 'Test Foydalanuvchi',
    phoneNumber: '+998901234567',
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-02T00:00:00.000Z',
  );
}

void main() {
  late FakeAuthRemoteDataSource remote;
  late AuthRepositoryImpl repository;

  setUp(() {
    remote = FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remote);
  });

  group('login', () {
    test('returns the merged AppUser on success', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = _profile();

      final result = await repository.login(identifier: '+998901234567', password: 'parol');

      final user = expectOk(result);
      expect(user.id, 'user-1');
      expect(user.role, UserRole.citizen);
      expect(user.fullName, 'Test Foydalanuvchi');
    });

    test('forwards the identifier and password verbatim', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = _profile();

      await repository.login(identifier: 'user@example.com', password: 'maxfiy');

      expect(remote.callOf('login')['identifier'], 'user@example.com');
      expect(remote.callOf('login')['password'], 'maxfiy');
    });

    test('returns a ServerFailure when Supabase returns no user', () async {
      remote.loginResponse = buildAuthResponseWithoutUser();

      final result = await repository.login(identifier: 'x', password: 'y');

      final failure = expectFailureOfType<dynamic, ServerFailure>(result);
      expect(failure.message, isNotEmpty);
      // Profil umuman o'qilmasligi kerak -- sessiya yo'q.
      expect(remote.fetchProfileCallCount, 0);
    });

    test('maps a network error to NetworkFailure', () async {
      remote.throwOnLogin = const SocketException('tarmoq yo\'q');

      final result = await repository.login(identifier: 'x', password: 'y');

      expectFailureOfType<dynamic, NetworkFailure>(result);
    });

    test('maps an RLS denial while reading the profile to PermissionDeniedFailure', () async {
      remote.loginResponse = buildAuthResponse();
      remote.throwOnFetchProfile = buildRlsDeniedException();

      final result = await repository.login(identifier: 'x', password: 'y');

      expectFailureOfType<dynamic, PermissionDeniedFailure>(result);
    });

    test('maps a missing profile row to a Failure instead of throwing', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = null; // profiles qatori hali yaratilmagan

      final result = await repository.login(identifier: 'x', password: 'y');

      // Muhimi: exception CHAQIRUVCHIGA chiqmaydi -- `Result.error`ga
      // aylanadi, aks holda presentation qatlami xom xatolik bilan
      // qolardi (docs/ARCHITECTURE.md, Exception -> Failure).
      expectFailure(result);
    });
  });

  group('verifyPhoneOtp', () {
    test('returns the AppUser when the code is accepted', () async {
      remote.verifyOtpResponse = buildAuthResponse();
      remote.profile = _profile();

      final result = await repository.verifyPhoneOtp(
        phoneNumber: '+998901234567',
        otpCode: '123456',
      );

      expect(expectOk(result).id, 'user-1');
    });

    test('returns a ServerFailure when no user comes back after verification', () async {
      remote.verifyOtpResponse = buildAuthResponseWithoutUser();

      final result = await repository.verifyPhoneOtp(phoneNumber: '+9989', otpCode: '000000');

      expectFailureOfType<dynamic, ServerFailure>(result);
    });

    test('maps a wrong-code AuthException to a ServerFailure carrying the status code', () async {
      remote.throwOnVerifyOtp = const AuthException('Invalid OTP', statusCode: '403');

      final result = await repository.verifyPhoneOtp(phoneNumber: '+9989', otpCode: 'xxx');

      final failure = expectFailureOfType<dynamic, ServerFailure>(result);
      expect(failure.code, '403');
    });
  });

  group('organization profile merge', () {
    test('reads organization_profiles only when the role is organization', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = _profile(role: 'organization');
      remote.organizationProfile = const OrganizationProfileModel(
        profileId: 'user-1',
        legalName: 'Test MChJ',
        taxId: '123456789',
        legalAddress: 'Toshkent',
      );

      final user = expectOk(await repository.login(identifier: 'x', password: 'y'));

      expect(remote.fetchOrganizationProfileCallCount, 1);
      expect(user.role, UserRole.organization);
      expect(user.organizationDetails?.legalName, 'Test MChJ');
    });

    test('does not touch organization_profiles for a citizen', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = _profile();

      final user = expectOk(await repository.login(identifier: 'x', password: 'y'));

      expect(remote.fetchOrganizationProfileCallCount, 0);
      expect(user.organizationDetails, isNull);
    });

    test('still returns the user when the organization row is missing', () async {
      remote.loginResponse = buildAuthResponse();
      remote.profile = _profile(role: 'organization');
      remote.organizationProfile = null;

      final user = expectOk(await repository.login(identifier: 'x', password: 'y'));

      // Foydalanuvchi kira oladi, faqat tafsilotlar bo'sh -- boshi berk
      // holat yaratilmaydi (DEVELOPMENT_RULES.md, 18-band).
      expect(user.organizationDetails, isNull);
    });
  });

  group('restoreSession', () {
    test('returns ok(null) when there is no stored session -- not an error', () async {
      remote.sessionToReturn = null;

      final result = await repository.restoreSession();

      // Bu MUHIM farq: sessiya yo'qligi xatolik EMAS, aks holda ilova
      // har ochilganda foydalanuvchiga xatolik ko'rsatilardi
      // (docs/UI.md, "App Entry Flow").
      expect(expectOk(result), isNull);
      expect(remote.fetchProfileCallCount, 0);
    });
  });

  group('pass-through operations', () {
    test('logout succeeds and reaches the datasource', () async {
      final result = await repository.logout();

      expectOk(result);
      expect(remote.wasCalled('logout'), isTrue);
    });

    test('logout maps a failure instead of throwing', () async {
      remote.throwOnLogout = const AuthException('sessiya topilmadi');

      expectFailure(await repository.logout());
    });

    test('registerCitizen forwards every field', () async {
      await repository.registerCitizen(
        password: 'parol',
        fullName: 'Ali Valiyev',
        phoneNumber: '+998901234567',
      );

      final call = remote.callOf('signUpCitizen');
      expect(call['fullName'], 'Ali Valiyev');
      expect(call['phoneNumber'], '+998901234567');
      expect(call['email'], isNull);
    });

    test('registerOrganization forwards the legal fields', () async {
      await repository.registerOrganization(
        password: 'parol',
        fullName: 'Ali Valiyev',
        legalName: 'Test MChJ',
        taxId: '123456789',
        legalAddress: 'Toshkent',
        email: 'org@example.com',
      );

      final call = remote.callOf('signUpOrganization');
      expect(call['legalName'], 'Test MChJ');
      expect(call['taxId'], '123456789');
      expect(call['legalAddress'], 'Toshkent');
    });

    test('a timeout during registration becomes a NetworkFailure', () async {
      remote.throwOnSignUp = TimeoutException('juda uzoq');

      final result = await repository.registerCitizen(password: 'p', fullName: 'A');

      expectFailureOfType<dynamic, NetworkFailure>(result);
    });
  });

  group('authStateChanges', () {
    test('emits null when the session is gone', () async {
      remote.authStateStream = Stream.fromIterable([
        const AuthState(AuthChangeEvent.signedOut, null),
      ]);

      expect(await repository.authStateChanges.first, isNull);
    });

    test('swallows a profile-read failure and emits null instead of an error', () async {
      remote.authStateStream = Stream.fromIterable([
        const AuthState(AuthChangeEvent.signedIn, null),
      ]);
      remote.throwOnFetchProfile = buildRlsDeniedException();

      // Oqim xatolik bilan yiqilmasligi kerak -- auth guard uni tinglaydi
      // va yiqilgan oqim navigatsiyani butunlay to'xtatib qo'yardi.
      expect(await repository.authStateChanges.first, isNull);
    });
  });
}
