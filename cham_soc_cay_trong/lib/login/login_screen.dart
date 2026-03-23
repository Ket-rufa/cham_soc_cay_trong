import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // Để lưu đăng nhập
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/home_screen.dart'; // Màn hình chính
import 'package:cham_soc_cay_trong/login/register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/login'),
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // 1. Lưu thông tin user vào bộ nhớ máy
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', data['data']['id']); // Lưu ID quan trọng nhất
        await prefs.setString('userName', data['data']['name']);
        final String? avatarUrl = data['data']['avatar_url']?.toString();
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          await prefs.setString('userAvatarUrl', avatarUrl);
        } else {
          await prefs.remove('userAvatarUrl');
        }

        // 2. Chuyển vào màn hình chính
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sai email hoặc mật khẩu"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_florist, size: 80, color: Colors.green),
                SizedBox(height: 10),
                Text("Chăm Sóc Cây Trồng", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                SizedBox(height: 40),
                
                TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
                SizedBox(height: 16),
                TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)), obscureText: true),
                
                SizedBox(height: 24),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50)),
                        child: Text("ĐĂNG NHẬP", style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => RegisterScreen()));
                  },
                  child: Text("Chưa có tài khoản? Đăng ký ngay", style: TextStyle(color: Colors.blue)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
