import 'package:memory_app/core/consent/consent_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoOpConsentService', () {
    test('reports consent as not required and no privacy options entry', () async {
      const service = NoOpConsentService();

      expect(await service.requestConsentIfNeeded(), ConsentStatus.notRequired);
      expect(service.currentStatus, ConsentStatus.notRequired);
      expect(service.isPrivacyOptionsFormAvailable, isFalse);

      // Must not throw even though there is nothing to show.
      await service.showPrivacyOptionsForm();
    });
  });

  test('consentRequestProvider resolves through whichever ConsentService is provided', () async {
    final container = ProviderContainer(
      overrides: [
        consentServiceProvider.overrideWithValue(const NoOpConsentService()),
      ],
    );
    addTearDown(container.dispose);

    final status = await container.read(consentRequestProvider.future);

    expect(status, ConsentStatus.notRequired);
  });
}
