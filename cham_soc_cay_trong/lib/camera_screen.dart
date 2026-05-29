import 'dart:ui';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cham_soc_cay_trong/main.dart'; // Để lấy biến cameras toàn cục
import 'package:cham_soc_cay_trong/plant_identify_result_screen.dart'; // Import màn hình AI
import 'package:cham_soc_cay_trong/disease_identify_result_screen.dart'; // Import màn hình nhận diện bệnh

class CameraScreen extends StatefulWidget {
  final bool initialDiseaseMode;
  const CameraScreen({Key? key, this.initialDiseaseMode = false}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.auto;
  late bool _isDiseaseMode;

  @override
  void initState() {
    super.initState();
    _isDiseaseMode = widget.initialDiseaseMode;
    _initCamera(_selectedCameraIndex);
  }

  // Khởi tạo Camera với index chỉ định
  Future<void> _initCamera(int cameraIndex) async {
    if (cameras.isEmpty) {
      print("Không tìm thấy camera nào!");
      return;
    }

    setState(() {
      _isCameraInitialized = false;
    });

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      
      // Cố gắng thiết lập flash mode mặc định nếu camera hỗ trợ
      try {
        await _controller!.setFlashMode(_currentFlashMode);
      } catch (e) {
        print("Đèn flash không khả dụng trên camera này: $e");
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _selectedCameraIndex = cameraIndex;
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

  // Thay đổi chế độ đèn flash
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_currentFlashMode) {
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.off;
        break;
      case FlashMode.off:
      default:
        nextMode = FlashMode.auto;
        break;
    }

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() {
        _currentFlashMode = nextMode;
      });
    } catch (e) {
      print("Lỗi thay đổi chế độ flash: $e");
    }
  }

  // Đổi giữa camera trước và sau
  Future<void> _toggleCamera() async {
    if (cameras.length < 2) return;
    int nextIndex = (_selectedCameraIndex + 1) % cameras.length;
    await _initCamera(nextIndex);
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickFromGallery() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _isDiseaseMode
                ? DiseaseIdentifyResultScreen(imageFile: pickedFile)
                : PlantIdentifyResultScreen(imageFile: pickedFile),
          ),
        );
      }
    } catch (e) {
      print("Lỗi khi chọn ảnh từ thư viện: $e");
    }
  }

  // Hàm chụp ảnh và chuyển trang
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
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
            builder: (context) => _isDiseaseMode
                ? DiseaseIdentifyResultScreen(imageFile: imageFile)
                : PlantIdentifyResultScreen(imageFile: imageFile),
          ),
        );
      }

      // 4. Khi quay lại thì tiếp tục chạy camera
      if (mounted && _controller != null) {
        _controller!.resumePreview();
      }
    } catch (e) {
      print("Lỗi chụp ảnh: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trường hợp không có camera (máy ảo hoặc chưa cấp quyền)
    if (cameras.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text("Nhận diện cây trồng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25BB57).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF25BB57),
                    size: 80,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Không phát hiện camera",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Thiết bị chưa phát hiện phần cứng camera hoặc quyền truy cập camera bị từ chối. Bạn có thể chọn ảnh có sẵn từ thư viện ảnh để nhận diện.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
                  label: const Text("Chọn ảnh từ thư viện", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25BB57),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: const Color(0xFF25BB57).withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Trường hợp đang tải camera
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF25BB57)),
              SizedBox(height: 16),
              Text(
                "Đang khởi động máy ảnh...",
                style: TextStyle(color: Colors.white70, fontSize: 15),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Màn hình Camera full-screen
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Lớp quét công nghệ cao phủ lên (Scanner Overlay Paint)
          const Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),

          // 3. Thanh điều khiển ở trên (Nút quay lại & Nút đèn Flash)
          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút quay lại
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),

                // Nút Đèn Flash
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _currentFlashMode == FlashMode.auto
                              ? Icons.flash_auto_rounded
                              : _currentFlashMode == FlashMode.always
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                          color: _currentFlashMode == FlashMode.off ? Colors.white : const Color(0xFF25BB57),
                        ),
                        onPressed: _toggleFlash,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Thanh chuyển chế độ (Nhận diện cây / Nhận diện bệnh)
          Positioned(
            bottom: 200,
            left: 40,
            right: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isDiseaseMode = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isDiseaseMode
                                  ? const Color(0xFF25BB57)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.eco_rounded,
                                  color: !_isDiseaseMode
                                      ? Colors.white
                                      : Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Nhận diện cây",
                                  style: TextStyle(
                                    color: !_isDiseaseMode
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isDiseaseMode = true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDiseaseMode
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.biotech_rounded,
                                  color: _isDiseaseMode
                                      ? Colors.white
                                      : Colors.white54,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Nhận diện bệnh",
                                  style: TextStyle(
                                    color: _isDiseaseMode
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4b. Hướng dẫn chụp kính mờ (Floating Info Glass Card)
          Positioned(
            bottom: 146,
            left: 32,
            right: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isDiseaseMode ? Icons.biotech_rounded : Icons.info_outline_rounded,
                        color: _isDiseaseMode ? Colors.redAccent : const Color(0xFF25BB57),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isDiseaseMode
                              ? "Hướng ống kính vào phần lá hoặc cây bị bệnh để AI phân tích"
                              : context.tr('camera.identifyHint'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Bảng điều khiển Dock dưới cùng (Thư viện - Chụp ảnh - Lật camera)
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Chọn từ Thư viện
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: GestureDetector(
                        onTap: _pickFromGallery,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nút Chụp ảnh phát sáng kép
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF25BB57).withOpacity(0.35), width: 6),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25BB57).withOpacity(0.4),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Color(0xFF25BB57),
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Đảo chiều camera (trước/sau)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: GestureDetector(
                        onTap: cameras.length < 2 ? null : _toggleCamera,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cameras.length < 2 ? Colors.black12 : Colors.black38,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Icon(
                            Icons.flip_camera_ios_rounded,
                            color: cameras.length < 2 ? Colors.white30 : Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp vẽ khung quét bo tròn nghệ thuật phát sáng
class ScannerOverlayPainter extends CustomPainter {
  const ScannerOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Tạo khung quét vuông bo tròn nằm giữa góc cao một chút
    final cutoutWidth = size.width * 0.76;
    final cutoutHeight = size.width * 0.76;
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2.3),
      width: cutoutWidth,
      height: cutoutHeight,
    );
    
    final innerPath = Path()..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(24)));
    
    // Kết hợp tạo mặt nạ đè mờ xung quanh và giữ độ sáng ở khung giữa
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(path, paint);

    // Vẽ viền thanh mảnh bao ngoài
    final borderPaint = Paint()
      ..color = const Color(0xFF25BB57).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(24)), borderPaint);

    // Vẽ 4 góc dày hơn tạo hiệu ứng khóa tiêu điểm (gương mặt quét)
    final cornerPaint = Paint()
      ..color = const Color(0xFF25BB57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final double cornerSize = 24.0;
    
    // Góc Trên-Trái
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.top + cornerSize)
        ..lineTo(cutoutRect.left, cutoutRect.top)
        ..lineTo(cutoutRect.left + cornerSize, cutoutRect.top),
      cornerPaint,
    );
    
    // Góc Trên-Phải
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerSize, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top)
        ..lineTo(cutoutRect.right, cutoutRect.top + cornerSize),
      cornerPaint,
    );

    // Góc Dưới-Trái
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.left, cutoutRect.bottom - cornerSize)
        ..lineTo(cutoutRect.left, cutoutRect.bottom)
        ..lineTo(cutoutRect.left + cornerSize, cutoutRect.bottom),
      cornerPaint,
    );

    // Góc Dưới-Phải
    canvas.drawPath(
      Path()
        ..moveTo(cutoutRect.right - cornerSize, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom)
        ..lineTo(cutoutRect.right, cutoutRect.bottom - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
