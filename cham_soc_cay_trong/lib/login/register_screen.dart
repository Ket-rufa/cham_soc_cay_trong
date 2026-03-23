import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/register'),
        body: {
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Đăng ký thành công -> Quay về màn đăng nhập
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Thành công"),
            content: Text("Đăng ký tài khoản thành công! Hãy đăng nhập."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Đóng popup
                  Navigator.pop(context); // Quay về màn Login
                },
                child: Text("OK"),
              )
            ],
          ),
        );
      } else {
        // Lỗi từ server (VD: Trùng email)
        String errorMsg = data['message'] ?? "Đăng ký thất bại";
        if(data['errors'] != null) errorMsg = data['errors'].toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
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
      appBar: AppBar(title: Text("Đăng Ký"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "Họ và Tên", icon: Icon(Icons.person))),
            SizedBox(height: 10),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: "Email", icon: Icon(Icons.email))),
            SizedBox(height: 10),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: "Mật khẩu", icon: Icon(Icons.lock)), obscureText: true),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50)),
                    child: Text("ĐĂNG KÝ", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}