import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';

class MyGardenTab extends StatefulWidget {
  const MyGardenTab({Key? key}) : super(key: key);

  @override
  State<MyGardenTab> createState() => _MyGardenTabState();
}

class _MyGardenTabState extends State<MyGardenTab> {
  List _myPlants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyGarden();
  }

  // Hàm gọi API lấy cây của tôi
  Future<void> _fetchMyGarden() async {
    try {
      // Gọi vào hàm index() bạn vừa viết trong Laravel
      final url = Uri.parse('${Config.apiUrl}/plants');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            _myPlants = jsonResponse['data']; // Lấy danh sách cây
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi lấy dữ liệu vườn: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.tr('garden.title'),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.green),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchMyGarden();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _myPlants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_florist_outlined,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('garden.emptyMessage'),
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myPlants.length,
                  itemBuilder: (context, index) {
                    final plant = _myPlants[index];
                    final plantMap = plant is Map
                        ? Map<String, dynamic>.from(plant)
                        : <String, dynamic>{};
                    final imageUrl = Config.getPlantImageUrl(plantMap);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          // Ảnh cây
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16)),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: imageUrl.isEmpty
                                  ? Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    )
                                  : Image.network(
                                      imageUrl,
                                      headers: Config.getImageHeaders(imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, error, ___) {
                                        debugPrint(
                                          '[MyGardenTab] Failed image $imageUrl | $error',
                                        );
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image),
                                        );
                                      },
                                    ),
                            ),
                          ),

                          // Thông tin
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plant['name'] ??
                                        context.tr('common.unknownPlant'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(plant['location'] ?? "",
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Đã thêm: ${plant['created_at'] != null ? plant['created_at'].toString().substring(0, 10) : 'Gần đây'}",
                                    style: TextStyle(
                                        color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Nút xóa (Demo)
                          IconButton(
                            icon:
                                const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: () {},
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
