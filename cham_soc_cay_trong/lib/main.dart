import 'package:flutter/material.dart';
// Import đúng đường dẫn file Login
import 'package:cham_soc_cay_trong/login/login_screen.dart'; 

// Khai báo biến camera toàn cục (giữ nguyên code cũ của bạn)
import 'package:camera/camera.dart';
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chăm Sóc Cây Trồng',
      theme: ThemeData(
        primarySwatch: Colors.green,
        // Có thể thêm font hoặc màu sắc tùy ý
      ),
      // SỬA Ở ĐÂY: Chạy màn hình Đăng nhập đầu tiên
      home: LoginScreen(), 
    );
  }
}