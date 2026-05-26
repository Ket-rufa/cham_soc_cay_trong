import 'dart:math' as math;

import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/models/plant_disease.dart';
import 'package:flutter/material.dart';

class PestDiseaseDetailScreen extends StatelessWidget {
  final PlantDisease disease;

  const PestDiseaseDetailScreen({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          disease.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DiseaseDetailHeader(disease: disease),
            const SizedBox(height: 16),
            DiseaseMainImage(imageUrl: disease.mainImageUrl),
            const SizedBox(height: 16),
            ShortDescriptionCard(description: disease.shortDescription),
            const SizedBox(height: 12),
            DiseaseInfoSection(
              title: 'Dấu hiệu (Symptoms)',
              content: disease.symptoms,
            ),
            DiseaseInfoSection(
              title: 'Nguyên nhân (Causes)',
              content: disease.causes,
            ),
            DiseaseInfoSection(
              title: 'Phòng ngừa (Prevention)',
              content: disease.prevention,
            ),
            DiseaseInfoSection(
              title: 'Điều trị (Treatment)',
              content: disease.treatment,
            ),
            DiseaseImageGallery(imageUrls: disease.galleryImageUrls),
            SusceptiblePlantTopList(plants: disease.susceptiblePlants),
          ],
        ),
      ),
    );
  }
}

class DiseaseDetailHeader extends StatelessWidget {
  final PlantDisease disease;

  const DiseaseDetailHeader({
    super.key,
    required this.disease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: disease.isDisease
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFF1F8E9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            disease.isDisease
                ? Icons.warning_amber_rounded
                : Icons.bug_report_outlined,
            color: disease.isDisease
                ? const Color(0xFFE65100)
                : const Color(0xFF558B2F),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                disease.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                  height: 1.2,
                ),
              ),
              if (disease.englishName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  disease.englishName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class DiseaseMainImage extends StatelessWidget {
  final String imageUrl;

  const DiseaseMainImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DiseaseImageFrame(
          imageUrl: imageUrl,
          height: 200,
          borderRadius: 16,
        ),
        const SizedBox(height: 8),
        Text(
          'Ảnh minh họa triệu chứng điển hình',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class ShortDescriptionCard extends StatelessWidget {
  final String description;

  const ShortDescriptionCard({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Color(0xFF455A64),
        ),
      ),
    );
  }
}

class DiseaseInfoSection extends StatelessWidget {
  final String title;
  final String content;

  const DiseaseInfoSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class DiseaseImageGallery extends StatelessWidget {
  final List<String> imageUrls;

  const DiseaseImageGallery({
    super.key,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh minh họa thêm',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imageUrl = imageUrls[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _DiseaseImagePreviewDialog(
                      imageUrl: imageUrl,
                    ),
                  ),
                  child: DiseaseImageFrame(
                    imageUrl: imageUrl,
                    width: 104,
                    height: 96,
                    borderRadius: 12,
                    compact: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SusceptiblePlantTopList extends StatelessWidget {
  final List<SusceptiblePlant> plants;

  const SusceptiblePlantTopList({
    super.key,
    required this.plants,
  });

  @override
  Widget build(BuildContext context) {
    if (plants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_florist, size: 18, color: Color(0xFFE65100)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Top 3 loài hoa dễ mắc bệnh này',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...plants.take(3).map(
                (plant) => SusceptiblePlantCard(plant: plant),
              ),
        ],
      ),
    );
  }
}

class SusceptiblePlantCard extends StatelessWidget {
  final SusceptiblePlant plant;

  const SusceptiblePlantCard({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _rankColor(plant.rank).withAlpha(120)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: _rankColor(plant.rank),
            child: Text(
              plant.rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF37474F),
                    height: 1.25,
                  ),
                ),
                if (plant.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plant.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB300);
      case 2:
        return const Color(0xFF90A4AE);
      default:
        return const Color(0xFFB87333);
    }
  }
}

class DiseaseImageFrame extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double height;
  final double borderRadius;
  final bool compact;

  const DiseaseImageFrame({
    super.key,
    required this.imageUrl,
    this.width,
    required this.height,
    required this.borderRadius,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveDiseaseImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: resolvedUrl.isEmpty
            ? _buildPlaceholder()
            : _buildImage(resolvedUrl),
      ),
    );
  }

  Widget _buildImage(String resolvedUrl) {
    if (_isAssetPath(resolvedUrl)) {
      return Image.asset(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.network(
      resolvedUrl,
      headers: Config.imageHeaders,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _buildPlaceholder(isLoading: true);
      },
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green,
                ),
              )
            else
              Icon(
                Icons.image_not_supported_outlined,
                size: compact ? 24 : 34,
                color: Colors.grey.shade500,
              ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                isLoading ? 'Đang tải ảnh' : 'Chưa có ảnh minh họa',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _isAssetPath(String url) {
    return url.startsWith('assets/');
  }

  static String _resolveDiseaseImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || _isAssetPath(trimmed)) {
      return trimmed;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Config.getImageUrl(trimmed);
    }

    final serverBaseUrl = Config.apiUrl.replaceAll('/api', '');
    if (trimmed.startsWith('/')) {
      return '$serverBaseUrl$trimmed';
    }
    return '$serverBaseUrl/$trimmed';
  }
}

class _DiseaseImagePreviewDialog extends StatelessWidget {
  final String imageUrl;

  const _DiseaseImagePreviewDialog({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = math.min(
      420.0,
      MediaQuery.of(context).size.height * 0.58,
    );

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Đóng',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: DiseaseImageFrame(
              imageUrl: imageUrl,
              height: imageHeight,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
