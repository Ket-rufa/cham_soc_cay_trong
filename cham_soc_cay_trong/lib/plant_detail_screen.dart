import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';

class PlantDetailScreen extends StatefulWidget {
  final int plantId; // Nhận ID cây từ màn hình danh sách

  const PlantDetailScreen({Key? key, required this.plantId}) : super(key: key);

  @override
  _PlantDetailScreenState createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  Map<String, dynamic>? _plantData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantDetails();
  }

  // Hàm gọi API lấy chi tiết cây + lịch sử
  Future<void> _fetchPlantDetails() async {
    try {
      // 2. SỬA QUAN TRỌNG: Gọi theo ID của cây (widget.plantId)
      // Thay vì lấy toàn bộ danh sách, ta chỉ lấy thông tin của đúng cây này
      final url = Uri.parse('${Config.apiUrl}/plants/${widget.plantId}');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        // Tùy vào cấu trúc API trả về, nếu API trả về { "data": {...} } thì dùng:
        // Nếu API trả về trực tiếp object thì bỏ ['data']
        // Ở đây giả định backend trả về chuẩn: { "status": 200, "data": { ... } }
        setState(() {
          _plantData = jsonResponse[
              'data']; // Hoặc jsonResponse nếu backend trả trực tiếp
          _isLoading = false;
        });
      } else {
        print("Lỗi tải dữ liệu: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Đang tải...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_plantData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Lỗi")),
        body: Center(child: Text("Không tìm thấy thông tin cây")),
      );
    }

    // Lấy dữ liệu ra biến cho gọn
    var plant = _plantData!;
    List histories = plant['histories'] ?? [];

    final fullImageUrl = Config.getPlantImageUrl(plant);

    return Scaffold(
      appBar: AppBar(
        title: Text(plant['name'] ?? "Chi tiết cây"),
        backgroundColor: Color(0xFF25BB57),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh cây lớn
            fullImageUrl.isNotEmpty
                ? _buildPlantImage(fullImageUrl)
                : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: Center(
                        child: Icon(Icons.image_not_supported, size: 50))),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Thông tin cơ bản
                  Text("Vị trí: ${plant['location'] ?? 'Chưa cập nhật'}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  SizedBox(height: 8),
                  Text("Ghi chú: ${plant['note'] ?? 'Không có'}",
                      style: TextStyle(fontSize: 14)),

                  Divider(height: 40, thickness: 1.5),

                  // 3. Danh sách lịch sử
                  Text("Lịch sử chăm sóc",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),

                  histories.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Chưa có lịch sử chăm sóc nào.",
                              style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap:
                              true, // Quan trọng để nằm trong SingleChildScrollView
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: histories.length,
                          itemBuilder: (context, index) {
                            var item = histories[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child:
                                    Icon(Icons.water_drop, color: Colors.blue),
                              ),
                              title: Text(item['action'] ?? 'Hoạt động'),
                              subtitle: Text(item['created_at'] != null
                                  ? item['created_at']
                                      .toString()
                                      .substring(0, 10)
                                  : ""),
                              // trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Nút thêm lịch sử mới
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Code chức năng thêm lịch sử sau
        },
        backgroundColor: Color(0xFF25BB57),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPlantImage(String imageUrl, {bool allowProxyFallback = true}) {
    debugPrint('[PlantDetail] Load image: $imageUrl');
    return Image.network(
      imageUrl,
      headers: Config.getImageHeaders(imageUrl),
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 250,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (ctx, error, __) {
        debugPrint('[PlantDetail] Failed image: $imageUrl | $error');
        final proxyUrl =
            allowProxyFallback && Config.canUseProxyFallback(imageUrl)
                ? Config.getImageProxyUrl(imageUrl)
                : "";
        if (proxyUrl.isNotEmpty && proxyUrl != imageUrl) {
          return _buildPlantImage(proxyUrl, allowProxyFallback: false);
        }
        return Container(
          height: 250,
          color: Colors.grey[300],
          child: const Center(child: Icon(Icons.broken_image, size: 50)),
        );
      },
    );
  }
}
