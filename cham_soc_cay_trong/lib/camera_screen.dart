import 'dart:io';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cham_soc_cay_trong/main.dart'; // Để lấy biến cameras toàn cục
import 'package:cham_soc_cay_trong/plant_identify_result_screen.dart'; // Import màn hình AI

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  // Khởi tạo Camera
  Future<void> _initCamera() async {
    // Lấy danh sách camera từ biến toàn cục (được khởi tạo ở main.dart)
    if (cameras.isEmpty) {
      print("Không tìm thấy camera nào!");
      return;
    }

    // Chọn camera sau (index 0 thường là camera sau)
    _controller = CameraController(cameras[0], ResolutionPreset.high);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Lỗi khởi tạo camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Hàm chụp ảnh và chuyển trang
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      // 1. Chụp ảnh
      XFile imageFile = await _controller!.takePicture();

      // 2. Dừng hình lại cho giống chụp xong
      await _controller!.pausePreview();

      // 3. Chuyển sang màn hình Kết quả (AI)
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PlantIdentifyResultScreen(imageFile: File(imageFile.path)),
          ),
        );
      }

      // 4. Khi quay lại thì tiếp tục chạy camera
      _controller!.resumePreview();
    } catch (e) {
      print("Lỗi chụp ảnh: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Màn hình Camera full
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Nút Back (Về trang chủ)
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Nút Chụp ảnh (Ở giữa dưới cùng)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Dòng chữ hướng dẫn
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              context.tr('camera.identifyHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
