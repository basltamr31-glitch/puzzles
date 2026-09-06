import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';

/// The player's chosen appearance — defaults to following the system
/// setting, but can be pinned to Light or Dark regardless of what the
/// device is set to (some players want the app dark even when their
/// phone's system theme is light, and vice versa).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final storage = ref.watch(localStorageServiceProvider);
    final stored = storage.getString(StorageKeys.themeMode);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> select(ThemeMode mode) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setString(StorageKeys.themeMode, mode.name);
    state = mode;
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
