import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';
import 'library_detail_screen.dart'; 

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

  Future<void> _fetchMyGarden() async {
    try {
      final url = Uri.parse('${Config.apiUrl}/plants');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) setState(() { _myPlants = jsonResponse['data']; _isLoading = false; });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlant(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa cây này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        final url = Uri.parse('${Config.apiUrl}/plants/$id');
        await http.delete(url);
        _fetchMyGarden();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã xóa cây!"), backgroundColor: Colors.green));
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Vườn Của Tôi", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.green), onPressed: _fetchMyGarden)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _myPlants.isEmpty
              ? const Center(child: Text("Vườn trống"))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
                  ),
                  itemCount: _myPlants.length,
                  itemBuilder: (context, index) {
                    final plant = _myPlants[index];
                    String rawImg = plant['image'] ?? plant['image_url'] ?? "";
                    ImageProvider imgProvider;
                    
                    if (rawImg.startsWith('http')) {
                      imgProvider = NetworkImage(Config.getImageUrl(rawImg));
                    } else if (rawImg.isNotEmpty) {
                      String baseUrl = Config.apiUrl.replaceAll('/api', '');
                      if (!rawImg.startsWith('/')) rawImg = '/$rawImg';
                      imgProvider = NetworkImage('$baseUrl$rawImg');
                    } else {
                      imgProvider = const AssetImage('assets/images/placeholder.png');
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LibraryDetailScreen(
                              imagePath: rawImg.startsWith('http') ? Config.getImageUrl(rawImg) : '${Config.apiUrl.replaceAll('/api', '')}$rawImg',
                              
                              // 👇👇👇 ĐÂY LÀ PHẦN QUAN TRỌNG ĐỂ TRUYỀN DỮ LIỆU SANG 👇👇👇
                              plantData: {
                                "name_vi": plant['name'],
                                "scientific_name": plant['scientific_name'], 
                                "description": plant['description'],
                                "light": plant['light'],
                                "water": plant['water'],
                                "temp": plant['temp'],
                                "care_tips": plant['care_tips'],
                                "pests": plant['pests'],

                                // CÁC TRƯỜNG MỚI BẮT BUỘC PHẢI CÓ Ở ĐÂY:
                                "soil": plant['soil'],                   
                                "fertilizer": plant['fertilizer'],       
                                "planting_time": plant['planting_time'], 
                                "pruning": plant['pruning'],             
                                "propagation": plant['propagation'],     
                                "hardiness": plant['hardiness'],         
                                "difficulty": plant['difficulty'],       
                              },
                              // 👆👆👆-------------------------------------------------👆👆👆
                              
                              hideAddButton: false,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image(image: imgProvider, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image))),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(plant['name'] ?? "Tên cây", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    Align(alignment: Alignment.bottomRight, child: GestureDetector(onTap: () => _deletePlant(plant['id']), child: const Icon(Icons.delete, color: Colors.red, size: 20))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}