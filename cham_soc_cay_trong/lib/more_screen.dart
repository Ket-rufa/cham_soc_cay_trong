import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/l10n/language_controller.dart';
import 'package:cham_soc_cay_trong/language_options_screen.dart';
import 'package:cham_soc_cay_trong/login/login_screen.dart';
import 'package:cham_soc_cay_trong/custom_dialog.dart';
import 'package:cham_soc_cay_trong/profile_screen.dart';
import 'package:cham_soc_cay_trong/terms_screen.dart';
import 'package:cham_soc_cay_trong/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.onProfileUpdated,
  });

  final ValueChanged<String> onProfileUpdated;

  final List<_MoreMenuItem> _menuItems = const <_MoreMenuItem>[
    _MoreMenuItem(id: 'profile', titleKey: 'settings.personalInfo'),
    _MoreMenuItem(id: 'reviews', titleKey: 'settings.reviews'),
    _MoreMenuItem(id: 'rate_app', titleKey: 'settings.rateApp'),
    _MoreMenuItem(id: 'terms', titleKey: 'settings.terms'),
    _MoreMenuItem(id: 'language', titleKey: 'settings.languageOptions'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.tr('settings.title'),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildLanguageInfoBanner(context),
              const SizedBox(height: 14),
              Divider(thickness: 1, color: Colors.grey[300]),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ..._menuItems.map(
                      (item) => _buildMenuItem(context, item),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: Text(
                          context.tr('settings.logout'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageInfoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.translate_rounded, color: Color(0xFF25BB57)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('settings.infoBanner'),
              style: const TextStyle(
                color: Color(0xFF1B5E20),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MoreMenuItem item) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(
            context.tr(item.titleKey),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_double_arrow_right,
            color: Colors.grey[400],
            size: 20,
          ),
          onTap: () => _handleMenuTap(context, item),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Future<void> _handleMenuTap(
    BuildContext context,
    _MoreMenuItem item,
  ) async {
    if (item.id == 'profile') {
      final String? successMessage = await Navigator.push<String>(
        context,
        MaterialPageRoute<String>(
          builder: (_) => const ProfileScreen(),
        ),
      );
      if (successMessage != null && successMessage.isNotEmpty) {
        onProfileUpdated(successMessage);
      }
      return;
    }

    if (item.id == 'terms') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const TermsScreen(),
        ),
      );
      return;
    }

    if (item.id == 'language') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const LanguageOptionsScreen(),
        ),
      );
      return;
    }

    TopToast.show(
      context,
      context.tr(
        'settings.featureInDevelopment',
        params: <String, String>{'feature': context.tr(item.titleKey)},
      ),
      backgroundColor: Colors.blueAccent,
      icon: Icons.info_outline,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final bool confirm = await PremiumDialog.showPremiumConfirmDialog(
      context: context,
      title: context.tr('settings.logout'),
      message: context.tr('settings.logoutConfirm'),
      confirmText: context.tr('settings.logout'),
      cancelText: context.tr('common.cancel'),
      isWarning: true,
    );

    if (!confirm) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final savedLanguageCode =
        preferences.getString(LanguageController.storageKey);
    await preferences.clear();
    if (savedLanguageCode != null && savedLanguageCode.isNotEmpty) {
      await preferences.setString(
        LanguageController.storageKey,
        savedLanguageCode,
      );
    }

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.id,
    required this.titleKey,
  });

  final String id;
  final String titleKey;
}
