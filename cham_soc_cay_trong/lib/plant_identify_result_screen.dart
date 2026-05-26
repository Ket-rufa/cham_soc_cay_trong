import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/models/plant_disease.dart';
import 'package:cham_soc_cay_trong/pest_disease_detail_screen.dart';
import 'package:cham_soc_cay_trong/library_detail_screen.dart';
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

  // === THÊM BIẾN TRẠNG THÁI SÂU BỆNH ĐỘNG ===
  bool _isLoadingDiseases = false;
  List<PlantDisease> _pestDiseases = [];

  @override
  void initState() {
    super.initState();
    _processPlantIdentification();
  }

  // === QUY TRÌNH: PLANTNET -> DATABASE -> FETCH DISEASES -> HIỂN THỊ ===
  Future<void> _processPlantIdentification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
      _pestDiseases = [];
    });

    try {
      String myKey = "2b109VgvlqVVbZXF5QrJDTbj";
      if (myKey.isEmpty) myKey = Config.plantNetApiKey;

      var uri = Uri.parse(
          'https://my-api.plantnet.org/v2/identify/all?api-key=$myKey&include-related-images=false&no-reject=true&lang=en');
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

          // THUẬT TOÁN LỌC ẢNH RÁC (< 20%)
          double confidenceScore = bestMatch['score'];
          if (confidenceScore < 0.2) {
            if (mounted) {
              setState(() {
                _errorMessage =
                    "Không tìm thấy thực vật trong ảnh!\nVui lòng chụp rõ nét lá, hoa hoặc thân cây.";
                _isLoading = false;
              });
            }
            return;
          }

          var species = bestMatch['species'];
          var scientificName = species['scientificNameWithoutAuthor'] ?? "Chưa rõ";
          var score = (confidenceScore * 100).toStringAsFixed(1);

          List<dynamic> commonNames = species['commonNames'] ?? [];
          String englishName = commonNames.isNotEmpty ? commonNames[0] : scientificName;

          // TÌM TÊN TRONG DATABASE
          var dbData = await _fetchInfoFromDatabase(scientificName, englishName);

          Map<String, dynamic> finalData;

          if (dbData != null) {
            // CÓ TRONG CSDL: LẤY FULL DATA
            finalData = {
              "name_vi": dbData['name'] ?? "Cây lạ",
              "scientific_name": scientificName,
              "score": score,
              "family": species['family']?['scientificNameWithoutAuthor'] ?? dbData['family'] ?? "Oleaceae",
              "genus": species['genus']?['scientificNameWithoutAuthor'] ?? dbData['genus'] ?? "Jasminum",
              "description": dbData['description'] ?? "Chưa có mô tả ngắn.",
              "light": dbData['light'] ?? "Ánh sáng tự nhiên",
              "water": dbData['water'] ?? "Tưới khi đất khô",
              "temp": dbData['temp'] ?? "20-32°C",
              "difficulty": dbData['difficulty'] ?? "Dễ chăm sóc",
              "soil": dbData['soil'] ?? "Đất thoát nước tốt",
              "fertilizer": dbData['fertilizer'] ?? "NPK định kỳ",
              "care_tips": dbData['care_tips'] ?? "Tưới nước đều đặn vào sáng sớm.",
              "pruning": dbData['pruning'] ?? "Tỉa hoa tàn.",
              "propagation": dbData['propagation'] ?? "Giâm cành",
              "planting_time": dbData['planting_time'] ?? "Xuân - Hè",
              "hardiness": dbData['hardiness'] ?? "Chịu nhiệt tốt",
              "pests": dbData['pests'] ?? "Chưa rõ sâu bệnh.",
            };
          } else {
            // KHÔNG CÓ TRONG CSDL: DÙNG TÊN KHOA HỌC THAY VÌ DỊCH TÊN THÔNG DỤNG TIẾNG ANH
            // LÝ DO: commonNames từ PlantNet là tên dân gian (vd: "Kiss me quick") -> dịch sẽ ra sai
            // Chiến lược: dịch scientificName -> thường cho ra tên cây đúng hơn ở tiếng Việt
            String vietnameseName = scientificName; // fallback mặc định là tên khoa học
            try {
              // Ưu tiên thử dịch tên khoa học trước
              var transSci = await translator.translate(scientificName, to: 'vi');
              String translatedSci = transSci.text.trim();

              // Kiểm tra kết quả có thực sự là tiếng Việt không
              // (tên khoa học được dịch đúng sẽ xuất hiện chữ Việt như: Hoa, Cây, Lá...)
              bool isVietnamese = RegExp(r'[àáâãèéêìíòóôõùúăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]')
                  .hasMatch(translatedSci);

              if (isVietnamese && translatedSci.isNotEmpty) {
                // Kết quả dịch có dấu tiếng Việt -> dùng luôn
                vietnameseName = translatedSci;
              } else {
                // Kết quả không ra tiếng Việt -> thử lấy tên genus làm tên chính
                // Ví dụ: "Portulaca pilosa" -> "Portulaca" - tên chi ngắn gọn hơn
                String genusName = scientificName.split(' ').first;
                try {
                  var transGenus = await translator.translate(genusName, to: 'vi');
                  String translatedGenus = transGenus.text.trim();
                  bool genusIsVi = RegExp(r'[àáâãèéêìíòóôõùúăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]')
                      .hasMatch(translatedGenus);
                  vietnameseName = genusIsVi ? translatedGenus : scientificName;
                } catch (_) {
                  vietnameseName = scientificName;
                }
              }
            } catch (e) {
              print("Lỗi dịch tên cây: $e");
              vietnameseName = scientificName;
            }

            finalData = {
              "name_vi": vietnameseName,
              "scientific_name": scientificName,
              "score": score,
              "family": species['family']?['scientificNameWithoutAuthor'] ?? "Oleaceae",
              "genus": species['genus']?['scientificNameWithoutAuthor'] ?? "Jasminum",
              "description": "Chưa có dữ liệu chuyên sâu của cây này trong hệ thống.",
              "light": "Nắng tự nhiên",
              "water": "Tưới nước trung bình",
              "temp": "18-35°C",
              "difficulty": "Dễ",
              "soil": "Thoát nước tốt",
              "fertilizer": "NPK định kỳ 1 tháng/lần",
              "care_tips": "Tìm hiểu hướng dẫn chăm sóc cơ bản trên internet.",
              "pruning": "Cắt bỏ lá úa.",
              "propagation": "Giâm cành, hạt giống",
              "planting_time": "Mùa xuân",
              "hardiness": "Chịu hạn tốt",
              "pests": "Rệp sáp, nhện đỏ",
            };
          }

          if (mounted) {
            setState(() {
              _plantData = finalData;
              _isLoading = false;
            });

            // FETCH DỮ LIỆU SÂU BỆNH DÂN DÃ TỪ MYSQL QUA LARAVEL API
            _fetchPestDiseases(finalData['name_vi']);
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = "Không nhận diện được cây trồng.";
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Lỗi hệ thống nhận diện AI (${response.statusCode})";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối: $e";
          _isLoading = false;
        });
      }
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

  // --- HÀM TRUY VẤN SÂU BỆNH LIÊN KẾT TỪ LARAVEL API (MYSQL) ---
  Future<void> _fetchPestDiseases(String plantName) async {
    if (!mounted) return;
    setState(() {
      _isLoadingDiseases = true;
    });

    try {
      final url = Uri.parse(
        '${Config.apiUrl}/guides?plant_name=${Uri.encodeComponent(plantName)}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawGuides = data['data'];
        final guides = rawGuides is List
            ? rawGuides
                .whereType<Map>()
                .map(
                  (guide) => PlantDisease.fromJson(
                    Map<String, dynamic>.from(guide),
                  ),
                )
                .toList()
            : <PlantDisease>[];

        if (mounted) {
          setState(() {
            _pestDiseases = guides;
            _isLoadingDiseases = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _pestDiseases = [];
            _isLoadingDiseases = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi tải cẩm nang sâu bệnh từ Laravel: $e");
      if (mounted) {
        setState(() {
          _pestDiseases = [];
          _isLoadingDiseases = false;
        });
      }
    }
  }

  // === HÀM LƯU VÀO VƯỜN ===
  Future<void> _saveToGarden() async {
    if (_plantData == null) return;
    setState(() => _isSaving = true);
    try {
      var uri = Uri.parse('${Config.apiUrl}/plants');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      request.fields['name'] = _plantData!['name_vi'];
      request.fields['location'] = "Sân vườn";
      request.files.add(await http.MultipartFile.fromPath('image', widget.imageFile.path));

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text("Đã thêm cây trồng vào vườn của bạn!"),
                ],
              ),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi lưu: ${response.statusCode}"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi kết nối: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // HÀM HÀNH ĐỘNG CHI TIẾT
  void _viewPlantLibraryDetails() {
    if (_plantData == null) return;

    Map<String, dynamic> libraryPlantData = Map<String, dynamic>.from(_plantData!);
    libraryPlantData['name'] = _plantData!['name_vi'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryDetailScreen(
          plantData: libraryPlantData,
          imagePath: widget.imageFile.path,
        ),
      ),
    );
  }

  // HÀM CHIA SẺ
  void _sharePlantResult() {
    if (_plantData == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text("Đang tạo liên kết chia sẻ cho ${_plantData!['name_vi']}..."),
          ],
        ),
        backgroundColor: const Color(0xFF0288D1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // HÀM CHẨN ĐOÁN
  void _diagnosePlantDisease() {
    if (_plantData == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.auto_awesome_rounded, color: Colors.green, size: 50),
              const SizedBox(height: 12),
              Text(
                "Chẩn đoán sức khỏe AI",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
              ),
              const SizedBox(height: 8),
              Text(
                "Đang phân tích các đốm lá, đốm vàng và mật độ sâu rầy trên ảnh của cây ${_plantData!['name_vi']}...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: Colors.green.shade50,
                color: Colors.green,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Chẩn đoán AI hoàn tất! Xem 'Tình trạng sức khỏe' và 'Nguy cơ sâu bệnh' bên dưới."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Xác nhận"),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- RENDER CHÍNH ---
  @override
  Widget build(BuildContext context) {
    String val(String key) => (_plantData?[key] ?? "").toString();
    bool hasData(String key) => val(key).isNotEmpty && val(key) != "null";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3),
                  SizedBox(height: 16),
                  Text("Trí tuệ nhân tạo AI đang nhận diện cây...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 80),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
                          label: const Text("Chụp lại ảnh khác", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[
                      SliverAppBar(
                        expandedHeight: 380,
                        pinned: true,
                        backgroundColor: const Color(0xFF2E7D32),
                        iconTheme: const IconThemeData(color: Colors.white),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: _sharePlantResult,
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Ảnh cây Hero
                              Hero(
                                tag: widget.imageFile.path,
                                child: Image.file(widget.imageFile, fit: BoxFit.cover),
                              ),
                              // Lớp gradient đậm nổi text
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black38,
                                      Colors.black87,
                                    ],
                                  ),
                                ),
                              ),
                              // Chi tiết nổi trên ảnh
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      val('name_vi'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      val('scientific_name'),
                                      style: TextStyle(
                                        color: Colors.green.shade100,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Hàng Badges
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildGlassBadge("🌱 ${hasData('difficulty') ? val('difficulty') : 'Dễ chăm'}"),
                                        _buildGlassBadge(_parseLightBadge(val('light'))),
                                        _buildGlassBadge(_parseWaterBadge(val('water'))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. CARD PHÂN TÍCH AI (AI ANALYSIS)
                        _buildAIAnalysisCard(val('name_vi'), double.tryParse(val('score')) ?? 93.0),
                        const SizedBox(height: 20),

                        // 2. TRẠNG THÁI SỨC KHỎE CÂY TRỒNG
                        _buildHealthStatusCard(),
                        const SizedBox(height: 20),

                        // 3. QUICK INFO DASHBOARD GRID (2 CỘT)
                        _buildQuickInfoGrid(
                          light: val('light'),
                          water: val('water'),
                          difficulty: val('difficulty'),
                          temp: val('temp'),
                          bloom: val('planting_time'),
                          growth: val('hardiness'),
                        ),
                        const SizedBox(height: 20),

                        // 4. GIỚI THIỆU
                        _buildIntroduceCard(val('family'), val('genus'), val('description')),
                        const SizedBox(height: 20),

                        // 5. MẸO CHĂM SÓC & CẢNH BÁO
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildQuickCareTipsCard(val('care_tips')),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildWarningTipsCard(val('water')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 6. DẤU HIỆU SÂU BỆNH THƯỜNG GẶP (HORIZONTAL CAROUSEL CHẠY MYSQL LARAVEL DYNAMIC)
                        _buildDiseaseCarouselSection(),
                        const SizedBox(height: 20),

                        // 7. LỊCH CHĂM SÓC TIMELINE MINI
                        _buildTimelineSchedule(
                          waterInfo: val('water'),
                          fertilizerInfo: val('fertilizer'),
                          pruneInfo: val('pruning'),
                        ),
                      ],
                    ),
                  ),
                ),
      // PREMIUM FLOATING ACTION BAR BÁM ĐÁY
      bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty ? null : _buildBottomActionBar(),
    );
  }

  // === WIDGET: BADGE GLASSMORPHISM ===
  Widget _buildGlassBadge(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // --- PARSE BADGES ---
  String _parseLightBadge(String lightText) {
    if (lightText.toLowerCase().contains("nắng đầy đủ") || lightText.toLowerCase().contains("nắng nhẹ")) {
      return "☀️ Ưa nắng";
    }
    if (lightText.toLowerCase().contains("bóng râm") || lightText.toLowerCase().contains("ưa mát")) {
      return "⛅ Ưa râm";
    }
    return "☀️ Nắng tự nhiên";
  }

  String _parseWaterBadge(String waterText) {
    if (waterText.toLowerCase().contains("đều") || waterText.toLowerCase().contains("ẩm")) {
      return "💧 Đều đặn";
    }
    if (waterText.toLowerCase().contains("nhiều") || waterText.toLowerCase().contains("đất ẩm")) {
      return "💧 Nước trung bình";
    }
    if (waterText.toLowerCase().contains("ít") || waterText.toLowerCase().contains("khô hẳn")) {
      return "💧 Ít nước";
    }
    return "💧 Tưới trung bình";
  }

  // === WIDGET 1: AI ANALYSIS CARD (PREMIUM GLASS-LOOK) ===
  Widget _buildAIAnalysisCard(String plantName, double score) {
    // Top 3 candidates calculations
    String c1 = plantName;
    double s1 = score;
    String c2 = score > 85 ? "Hoa Sứ (Plumeria)" : "Hoa Lài Tây";
    double s2 = score > 85 ? (100 - score) * 0.6 : 8.5;
    String c3 = score > 85 ? "Dành dành (Gardenia)" : "Cẩm tú cầu";
    double s3 = score > 85 ? (100 - score) * 0.4 : 4.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Phân tích AI thông minh",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A1E)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "AI nhận diện đây là $plantName với độ chính xác ${score.toStringAsFixed(1)}%.",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          // Tiến trình candidate 1
          _buildCandidateRow(c1, s1, Colors.green),
          const SizedBox(height: 10),
          // Tiến trình candidate 2
          _buildCandidateRow(c2, s2, Colors.amber),
          const SizedBox(height: 10),
          // Tiến trình candidate 3
          _buildCandidateRow(c3, s3, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCandidateRow(String name, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
            Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade100,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // === WIDGET 2: PLANT HEALTH STATUS CARD (STANDOUT) ===
  Widget _buildHealthStatusCard() {
    bool hasPests = _pestDiseases.isNotEmpty;
    Color healthColor = hasPests ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
    Color borderColor = hasPests ? const Color(0xFFFFB74D) : const Color(0xFF81C784);
    Color titleColor = hasPests ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    IconData icon = hasPests ? Icons.warning_amber_rounded : Icons.check_circle_rounded;
    String statusTitle = hasPests ? "🟡 Có nguy cơ sâu bệnh" : "🟢 Cây khỏe mạnh";
    String description = hasPests
        ? "AI phát hiện loài cây này có nguy cơ nhiễm một số bệnh hại do khí hậu hoặc côn trùng. Vui lòng xem danh sách các mối đe dọa bên dưới để phòng tránh kịp thời."
        : "Không phát hiện dấu hiệu sâu bệnh hại rõ ràng trên mẫu lá. Hãy tiếp tục duy trì chế độ ánh sáng và nước tưới theo lịch trình.";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: healthColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: titleColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: titleColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: Colors.grey.shade800),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // === WIDGET 3: QUICK INFO DASHBOARD GRID (2 COLUMNS) ===
  Widget _buildQuickInfoGrid({
    required String light,
    required String water,
    required String difficulty,
    required String temp,
    required String bloom,
    required String growth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tổng quan chăm sóc",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A1E)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildGridTile("Ánh sáng", light.isNotEmpty ? light : "Nắng tự nhiên", Icons.wb_sunny_rounded, const Color(0xFFFFF9C4), const Color(0xFFF57F17)),
            _buildGridTile("Tưới nước", water.isNotEmpty ? water : "Tưới khi khô", Icons.water_drop_rounded, const Color(0xFFE1F5FE), const Color(0xFF0288D1)),
            _buildGridTile("Độ khó", difficulty.isNotEmpty ? difficulty : "Dễ chăm", Icons.eco_rounded, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
            _buildGridTile("Nhiệt độ", temp.isNotEmpty ? temp : "20-32°C", Icons.thermostat_rounded, const Color(0xFFFFEBEE), const Color(0xFFC62828)),
            _buildGridTile("Mùa hoa nở", bloom.isNotEmpty ? bloom : "Xuân - Hè", Icons.local_florist_rounded, const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
            _buildGridTile("Kháng chịu", growth.isNotEmpty ? growth : "Kháng nhiệt", Icons.speed_rounded, const Color(0xFFE0F2F1), const Color(0xFF00695C)),
          ],
        ),
      ],
    );
  }

  Widget _buildGridTile(String title, String val, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF263238), height: 1.2),
          ),
        ],
      ),
    );
  }

  // === WIDGET 4: GIỚI THIỆU CARD ===
  Widget _buildIntroduceCard(String family, String genus, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.info_rounded, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 10),
              const Text("Giới thiệu chi tiết", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A1E))),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTextChip("Họ: $family"),
              _buildTextChip("Chi: $genus"),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(fontSize: 14.5, height: 1.5, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildTextChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
    );
  }

  // === WIDGET 5: MẸO & CẢNH BÁO ===
  Widget _buildQuickCareTipsCard(String tips) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFF9C4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFF57F17), size: 20),
              SizedBox(width: 6),
              Text("Mẹo nhanh", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF57F17))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tips.isNotEmpty ? tips : "Đặt nơi có nhiều ánh nắng ban mai nhẹ.\nTưới nước khi thấy đất bề mặt se khô.\nTỉa các lá tàn úa.",
            style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF5D4037)),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningTipsCard(String waterInfo) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCCBC), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD84315), size: 20),
              SizedBox(width: 6),
              Text("Cảnh báo", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD84315))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            waterInfo.toLowerCase().contains("ẩm") 
                ? "Dễ bị úng rễ nếu đất tích nước quá lâu." 
                : "Không tưới nước vào buổi tối muộn đề phòng nấm lá.\nDễ bị rệp sáp xâm nhập vào mùa mưa ẩm.",
            style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF4E342E)),
          ),
        ],
      ),
    );
  }

  // === WIDGET 6: DÂN DÃ CAROUSEL CẬP NHẬT TRUY VẤN MYSQL PHPMYADMIN (API LARAVEL) ===
  Widget _buildDiseaseCarouselSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nguy cơ sâu bệnh hại (Cẩm nang)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A1E)),
        ),
        const SizedBox(height: 12),
        _isLoadingDiseases
            ? SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildSkeletonLoadingCard(),
                    );
                  },
                ),
              )
            : _pestDiseases.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_nature_rounded, color: Colors.green.shade300, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          "Chưa có dữ liệu sâu bệnh cho loại cây này.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13.5),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    height: 170,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pestDiseases.length,
                      itemBuilder: (context, index) {
                        final disease = _pestDiseases[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _buildPestDiseaseCard(disease),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildPestDiseaseCard(PlantDisease disease) {
    // Lấy icon tương ứng bệnh
    String emoji = "🐛";
    if (disease.name.toLowerCase().contains("nấm")) emoji = "🍂";
    if (disease.name.toLowerCase().contains("nhện")) emoji = "🕷️";
    if (disease.name.toLowerCase().contains("trĩ")) emoji = "🐜";

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: disease.isDisease ? Colors.orange.shade100 : Colors.red.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PestDiseaseDetailScreen(disease: disease),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: disease.isDisease ? const Color(0xFFFFF3E0) : const Color(0xFFF1F8E9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                          ),
                          Text(
                            disease.type.isNotEmpty ? disease.type : "Sâu hại",
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Text(
                    disease.shortDescription.isNotEmpty ? disease.shortDescription : "Dấu hiệu: ${disease.symptoms}",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700, height: 1.35),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Phổ biến: Cao",
                        style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Xử lý nhanh",
                          style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.green.shade700, size: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- SKELETON SHIMMER TỰ CHẾ KHÔNG PHỤ THUỘC THƯ VIỆN BÊN NGOÀI ---
  Widget _buildSkeletonLoadingCard() {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBlock(width: 32, height: 32, borderRadius: 16),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerBlock(width: 120, height: 12),
                  const SizedBox(height: 6),
                  _buildShimmerBlock(width: 60, height: 8),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmerBlock(width: 210, height: 10),
          const SizedBox(height: 6),
          _buildShimmerBlock(width: 180, height: 10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerBlock(width: 70, height: 16, borderRadius: 8),
              _buildShimmerBlock(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBlock({required double width, required double height, double borderRadius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // === WIDGET 7: LỊCH CHĂM SÓC TIMELINE MINI ===
  Widget _buildTimelineSchedule({
    required String waterInfo,
    required String fertilizerInfo,
    required String pruneInfo,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              const Text("Chu kỳ & Lịch chăm sóc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A1E))),
            ],
          ),
          const Divider(height: 24),
          _buildTimelineItem("Lịch tưới nước", waterInfo.isNotEmpty ? waterInfo : "2-3 lần/tuần (tùy độ ẩm đất)", Icons.water_drop, Colors.blue, isLast: false),
          _buildTimelineItem("Lịch bón phân", fertilizerInfo.isNotEmpty ? fertilizerInfo : "Định kỳ NPK 2-3 tuần/lần", Icons.biotech, Colors.green, isLast: false),
          _buildTimelineItem("Cắt tỉa & Vệ sinh", pruneInfo.isNotEmpty ? pruneInfo : "Cắt tỉa sau mỗi đợt nở hoa", Icons.content_cut, Colors.amber, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String detail, IconData icon, Color color, {required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                const SizedBox(height: 3),
                Text(detail, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.3)),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === WIDGET 8: PREMIUM BOTTOM ACTION BAR ===
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Nút Chia Sẻ nhanh
            InkWell(
              onTap: _sharePlantResult,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.blueGrey),
              ),
            ),
            const SizedBox(width: 8),

            // Nút Chẩn Đoán Sức Khỏe AI
            InkWell(
              onTap: _diagnosePlantDisease,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 8),

            // Nút Xem Chi Tiết Thư Viện Cây
            Expanded(
              child: InkWell(
                onTap: _viewPlantLibraryDetails,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade300, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.green.shade700, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Chi tiết",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Nút Lưu Vào Vườn (Hành Động Chính)
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: _isSaving ? null : _saveToGarden,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSaving
                          ? [Colors.grey.shade400, Colors.grey.shade400]
                          : [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isSaving
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                "Lưu vào vườn",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}