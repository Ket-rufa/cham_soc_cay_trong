import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations._({
    required this.locale,
    required Map<String, dynamic> localizedValues,
    required Map<String, dynamic> fallbackValues,
  })  : _localizedValues = localizedValues,
        _fallbackValues = fallbackValues;

  static const Locale fallbackLocale = Locale('vi');
  static const List<Locale> supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Locale locale;
  final Map<String, dynamic> _localizedValues;
  final Map<String, dynamic> _fallbackValues;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations._(
          locale: fallbackLocale,
          localizedValues: <String, dynamic>{},
          fallbackValues: <String, dynamic>{},
        );
  }

  static bool isSupportedCode(String? code) {
    return supportedLocales.any((locale) => locale.languageCode == code);
  }

  static Locale normalize(Locale locale) {
    if (isSupportedCode(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
    return fallbackLocale;
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final normalizedLocale = normalize(locale);
    final fallbackValues = await _loadLocaleMap(fallbackLocale.languageCode);
    final localizedValues =
        normalizedLocale.languageCode == fallbackLocale.languageCode
            ? fallbackValues
            : await _loadLocaleMap(normalizedLocale.languageCode);

    return AppLocalizations._(
      locale: normalizedLocale,
      localizedValues: localizedValues,
      fallbackValues: fallbackValues,
    );
  }

  String t(String key,
      {Map<String, String> params = const <String, String>{}}) {
    final value =
        _lookup(_localizedValues, key) ?? _lookup(_fallbackValues, key) ?? key;

    var text = value is String ? value : key;
    for (final entry in params.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }

  static Future<Map<String, dynamic>> _loadLocaleMap(
      String languageCode) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/translations/$languageCode.json');
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{};
  }

  static dynamic _lookup(Map<String, dynamic> source, String key) {
    dynamic current = source;
    for (final segment in key.split('.')) {
      if (current is! Map || !current.containsKey(segment)) {
        return null;
      }
      current = current[segment];
    }
    return current;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.isSupportedCode(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  String tr(
    String key, {
    Map<String, String> params = const <String, String>{},
  }) {
    return AppLocalizations.of(this).t(key, params: params);
  }
}
