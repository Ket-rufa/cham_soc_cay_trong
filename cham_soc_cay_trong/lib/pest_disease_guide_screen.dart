import 'dart:convert';

import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/models/plant_disease.dart';
import 'package:cham_soc_cay_trong/pest_disease_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PestDiseaseGuideScreen extends StatefulWidget {
  final String plantId;
  final String plantName;

  const PestDiseaseGuideScreen({
    super.key,
    required this.plantId,
    required this.plantName,
  });

  @override
  State<PestDiseaseGuideScreen> createState() => _PestDiseaseGuideScreenState();
}

class _PestDiseaseGuideScreenState extends State<PestDiseaseGuideScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<PlantDisease> _guides = [];

  @override
  void initState() {
    super.initState();
    _fetchGuides();
  }

  Future<void> _fetchGuides() async {
    try {
      final url = Uri.parse(
        '${Config.apiUrl}/guides?plant_name=${Uri.encodeComponent(widget.plantName)}',
      );
      final response = await http.get(url, headers: Config.apiHeaders);

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
            _guides = guides;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _guides = [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Cẩm nang sâu bệnh',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_hasError) {
      return _GuideMessageState(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        message: 'ÄÃ£ cÃ³ lá»—i xáº£y ra khi táº£i dá»¯ liá»‡u.',
        actionLabel: 'Thá»­ láº¡i',
        onActionPressed: () {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
          _fetchGuides();
        },
      );
    }

    if (_guides.isEmpty) {
      return const _GuideMessageState(
        icon: Icons.inventory_2_outlined,
        iconColor: Colors.grey,
        message: 'ChÆ°a cÃ³ hÆ°á»›ng dáº«n sÃ¢u bá»‡nh cho loáº¡i cÃ¢y nÃ y.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _guides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final disease = _guides[index];
        return DiseaseSummaryCard(
          disease: disease,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PestDiseaseDetailScreen(disease: disease),
              ),
            );
          },
        );
      },
    );
  }
}

class DiseaseSummaryCard extends StatelessWidget {
  final PlantDisease disease;
  final VoidCallback onTap;

  const DiseaseSummaryCard({
    super.key,
    required this.disease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1.5,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: disease.isDisease
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  disease.isDisease
                      ? Icons.warning_amber_rounded
                      : Icons.bug_report_outlined,
                  color: disease.isDisease
                      ? const Color(0xFFE65100)
                      : const Color(0xFF558B2F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                        height: 1.25,
                      ),
                    ),
                    if (disease.englishName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        disease.englishName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      disease.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideMessageState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const _GuideMessageState({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: iconColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onActionPressed,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


