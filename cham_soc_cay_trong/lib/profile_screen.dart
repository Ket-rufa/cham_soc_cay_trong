import 'dart:convert';
import 'dart:typed_data';

import 'package:cham_soc_cay_trong/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  const UserProfile({
    required this.displayName,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _userIdKey = 'userId';
  static const String _userNameKey = 'userName';
  static const String _userAvatarUrlKey = 'userAvatarUrl';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final Color _primaryColor = const Color(0xFF25BB57);
  final Color _backgroundColor = const Color(0xFFF5F8F3);

  UserProfile _profile = const UserProfile(displayName: 'Người dùng');
  Uint8List? _selectedAvatarBytes;
  String _selectedAvatarFileName = 'avatar.jpg';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String savedName =
        preferences.getString(_userNameKey)?.trim().isNotEmpty == true
            ? preferences.getString(_userNameKey)!.trim()
            : 'Người dùng';
    final String? avatarUrl = preferences.getString(_userAvatarUrlKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = UserProfile(displayName: savedName, avatarUrl: avatarUrl);
      _nameController.text = savedName;
      _isLoading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (pickedFile == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa chọn ảnh mới.'),
        ),
      );
      return;
    }

    final Uint8List imageBytes = await pickedFile.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatarBytes = imageBytes;
      _selectedAvatarFileName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : 'avatar.jpg';
    });
  }

  Future<void> _saveProfile() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final int? userId = preferences.getInt(_userIdKey);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy tài khoản đăng nhập.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.apiUrl}/profile/update'),
      );

      request.fields['user_id'] = userId.toString();
      request.fields['name'] = _nameController.text.trim();

      if (_selectedAvatarBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            _selectedAvatarBytes!,
            filename: _selectedAvatarFileName,
          ),
        );
      }

      final http.StreamedResponse streamedResponse = await request.send();
      final String responseBody = await streamedResponse.stream.bytesToString();
      final Map<String, dynamic> responseData =
          json.decode(responseBody) as Map<String, dynamic>;

      if (streamedResponse.statusCode != 200) {
        final String errorMessage = _extractErrorMessage(responseData);
        throw Exception(errorMessage);
      }

      final Map<String, dynamic> data =
          responseData['data'] as Map<String, dynamic>;
      final String updatedName = (data['name'] ?? _nameController.text).toString();
      final String? avatarUrl = data['avatar_url']?.toString();

      await preferences.setString(_userNameKey, updatedName);
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        await preferences.setString(_userAvatarUrlKey, avatarUrl);
      } else {
        await preferences.remove(_userAvatarUrlKey);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = UserProfile(displayName: updatedName, avatarUrl: avatarUrl);
        _nameController.text = updatedName;
        _selectedAvatarBytes = null;
      });

      Navigator.pop(context, 'Lưu thông tin cá nhân thành công');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _extractErrorMessage(Map<String, dynamic> responseData) {
    final dynamic errors = responseData['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final dynamic firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }

    return (responseData['message'] ?? 'Không thể cập nhật thông tin.')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ProfileAvatarSection(
                              avatarBytes: _selectedAvatarBytes,
                              avatarUrl: _profile.avatarUrl,
                              primaryColor: _primaryColor,
                              onChangeAvatar: _pickAvatar,
                            ),
                            const SizedBox(height: 24),
                            ProfileNameField(
                              controller: _nameController,
                              primaryColor: _primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SaveProfileButton(
                        isSaving: _isSaving,
                        primaryColor: _primaryColor,
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.avatarBytes,
    required this.avatarUrl,
    required this.primaryColor,
    required this.onChangeAvatar,
  });

  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final Color primaryColor;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.18),
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: _buildAvatarImage(),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: primaryColor,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: onChangeAvatar,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Cập nhật ảnh đại diện',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chọn ảnh từ thư viện để thay đổi hồ sơ của bạn',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (avatarBytes != null) {
      return Image.memory(
        avatarBytes!,
        fit: BoxFit.cover,
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        Config.getImageUrl(avatarUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/avatar.png',
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image.asset(
      'assets/avatar.png',
      fit: BoxFit.cover,
    );
  }
}

class ProfileNameField extends StatelessWidget {
  const ProfileNameField({
    super.key,
    required this.controller,
    required this.primaryColor,
  });

  final TextEditingController controller;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Tên người dùng',
        hintText: 'Nhập tên hiển thị của bạn',
        prefixIcon: Icon(Icons.person_outline, color: primaryColor),
        filled: true,
        fillColor: const Color(0xFFF7F9F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.4),
        ),
      ),
      validator: (String? value) {
        final String trimmedValue = value?.trim() ?? '';

        if (trimmedValue.isEmpty) {
          return 'Tên không được để trống';
        }

        if (trimmedValue.length < 2) {
          return 'Tên phải có tối thiểu 2 ký tự';
        }

        return null;
      },
    );
  }
}

class SaveProfileButton extends StatelessWidget {
  const SaveProfileButton({
    super.key,
    required this.isSaving,
    required this.primaryColor,
    required this.onPressed,
  });

  final bool isSaving;
  final Color primaryColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
