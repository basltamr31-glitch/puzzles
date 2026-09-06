import 'package:word_search_app/core/ads/ad_policy.dart';
import 'package:word_search_app/core/storage/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('never shows an interstitial for premium (ads-removed) users', () async {
    final storage = await SharedPreferencesStorageService.create();
    final policy = AdPolicy(storage, () => true);

    await policy.recordPuzzleCompleted();
    await policy.recordPuzzleCompleted();
    await policy.recordPuzzleCompleted();

    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isFalse);
  });

  test('never shows an interstitial for triggers other than puzzle completion', () {
    final storage = _syncFakeStorage();
    final policy = AdPolicy(storage, () => false);

    expect(policy.shouldShowInterstitial(trigger: 'app_open'), isFalse);
  });

  test('waits for AppConfig.interstitialMinPuzzlesBetween completions', () async {
    final storage = await SharedPreferencesStorageService.create();
    final policy = AdPolicy(storage, () => false);

    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isFalse);
    await policy.recordPuzzleCompleted();
    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isFalse);
    await policy.recordPuzzleCompleted();
    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isTrue);
  });

  test('recordInterstitialShown resets the counter', () async {
    final storage = await SharedPreferencesStorageService.create();
    final policy = AdPolicy(storage, () => false);

    await policy.recordPuzzleCompleted();
    await policy.recordPuzzleCompleted();
    await policy.recordInterstitialShown();

    expect(policy.shouldShowInterstitial(trigger: 'puzzle_completed'), isFalse);
  });
}

LocalStorageService _syncFakeStorage() {
  final values = <String, Object>{};
  return _InMemoryStorage(values);
}

class _InMemoryStorage implements LocalStorageService {
  _InMemoryStorage(this._values);
  final Map<String, Object> _values;

  @override
  bool? getBool(String key) => _values[key] as bool?;
  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _values[key] as int?;
  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _values[key] as String?;
  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }
}
