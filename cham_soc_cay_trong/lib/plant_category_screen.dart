import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'library_detail_screen.dart';

class PlantCategoryScreen extends StatelessWidget {
  const PlantCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Color(0xFF1B5E20), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          context.tr('plantList.title'),
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: const _PlantLibraryGrid(categoryType: "Hoa"),
    );
  }
}

// ============================================================
// GRID STATE
// ============================================================
class _PlantLibraryGrid extends StatefulWidget {
  final String categoryType;
  const _PlantLibraryGrid({required this.categoryType});

  @override
  State<_PlantLibraryGrid> createState() => _PlantLibraryGridState();
}

class _PlantLibraryGridState extends State<_PlantLibraryGrid> {
  List _allPlants = [];
  List _foundPlants = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
  }

  Future<void> _fetchLibrary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = Uri.parse(
          '${Config.apiUrl}/library?type=${widget.categoryType}');
      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = (jsonResponse['data'] as List?) ?? [];

        // DEBUG: log các record bị thiếu image_url
        for (final plant in data) {
          final rawUrl = plant['image_url'];
          if (rawUrl == null || (rawUrl as String).trim().isEmpty) {
            debugPrint(
                '[PlantCat] ⚠️  No image_url: ${plant['name']}');
          }
        }

        if (mounted) {
          setState(() {
            _allPlants = data;
            _foundPlants = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      debugPrint('[PlantCat] Error fetching library: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _runFilter(String keyword) {
    setState(() {
      _foundPlants = keyword.isEmpty
          ? _allPlants
          : _allPlants
              .where((p) => (p['name'] ?? '')
                  .toLowerCase()
                  .contains(keyword.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- THANH TÌM KIẾM ----
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              onChanged: _runFilter,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: context.tr('plantList.searchHint'),
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 15),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF25BB57), size: 22),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: Color(0xFF25BB57), width: 1.5),
                ),
              ),
            ),
          ),
        ),

        // ---- LƯỚI KẾT QUẢ ----
        Expanded(
          child: _isLoading
              ? _buildSkeletonGrid()
              : _hasError
                  ? _buildErrorState()
                  : _foundPlants.isEmpty
                      ? _buildEmptyState(context)
                      : GridView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _foundPlants.length,
                          addRepaintBoundaries: true,
                          itemBuilder: (context, index) {
                            final plant = _foundPlants[index];
                            return _PlantCard(
                              plant: plant,
                              onTap: () =>
                                  _navigateToDetail(context, plant),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, dynamic plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryDetailScreen(
          imagePath: Config.getImageUrl(plant['image_url']),
          plantData: {
            'name_vi': plant['name'],
            'scientific_name': plant['scientific_name'] ?? '',
            'description': plant['description'] ??
                context.tr('plantList.noDescription'),
            'family': plant['family'],
            'genus': plant['genus'],
            'light': plant['light'],
            'water': plant['water'],
            'temp': plant['temp'],
            'soil': plant['soil'],
            'fertilizer': plant['fertilizer'],
            'planting_time': plant['planting_time'],
            'pruning': plant['pruning'],
            'propagation': plant['propagation'],
            'pests': plant['pests'],
            'care_tips': plant['care_tips'],
            'difficulty': plant['difficulty'],
            'hardiness': plant['hardiness'],
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không thể tải dữ liệu\nKiểm tra kết nối mạng',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchLibrary,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25BB57),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            context.tr('plantList.empty'),
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PLANT CARD — Stateless, tách riêng để tránh rebuild toàn grid
// ============================================================
class _PlantCard extends StatelessWidget {
  final dynamic plant;
  final VoidCallback onTap;

  const _PlantCard({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String difficulty = plant['difficulty'] ?? 'Dễ';
    final String light = plant['light'] ?? 'Ánh sáng tự nhiên';

    Color diffBg;
    Color diffIcon;
    if (difficulty.toLowerCase().contains('dễ') ||
        difficulty.toLowerCase().contains('easy')) {
      diffBg = const Color(0xFFE0F2F1);
      diffIcon = const Color(0xFF00796B);
    } else if (difficulty.toLowerCase().contains('trung bình') ||
        difficulty.toLowerCase().contains('medium')) {
      diffBg = const Color(0xFFFFF3E0);
      diffIcon = const Color(0xFFF57C00);
    } else {
      diffBg = const Color(0xFFFFEBEE);
      diffIcon = const Color(0xFFD32F2F);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- PHẦN ẢNH ----
                Expanded(
                  flex: 13,
                  child: _PlantImage(
                    imageUrl: plant['image_url'],
                    plantName: plant['name'] ?? 'Cây',
                  ),
                ),
                // ---- PHẦN THÔNG TIN ----
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plant['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: Color(0xFF1E293B),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          children: [
                            _InfoRow(
                              bgColor: diffBg,
                              iconColor: diffIcon,
                              icon: Icons.bar_chart_rounded,
                              text: difficulty,
                            ),
                            const SizedBox(height: 4),
                            _InfoRow(
                              bgColor: const Color(0xFFFFFDE7),
                              iconColor: const Color(0xFFFBC02D),
                              icon: Icons.wb_sunny_rounded,
                              text: light,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PLANT IMAGE — STATELESS, dùng built-in loadingBuilder/errorBuilder
// KHÔNG dùng StatefulWidget để tránh "setState during build" bug
// ============================================================
class _PlantImage extends StatelessWidget {
  final String? imageUrl;
  final String plantName;

  static const Map<String, String> _wikiHeaders = {
    // Wikipedia yêu cầu User-Agent mô tả app, không được để trống
    'User-Agent': 'ChamSocCayTrong/1.0 (Flutter mobile app; educational)',
    'Referer': 'https://vi.wikipedia.org/',
  };

  const _PlantImage({required this.imageUrl, required this.plantName});

  @override
  Widget build(BuildContext context) {
    final resolved = Config.getImageUrl(imageUrl);

    // URL rỗng hoặc invalid -> hiển thị placeholder ngay
    if (resolved.isEmpty) {
      debugPrint('[PlantImage] ⚠️  No image_url for: $plantName');
      return _buildPlaceholder();
    }

    // Chọn headers phù hợp: Wikipedia dùng header riêng
    final headers = resolved.contains('wikimedia.org') ||
            resolved.contains('wikipedia.org')
        ? _wikiHeaders
        : Config.imageHeaders;

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      headers: headers,
      // loadingBuilder: hiện skeleton trong khi đang tải
      // QUAN TRỌNG: callback này được gọi bởi Flutter framework,
      // KHÔNG được gọi setState bên trong — đây là nguyên nhân bug cũ
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Ảnh đã load xong -> hiện ảnh với fade-in qua AnimatedSwitcher
          return child;
        }
        // Đang tải -> hiện skeleton shimmer
        return _buildLoadingShimmer(loadingProgress);
      },
      errorBuilder: (context, error, stackTrace) {
        // Log lỗi để debug
        debugPrint(
            '[PlantImage] ❌ Failed to load image for $plantName: $resolved\n  Error: $error');
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildLoadingShimmer(ImageChunkEvent loadingProgress) {
    // Tính % progress nếu có
    final double? progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return _AnimatedShimmer(progress: progress);
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: Color(0xFF2E7D32),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có ảnh',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ANIMATED SHIMMER — StatefulWidget chỉ để chạy animation
// Hoàn toàn độc lập, không gây setState trong build của parent
// ============================================================
class _AnimatedShimmer extends StatefulWidget {
  final double? progress;
  const _AnimatedShimmer({this.progress});

  @override
  State<_AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<_AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.lerp(
                  const Color(0xFFE0E0E0), const Color(0xFFF5F5F5), _anim.value)!,
              Color.lerp(
                  const Color(0xFFF5F5F5), const Color(0xFFE0E0E0), _anim.value)!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: widget.progress != null
            ? Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: widget.progress,
                  backgroundColor: Colors.transparent,
                  color: Colors.green.withValues(alpha: 0.3),
                  minHeight: 2,
                ),
              )
            : null,
      ),
    );
  }
}

// ============================================================
// SKELETON CARD — Placeholder khi đang tải danh sách
// ============================================================
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            const Expanded(
              flex: 13,
              child: _AnimatedShimmer(),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shimmerLine(double.infinity, 14),
                    _shimmerLine(80, 10),
                    _shimmerLine(100, 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerLine(double width, double height) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: const _AnimatedShimmer(),
      ),
    );
  }
}

// ============================================================
// INFO ROW — Dòng icon + text nhỏ trong card
// ============================================================
class _InfoRow extends StatelessWidget {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.bgColor,
    required this.iconColor,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
