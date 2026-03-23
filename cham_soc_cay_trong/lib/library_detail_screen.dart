import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cham_soc_cay_trong/config.dart';

class LibraryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  final String imagePath;
  final bool hideAddButton;

  const LibraryDetailScreen({
    Key? key,
    required this.plantData,
    required this.imagePath,
    this.hideAddButton = false,
  }) : super(key: key);

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  bool _isSaving = false;

  Future<void> _saveToGarden() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/plants'),
        body: {
          'name': widget.plantData['name_vi'] ?? 'Cây mới',
          'location': 'Sân vườn',
          'image_url': widget.imagePath,
        },
        headers: {'Accept': 'application/json'},
      );
      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Đã thêm vào Vườn!"), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi: ${response.statusCode}"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi mạng: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String val(String key) => (widget.plantData[key] ?? "").toString();
    bool hasData(String key) => val(key).isNotEmpty && val(key) != "null";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      floatingActionButton: widget.hideAddButton
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveToGarden,
              backgroundColor: Colors.green,
              icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_circle_outline),
              label: Text(_isSaving ? "Đang lưu..." : "Thêm vào Vườn"),
            ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.green,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(val('name_vi'), style: const TextStyle(color: Colors.white, shadows: [Shadow(blurRadius: 5, color: Colors.black45)])),
              background: Image.network(
                Config.getImageUrl(widget.imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(color: Colors.grey, child: const Icon(Icons.broken_image, size: 50, color: Colors.white)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  // 1. GIỚI THIỆU & TÊN KHOA HỌC
                  _buildCard("Giới thiệu", Icons.info, 
                    "${hasData('scientific_name') ? 'Tên Khoa Học: ${val('scientific_name')}\n\n' : ''}${val('description')}"
                  ),
                  const SizedBox(height: 16),

                  // 2. ĐIỀU KIỆN SỐNG (Gộp Ánh sáng, Nước, Nhiệt độ)
                  if (hasData('light')) 
                    _buildCard("Điều kiện sống", Icons.wb_sunny, 
                      "☀️ Ánh sáng: ${val('light')}\n💧 Nước: ${val('water')}\n🌡️ Nhiệt độ: ${val('temp')}\n⛰️ Độ khó: ${val('difficulty')}"
                    ),
                  
                  // 3. ĐẤT TRỒNG & PHÂN BÓN
                  if (hasData('soil') || hasData('fertilizer'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildCard("Đất & Phân bón", Icons.landscape, 
                        "🌱 Đất: ${val('soil')}\n🧪 Phân bón: ${val('fertilizer')}"
                      ),
                    ),

                  // 4. CÁCH CHĂM SÓC & CẮT TỈA
                  if (hasData('care_tips') || hasData('pruning'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildCard("Chăm sóc & Cắt tỉa", Icons.content_cut, 
                        "✂️ Cắt tỉa: ${val('pruning')}\n💚 Chăm sóc: ${val('care_tips')}"
                      ),
                    ),

                  // 5. NHÂN GIỐNG & MÙA VỤ
                  if (hasData('propagation') || hasData('planting_time'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildCard("Nhân giống & Mùa vụ", Icons.spa, 
                        "🌱 Nhân giống: ${val('propagation')}\n🗓️ Mùa trồng: ${val('planting_time')}\n💪 Chịu đựng: ${val('hardiness')}"
                      ),
                    ),

                  // 6. SÂU BỆNH
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

  Widget _buildCard(String title, IconData icon, String content, {Color color = Colors.white}) {
    // Lọc bỏ các dòng null hoặc trống để hiển thị đẹp hơn
    final cleanContent = content.split('\n').where((line) => !line.contains('null') && line.trim().length > 4).join('\n');
    if (cleanContent.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: Colors.green), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const Divider(),
          Text(cleanContent, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
        ],
      ),
    );
  }
}