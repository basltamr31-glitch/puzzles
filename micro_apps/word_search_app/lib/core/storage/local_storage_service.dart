import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstraction over local key-value persistence.
///
/// Every feature depends on this interface, never on `SharedPreferences`
/// directly, so the backing store can be swapped or mocked in tests without
/// touching feature code.
abstract class LocalStorageService {
  String? getString(String key);
  Future<bool> setString(String key, String value);

  bool? getBool(String key);
  Future<bool> setBool(String key, bool value);

  int? getInt(String key);
  Future<bool> setInt(String key, int value);

  Future<bool> remove(String key);
}

class SharedPreferencesStorageService implements LocalStorageService {
  SharedPreferencesStorageService(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorageService(prefs);
  }

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  int? getInt(String key) => _prefs.getInt(key);

  @override
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);
}

/// Overridden in `main.dart` with the real instance once async init
/// completes. Left unimplemented here on purpose: reading it before
/// override is a programmer error and should fail loudly.
final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => throw UnimplementedError(
    'localStorageServiceProvider must be overridden in main() after '
    'SharedPreferencesStorageService.create()',
  ),
);
