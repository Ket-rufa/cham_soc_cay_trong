import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const String storageKey = 'selected_language_code';

  Locale _locale = AppLocalizations.fallbackLocale;

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(storageKey);
    _locale = _localeFromCode(savedCode);
  }

  Future<void> setLanguageCode(String code) async {
    final nextLocale = _localeFromCode(code);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, nextLocale.languageCode);

    if (_locale.languageCode == nextLocale.languageCode) {
      return;
    }

    _locale = nextLocale;
    notifyListeners();
  }

  bool isSelected(String code) => languageCode == code;

  static Locale _localeFromCode(String? code) {
    if (AppLocalizations.isSupportedCode(code)) {
      return Locale(code!);
    }
    return AppLocalizations.fallbackLocale;
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
