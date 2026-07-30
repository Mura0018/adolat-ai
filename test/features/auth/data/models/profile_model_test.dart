import 'package:adolat_ai/features/auth/data/models/organization_profile_model.dart';
import 'package:adolat_ai/features/auth/data/models/profile_model.dart';
import 'package:adolat_ai/features/auth/domain/entities/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/supabase_fixtures.dart';

/// DTO ↔ entity chegarasi: `profiles` jadvalining snake_case ustunlari
/// bilan Dart'ning camelCase maydonlari o'rtasidagi xaritalash.
///
/// Nega test kerak: `@JsonKey(name: 'full_name')` kabi annotatsiyadagi
/// bitta harf xatosi kompilyatsiyada emas, faqat ISH VAQTIDA (profil
/// bo'sh ko'rinishi bilan) bilinadi -- ya'ni aynan avtomatik test
/// ushlashi kerak bo'lgan xato turi.
void main() {
  group('ProfileModel.fromJson', () {
    test('maps every snake_case column to its field', () {
      final model = ProfileModel.fromJson(buildProfileJson());

      expect(model.id, 'user-1');
      expect(model.role, 'citizen');
      expect(model.fullName, 'Test Foydalanuvchi');
      expect(model.phoneNumber, '+998901234567');
      expect(model.createdAt, '2026-01-01T00:00:00.000Z');
      expect(model.updatedAt, '2026-01-02T00:00:00.000Z');
    });

    test('accepts null for the optional columns', () {
      final model = ProfileModel.fromJson(
        buildProfileJson(phoneNumber: null, avatarUrl: null),
      );

      expect(model.phoneNumber, isNull);
      expect(model.avatarUrl, isNull);
    });

    test('survives a JSON round trip unchanged', () {
      final original = ProfileModel.fromJson(buildProfileJson());

      expect(ProfileModel.fromJson(original.toJson()), original);
    });
  });

  group('ProfileModelX.toEntity', () {
    test('parses the role and the timestamps into domain types', () {
      final user = ProfileModel.fromJson(buildProfileJson()).toEntity();

      expect(user.role, UserRole.citizen);
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(user.updatedAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
    });

    test('maps the organization role and attaches the supplied details', () {
      final user = ProfileModel.fromJson(buildProfileJson(role: 'organization')).toEntity(
        organizationDetails: const OrganizationProfileModel(
          profileId: 'user-1',
          legalName: 'Test MChJ',
          taxId: '123456789',
          legalAddress: 'Toshkent',
        ).toEntity(),
      );

      expect(user.role, UserRole.organization);
      expect(user.organizationDetails?.legalName, 'Test MChJ');
      expect(user.organizationDetails?.taxId, '123456789');
    });

    test('an unknown role value fails loudly instead of defaulting silently', () {
      // Jimgina `citizen`ga tushib qolish XAVFLI bo'lardi: admin
      // huquqlari noto'g'ri talqin qilinishi mumkin
      // (docs/SECURITY.md, "Avtorizatsiya").
      final model = ProfileModel.fromJson(buildProfileJson(role: 'superuser'));

      expect(() => model.toEntity(), throwsArgumentError);
    });
  });

  group('UserRole.fromDbValue', () {
    test('maps every documented database value', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromDbValue(role.dbValue), role);
      }
    });
  });
}
