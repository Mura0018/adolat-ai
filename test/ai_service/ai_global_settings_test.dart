import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_global_settings.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';

void main() {
  group('AIGlobalSettings', () {
    test('round-trips through JSON, including maintenanceMessage', () {
      const settings = AIGlobalSettings(
        aiFeatureEnabled: false,
        defaultProviderId: AIProviderId.openAI,
        maintenanceMessage: 'Texnik xizmat ko\'rsatilmoqda',
      );

      final decoded = AIGlobalSettings.fromJson(settings.toJson());

      expect(decoded, settings);
    });

    test('round-trips without a maintenanceMessage', () {
      const settings = AIGlobalSettings(
        aiFeatureEnabled: true,
        defaultProviderId: AIProviderId.claude,
      );

      final decoded = AIGlobalSettings.fromJson(settings.toJson());

      expect(decoded, settings);
      expect(decoded.maintenanceMessage, isNull);
    });
  });
}
