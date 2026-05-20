import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cham_soc_cay_trong/config.dart';
import 'package:translator/translator.dart';

class PlantIdentifyResultScreen extends StatefulWidget {
  final File imageFile;

  const PlantIdentifyResultScreen({Key? key, required this.imageFile}) : super(key: key);

  @override
  _PlantIdentifyResultScreenState createState() => _PlantIdentifyResultScreenState();
}

class _PlantIdentifyResultScreenState extends State<PlantIdentifyResultScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _plantData;
  String _errorMessage = "";
  final translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _processPlantIdentification();
  }

  // === QUY TRÌNH: PLANTNET -> DATABASE -> HIỂN THỊ ===
  Future<void> _processPlantIdentification() async {
    setState(() { _isLoading = true; _errorMessage = ""; });

    try {
      // 1. GỌI PLANTNET ĐỂ NHẬN DIỆN
      String myKey = "2b109VgvlqVVbZXF5QrJDTbj"; 
      if (myKey.isEmpty) myKey = Config.plantNetApiKey;

      var uri = Uri.parse('https://my-api.plantnet.org/v2/identify/all?api-key=$myKey&include-related-images=false&no-reject=true&lang=en');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('images', widget.imageFile.path));
      request.fields['organs'] = 'auto'; 

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        var results = jsonResponse['results'];
        
        if (results != null && results.isNotEmpty) {
          var bestMatch = results[0];
          
//THUẬT TOÁN LỌC ẢNH RÁC
          double confidenceScore = bestMatch['score'];
          if (confidenceScore < 0.2) { // Nếu độ chính xác dưới 20%
            if (mounted) {
              setState(() {
                _errorMessage = "Không tìm thấy thực vật trong ảnh!\nVui lòng chụp rõ nét lá, hoa hoặc thân cây.";
                _isLoading = false;
              });
            }
            return; // Dừng luôn, không chạy tiếp đoạn dưới
          }

          var species = bestMatch['species'];
          var scientificName = species['scientificNameWithoutAuthor']; // Tên KH từ AI
          var score = (confidenceScore * 100).toStringAsFixed(1); // Độ chính xác
          
          List<dynamic> commonNames = species['commonNames'] ?? [];
          String englishName = commonNames.isNotEmpty ? commonNames[0] : scientificName;

          // 2. TÌM TÊN KHOA HỌC TRONG DATABASE
          var dbData = await _fetchInfoFromDatabase(scientificName, englishName);

          Map<String, dynamic> finalData;

          if (dbData != null) {
            // --- NẾU CÓ TRONG CSDL: LẤY FULL DATA ---
            finalData = {
              "name_vi": dbData['name'] ?? "Cây lạ",
              "scientific_name": scientificName,
              "score": score,
              "family": species['family']['scientificNameWithoutAuthor'] ?? "Chưa rõ",
              "genus": species['genus']['scientificNameWithoutAuthor'] ?? "Chưa rõ",
              "description": dbData['description'],
              "light": dbData['light'],
              "water": dbData['water'],
              "temp": dbData['temp'],
              "difficulty": dbData['difficulty'],
              "soil": dbData['soil'],
              "fertilizer": dbData['fertilizer'],
              "care_tips": dbData['care_tips'],
              "pruning": dbData['pruning'],
              "propagation": dbData['propagation'],
              "planting_time": dbData['planting_time'],
              "hardiness": dbData['hardiness'],
              "pests": dbData['pests'],
            };
          } else {
            // --- NẾU KHÔNG CÓ TRONG CSDL: DÙNG DỊCH AI ---
            String vietnameseName = englishName;
            try {
               var trans = await translator.translate(englishName, to: 'vi');
               vietnameseName = trans.text;
            } catch (e) {}

            finalData = {
              "name_vi": vietnameseName,
              "scientific_name": scientificName,
              "score": score,
              "family": species['family']['scientificNameWithoutAuthor'],
              "genus": species['genus']['scientificNameWithoutAuthor'],
              "description": "Chưa có dữ liệu chuyên sâu trong hệ thống.",
              "light": "Tự nhiên",
              "water": "Tưới khi đất khô",
              "temp": "Nhiệt độ phòng",
              "care_tips": "Tìm hiểu thêm hướng dẫn chăm sóc cơ bản trên internet."
            };
          }

          if (mounted) {
            setState(() {
              _plantData = finalData;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() { _errorMessage = "Không nhận diện được cây."; _isLoading = false; });
        }
      } else {
        if (mounted) setState(() { _errorMessage = "Lỗi PlantNet (${response.statusCode})"; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = "Lỗi kết nối: $e"; _isLoading = false; });
    }
  }

  // --- HÀM TÌM KIẾM TRONG DATABASE ---
  Future<Map<String, dynamic>?> _fetchInfoFromDatabase(String sciName, String engName) async {
    try {
      final url = Uri.parse('${Config.apiUrl}/library');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        List data = json['data'];

        for (var item in data) {
          String dbSciName = (item['scientific_name'] ?? "").toString().toLowerCase();
          String querySci = sciName.toLowerCase();
          if (dbSciName.isNotEmpty && (querySci.contains(dbSciName) || dbSciName.contains(querySci))) {
            return item;
          }
        }
      }
    } catch (e) {
      print("Lỗi gọi Server DB: $e");
    }
    return null; 
  }

  // === HÀM LƯU VÀO VƯỜN ===
  Future<void> _saveToGarden() async {
    if (_plantData == null) return;
    setState(() => _isSaving = true);
    try {
      var uri = Uri.parse('${Config.apiUrl}/plants');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';
      
      request.fields['name'] = _plantData!['name_vi']; // Lưu tên tiếng Việt
      request.fields['location'] = "Sân vườn";
      request.files.add(await http.MultipartFile.fromPath('image', widget.imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Đã lưu vào Vườn!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); 
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Lỗi lưu: ${response.statusCode}"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Lỗi kết nối: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // === GIAO DIỆN HIỂN THỊ CHUẨN ĐẸP ===
  @override
  Widget build(BuildContext context) {
    // Các hàm phụ trợ để xử lý chuỗi an toàn
    String val(String key) => (_plantData?[key] ?? "").toString();
    bool hasData(String key) => val(key).isNotEmpty && val(key) != "null";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      
      // 1. THANH ĐIỀU HƯỚNG DƯỚI CÙNG (CHỤP LẠI & LƯU)
      bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty ? null : Padding(
        padding: const EdgeInsets.all(16.0), 
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context), 
              icon: const Icon(Icons.refresh, color: Colors.green), 
              label: const Text("Chụp lại", style: TextStyle(color: Colors.green)), 
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
            )
          ), 
          const SizedBox(width: 12), 
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveToGarden, 
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.add, color: Colors.white), 
              label: Text(_isSaving ? "Đang lưu..." : "Lưu lại", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
            )
          ),
        ])
      ),
      
      // 2. NỘI DUNG CHÍNH
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _errorMessage.isNotEmpty
              // 👇 GIAO DIỆN HIỂN THỊ LỖI KHI CHỤP SAI 👇
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text("Chụp lại ảnh khác", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // A. ẢNH HEADER
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      backgroundColor: Colors.green,
                      iconTheme: const IconThemeData(color: Colors.white),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(val('name_vi'), style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 5, color: Colors.black45)])),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(widget.imageFile, fit: BoxFit.cover),
                            // Thêm lớp gradient đen mờ dưới đáy để nổi bật chữ
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black87, Colors.transparent]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // B. DANH SÁCH CÁC THẺ THÔNG TIN
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: Column(
                          children: [
                            // 1. Thuộc tính & Độ chính xác
                            _buildCard("Thuộc tính", Icons.eco, 
                              "🌿 Họ: ${val('family')}\n🌱 Chi: ${val('genus')}\n🎯 Độ chính xác: ${val('score')}%\n⛰️ Độ khó: ${hasData('difficulty') ? val('difficulty') : 'Đang cập nhật'}"
                            ),
                            const SizedBox(height: 16),

                            // 2. Giới thiệu
                            _buildCard("Giới thiệu", Icons.info, 
                              "Tên Khoa Học: ${val('scientific_name')}\n${val('description')}"
                            ),
                            const SizedBox(height: 16),

                            // 3. Điều kiện sống
                            if (hasData('light') || hasData('water')) 
                              _buildCard("Điều kiện sống", Icons.wb_sunny, 
                                "☀️ Ánh sáng: ${val('light')}\n💧 Nước: ${val('water')}\n🌡️ Nhiệt độ: ${val('temp')}"
                              ),
                            
                            // 4. Đất & Phân bón
                            if (hasData('soil') || hasData('fertilizer'))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildCard("Đất & Phân bón", Icons.landscape, 
                                  "🌱 Đất: ${val('soil')}\n🧪 Phân bón: ${val('fertilizer')}"
                                ),
                              ),

                            // 5. Chăm sóc & Cắt tỉa
                            if (hasData('care_tips') || hasData('pruning'))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildCard("Chăm sóc & Cắt tỉa", Icons.content_cut, 
                                  "✂️ Cắt tỉa: ${val('pruning')}\n💚 Chăm sóc: ${val('care_tips')}"
                                ),
                              ),

                            // 6. Nhân giống & Mùa vụ
                            if (hasData('propagation') || hasData('planting_time'))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildCard("Nhân giống & Mùa vụ", Icons.spa, 
                                  "🌱 Nhân giống: ${val('propagation')}\n🗓️ Mùa trồng: ${val('planting_time')}\n💪 Chịu đựng: ${val('hardiness')}"
                                ),
                              ),

                            // 7. Sâu bệnh
                            if (hasData('pests'))
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: _buildCard("Phòng ngừa sâu bệnh", Icons.bug_report, val('pests'), color: Colors.orange.shade50),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // === HÀM VẼ THẺ (CARD) CHUẨN ĐẸP ===
  Widget _buildCard(String title, IconData icon, String content, {Color color = Colors.white}) {
    // Lọc bỏ các dòng null hoặc rỗng để giao diện không bị thừa
    final cleanContent = content.split('\n').where((line) => !line.contains('null') && !line.endsWith(': ')).join('\n');
    if (cleanContent.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.green), 
            const SizedBox(width: 8), 
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const Divider(height: 24),
          Text(cleanContent, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }
}