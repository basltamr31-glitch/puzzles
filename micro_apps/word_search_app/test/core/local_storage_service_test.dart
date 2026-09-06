import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips string, bool, and int values', () async {
    final service = await SharedPreferencesStorageService.create();

    await service.setString('name', 'word search');
    await service.setBool('flag', true);
    await service.setInt('count', 3);

    expect(service.getString('name'), 'word search');
    expect(service.getBool('flag'), isTrue);
    expect(service.getInt('count'), 3);
  });

  test('returns null for missing keys', () async {
    final service = await SharedPreferencesStorageService.create();

    expect(service.getString('missing'), isNull);
    expect(service.getBool('missing'), isNull);
    expect(service.getInt('missing'), isNull);
  });

  test('remove clears a key', () async {
    final service = await SharedPreferencesStorageService.create();
    await service.setString('name', 'word search');

    await service.remove('name');

    expect(service.getString('name'), isNull);
  });
}
