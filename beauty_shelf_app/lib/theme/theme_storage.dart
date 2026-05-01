// Abstract storage interface
abstract class ThemeStorage {
  String? get(String key);
  void set(String key, String value);
  void remove(String key);
}

// Web implementation using localStorage
class WebThemeStorage implements ThemeStorage {
  @override
  String? get(String key) {
    // ignore: avoid_web_libraries
    // ignore: undefined_identifier
    // ignore: undefined_class
    return null; // Will be replaced by conditional import
  }

  @override
  void set(String key, String value) {}

  @override
  void remove(String key) {}
}

// Mobile implementation using SharedPreferences
class MobileThemeStorage implements ThemeStorage {
  @override
  String? get(String key) => null;

  @override
  void set(String key, String value) {}

  @override
  void remove(String key) {}
}
