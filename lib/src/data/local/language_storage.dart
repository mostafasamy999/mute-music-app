import 'package:shared_preferences/shared_preferences.dart';

/// Where the language choice lives on the device. No key means "follow the
/// phone".
class LanguageStorage {
  const LanguageStorage(this._prefs);

  static const String key = 'app_language';

  final SharedPreferences _prefs;

  String? read() => _prefs.getString(key);

  /// Null removes the choice.
  Future<bool> write(String? code) =>
      code == null ? _prefs.remove(key) : _prefs.setString(key, code);
}
