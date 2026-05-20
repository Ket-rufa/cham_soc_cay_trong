import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/l10n/language_controller.dart';
import 'package:cham_soc_cay_trong/top_toast_util.dart';
import 'package:flutter/material.dart';

class LanguageOptionsScreen extends StatelessWidget {
  const LanguageOptionsScreen({super.key});

  static const List<_LanguageOption> _options = <_LanguageOption>[
    _LanguageOption(code: 'vi', titleKey: 'languageOptions.vietnamese'),
    _LanguageOption(code: 'en', titleKey: 'languageOptions.english'),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        title: Text(context.tr('languageOptions.title')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.tr('languageOptions.subtitle'),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: _options
                    .map(
                      (option) => _LanguageOptionTile(
                        option: option,
                        selected: controller.isSelected(option.code),
                        onTap: () => _selectLanguage(context, option.code),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.tr('languageOptions.savedHint'),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String code) async {
    final message = context.tr('languageOptions.updated');
    await LanguageScope.of(context).setLanguageCode(code);

    if (!context.mounted) {
      return;
    }

    TopToast.show(
      context,
      message,
      icon: Icons.translate_rounded,
    );
    Navigator.pop(context);
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF25BB57);

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(
            context.tr(option.titleKey),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          subtitle: selected
              ? Text(
                  context.tr('languageOptions.current'),
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
          trailing: Radio<String>(
            value: option.code,
            groupValue: selected ? option.code : null,
            activeColor: primaryColor,
            onChanged: (_) => onTap(),
          ),
          onTap: onTap,
        ),
        if (option.code != LanguageOptionsScreen._options.last.code)
          Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.titleKey,
  });

  final String code;
  final String titleKey;
}
