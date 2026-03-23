import 'package:cham_soc_cay_trong/login/login_screen.dart';
import 'package:cham_soc_cay_trong/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreScreen extends StatelessWidget {
  MoreScreen({
    super.key,
    required this.onProfileUpdated,
  });

  final ValueChanged<String> onProfileUpdated;

  final List<String> _menuTitles = const <String>[
    'Thông tin cá nhân',
    'Nhận xét',
    'Đánh giá ứng dụng',
    'Điều khoản & Dịch vụ',
    'Tùy chọn ngôn ngữ',
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
              const Text(
                'Cài đặt',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Divider(thickness: 1, color: Colors.grey[300]),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    ..._menuTitles.map(
                      (String title) => _buildMenuItem(context, title),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(
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

  Widget _buildMenuItem(BuildContext context, String title) {
    return Column(
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(
            title,
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
          onTap: () => _handleMenuTap(context, title),
        ),
        Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }

  Future<void> _handleMenuTap(BuildContext context, String title) async {
    if (title == 'Thông tin cá nhân') {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tính năng '$title' đang phát triển!")),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text(
              'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();

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
