import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';
import 'library_detail_screen.dart'; 

class PlantCategoryScreen extends StatelessWidget {
  const PlantCategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Thư viện Hoa"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const _PlantLibraryGrid(categoryType: "Hoa"),
    );
  }
}

class _PlantLibraryGrid extends StatefulWidget {
  final String categoryType;
  const _PlantLibraryGrid({required this.categoryType});

  @override
  State<_PlantLibraryGrid> createState() => _PlantLibraryGridState();
}

class _PlantLibraryGridState extends State<_PlantLibraryGrid> {
  List _allPlants = [];   // Danh sách gốc (đầy đủ)
  List _foundPlants = []; // Danh sách hiển thị (sau khi tìm kiếm)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
  }

  Future<void> _fetchLibrary() async {
    try {
      final url = Uri.parse('${Config.apiUrl}/library?type=${widget.categoryType}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            _allPlants = jsonResponse['data'];
            _foundPlants = _allPlants; // Ban đầu hiển thị hết
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM TÌM KIẾM ---
  void _runFilter(String enteredKeyword) {
    List results = [];
    if (enteredKeyword.isEmpty) {
      results = _allPlants;
    } else {
      results = _allPlants
          .where((plant) =>
              plant["name"].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }

    setState(() {
      _foundPlants = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. THANH TÌM KIẾM
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) => _runFilter(value),
            decoration: InputDecoration(
              labelText: 'Tìm kiếm loài hoa...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ),

        // 2. LƯỚI KẾT QUẢ
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _foundPlants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("Không tìm thấy cây nào", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _foundPlants.length,
                    itemBuilder: (context, index) {
                      final plant = _foundPlants[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LibraryDetailScreen(
                                imagePath: plant['image_url'] ?? "https://via.placeholder.com/300",
                                plantData: {
                                  "name_vi": plant['name'],
                                  "scientific_name": plant['scientific_name'] ?? "",
                                  "description": plant['description'] ?? "Chưa có mô tả.",
                                  "family": plant['family'],
                                  "genus": plant['genus'],
                                  "light": plant['light'],
                                  "water": plant['water'],
                                  "temp": plant['temp'],
                                  "soil": plant['soil'],
                                  "fertilizer": plant['fertilizer'],
                                  "planting_time": plant['planting_time'],
                                  "pruning": plant['pruning'],
                                  "propagation": plant['propagation'],
                                  "pests": plant['pests'],
                                  "care_tips": plant['care_tips'],
                                  "difficulty": plant['difficulty'],
                                  "hardiness": plant['hardiness'],
                                },
                              ),
                            ),
                          );
                        },
                        child: _buildPlantCard(plant),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(dynamic plant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                Config.getImageUrl(plant['image_url'] ?? ""),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.speed, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(plant['difficulty'] ?? 'TB', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          plant['light'] ?? 'Nắng',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1, overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}