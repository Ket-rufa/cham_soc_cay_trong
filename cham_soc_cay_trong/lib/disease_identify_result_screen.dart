import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/models/plant_disease.dart';
import 'package:cham_soc_cay_trong/pest_disease_detail_screen.dart';

class DiseaseIdentifyResultScreen extends StatefulWidget {
  final XFile imageFile;

  const DiseaseIdentifyResultScreen({Key? key, required this.imageFile})
      : super(key: key);

  @override
  _DiseaseIdentifyResultScreenState createState() =>
      _DiseaseIdentifyResultScreenState();
}

class _DiseaseIdentifyResultScreenState
    extends State<DiseaseIdentifyResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = "";
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _colorAnalysis;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _identifyDisease();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _identifyDisease() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      var uri = Uri.parse('${Config.apiUrl}/disease-identify');
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll(Config.apiHeaders);
      
      final bytes = await widget.imageFile.readAsBytes();
      // Xác định đúng mime type để Laravel validate image thành công
      final ext = widget.imageFile.name.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'png' : ext == 'webp' ? 'webp' : 'jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: widget.imageFile.name,
          contentType: MediaType('image', mimeType),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _results =
                List<Map<String, dynamic>>.from(jsonResponse['results'] ?? []);
            _colorAnalysis = jsonResponse['color_analysis'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = jsonResponse['message'] ??
                "Lỗi phân tích ảnh (${response.statusCode})";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối server: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _buildResultContent(),
    );
  }

  // === LOADING STATE ===
  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFFF4F6F4)],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Nút quay lại
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Spacer(),
            // Animation ảnh quét
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent
                            .withOpacity(0.2 + _pulseController.value * 0.3),
                        blurRadius: 30 + _pulseController.value * 20,
                        spreadRadius: _pulseController.value * 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: kIsWeb 
                        ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                        : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "Đang phân tích bệnh trên lá...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "AI đang quét và phân tích màu sắc, đốm lá,\nvết bệnh để đưa ra chẩn đoán",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Colors.greenAccent,
                minHeight: 4,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  // === ERROR STATE ===
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.search_off_rounded,
                  color: Color(0xFFE65100), size: 60),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text("Chụp lại"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _identifyDisease,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text("Thử lại",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === RESULT CONTENT ===
  Widget _buildResultContent() {
    final topResult = _results.isNotEmpty ? _results[0] : null;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh chụp
                  kIsWeb 
                      ? Image.network(widget.imageFile.path, fit: BoxFit.cover)
                      : Image.file(File(widget.imageFile.path), fit: BoxFit.cover),
                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black26,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  // Kết quả nổi trên ảnh
                  if (topResult != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge kết quả
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.biotech_rounded,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "Phát hiện bệnh • ${topResult['confidence']}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tên bệnh
                          Text(
                            topResult['name'] ?? 'Không rõ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            topResult['english_name'] ?? '',
                            style: TextStyle(
                              color: Colors.green.shade100,
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CARD CHẨN ĐOÁN AI
            _buildDiagnosisCard(),
            const SizedBox(height: 16),

            // 2. CHI TIẾT BỆNH TOP 1
            if (topResult != null) ...[
              _buildDiseaseDetailCard(topResult),
              const SizedBox(height: 16),
            ],

            // 3. PHÂN TÍCH MÀU SẮC (DEBUG / VISUAL)
            if (_colorAnalysis != null) _buildColorAnalysisCard(),
            const SizedBox(height: 16),

            // 4. CÁC GỢI Ý KHÁC
            if (_results.length > 1) _buildOtherSuggestionsCard(),
          ],
        ),
      ),
    );
  }

  // === CARD: CHẨN ĐOÁN AI ===
  Widget _buildDiagnosisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded,
                    color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Chẩn đoán bệnh AI",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "AI đã phân tích ảnh dựa trên đặc điểm màu sắc và vết bệnh trên lá. "
            "Dưới đây là các bệnh có khả năng cao nhất:",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          // Top 3 progress bars
          ..._results.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            final confidence = (result['confidence'] as num).toDouble();
            final color = index == 0
                ? Colors.redAccent
                : index == 1
                    ? Colors.orange
                    : Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildCandidateRow(
                result['name'] ?? 'Không rõ',
                confidence,
                color,
              ),
            );
          }),
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
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  // === CARD: CHI TIẾT BỆNH ===
  Widget _buildDiseaseDetailCard(Map<String, dynamic> disease) {
    final symptoms = disease['symptoms'] ?? '';
    final causes = disease['causes'] ?? '';
    final prevention = disease['prevention'] ?? '';
    final treatment = disease['treatment'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFE65100), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Chi tiết bệnh hàng đầu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A1E),
                      ),
                    ),
                    Text(
                      disease['type'] ?? 'Bệnh hại',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Triệu chứng
          if (symptoms.isNotEmpty) ...[
            _buildInfoRow(
              Icons.visibility_rounded,
              "Triệu chứng",
              symptoms,
              Colors.red.shade700,
              Colors.red.shade50,
            ),
            const SizedBox(height: 14),
          ],

          // Nguyên nhân
          if (causes.isNotEmpty) ...[
            _buildInfoRow(
              Icons.science_rounded,
              "Nguyên nhân",
              causes,
              Colors.orange.shade800,
              Colors.orange.shade50,
            ),
            const SizedBox(height: 14),
          ],

          // Phòng ngừa
          if (prevention.isNotEmpty) ...[
            _buildInfoRow(
              Icons.shield_rounded,
              "Phòng ngừa",
              prevention,
              Colors.blue.shade700,
              Colors.blue.shade50,
            ),
            const SizedBox(height: 14),
          ],

          // Điều trị
          if (treatment.isNotEmpty) ...[
            _buildInfoRow(
              Icons.healing_rounded,
              "Điều trị",
              treatment,
              Colors.green.shade700,
              Colors.green.shade50,
            ),
            const SizedBox(height: 14),
          ],

          // Nút xem chi tiết đầy đủ
          if (disease['guide_id'] != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openDiseaseDetail(disease),
                icon: Icon(Icons.menu_book_rounded,
                    color: Colors.green.shade700, size: 18),
                label: Text(
                  "Xem hướng dẫn chi tiết đầy đủ",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String content,
    Color titleColor,
    Color bgColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: titleColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  // === CARD: PHÂN TÍCH MÀU SẮC ===
  Widget _buildColorAnalysisCard() {
    final colors = {
      'green': MapEntry('Xanh lá', const Color(0xFF4CAF50)),
      'yellow': MapEntry('Vàng', const Color(0xFFFFC107)),
      'brown': MapEntry('Nâu', const Color(0xFF795548)),
      'black': MapEntry('Đen', const Color(0xFF424242)),
      'white': MapEntry('Trắng/Xám', const Color(0xFF9E9E9E)),
    };

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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_rounded,
                    color: Colors.deepPurple, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Phân tích quang phổ màu",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Color bars
          ...colors.entries.map((entry) {
            final key = entry.key;
            final label = entry.value.key;
            final color = entry.value.value;
            final value = (_colorAnalysis?[key] ?? 0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: value / 100,
                        backgroundColor: Colors.grey.shade100,
                        color: color,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    child: Text(
                      "${value.toStringAsFixed(1)}%",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // === CARD: GỢI Ý KHÁC ===
  Widget _buildOtherSuggestionsCard() {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                "Bệnh khác có thể gặp",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._results.skip(1).map((result) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openDiseaseDetail(result),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bug_report_outlined,
                            color: Color(0xFFE65100),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result['name'] ?? 'Không rõ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                result['english_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${(result['confidence'] as num).toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Lưu ý
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Kết quả mang tính tham khảo. Nên kết hợp quan sát thực tế "
                    "và tham khảo chuyên gia nông nghiệp để chẩn đoán chính xác.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === NAVIGATE TO DISEASE DETAIL ===
  void _openDiseaseDetail(Map<String, dynamic> diseaseData) {
    final plantDisease = PlantDisease.fromJson({
      'name': diseaseData['name'],
      'english_name': diseaseData['english_name'],
      'symptoms': diseaseData['symptoms'] ?? '',
      'causes': diseaseData['causes'] ?? '',
      'prevention': diseaseData['prevention'] ?? '',
      'treatment': diseaseData['treatment'] ?? '',
      'image_url': diseaseData['image_url'] ?? '',
      'type': diseaseData['type'] ?? 'Bệnh hại',
      'affected_plants': diseaseData['affected_plants'] ?? '',
      'top_affected_flowers': diseaseData['top_affected_flowers'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PestDiseaseDetailScreen(disease: plantDisease),
      ),
    );
  }
}
