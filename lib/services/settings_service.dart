import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';

class SettingsService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<ThemeConfig> getThemeConfig() async {
    final base = await _storage.read(key: 'theme_base') ?? 'dark';
    final accent = await _storage.read(key: 'theme_accent') ?? 'blue';
    return ThemeConfig(baseTheme: base, accentColor: accent);
  }

  Future<void> saveThemeConfig(ThemeConfig config) async {
    await _storage.write(key: 'theme_base', value: config.baseTheme);
    await _storage.write(key: 'theme_accent', value: config.accentColor);
  }

  Future<bool> isAppLockEnabled() async {
    final val = await _storage.read(key: 'app_lock_enabled');
    return val == 'true';
  }

  Future<void> setAppLockEnabled(bool isEnabled) async {
    await _storage.write(key: 'app_lock_enabled', value: isEnabled.toString());
  }

  Future<String> getCursorStyle() async {
    return await _storage.read(key: 'cursor_style') ?? 'Block';
  }

  Future<void> setCursorStyle(String style) async {
    await _storage.write(key: 'cursor_style', value: style);
  }
}