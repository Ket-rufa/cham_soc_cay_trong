import 'dart:convert';

import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/library_detail_screen.dart';
import 'package:cham_soc_cay_trong/top_toast_util.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum GardenFilter { all, needWater, fertilizeSoon, healthy }

class MyGardenTab extends StatefulWidget {
  const MyGardenTab({super.key});

  @override
  State<MyGardenTab> createState() => _MyGardenTabState();
}

class _MyGardenTabState extends State<MyGardenTab> {
  static const Color _primaryGreen = Color(0xFF25BB57);
  static const Color _softBackground = Color(0xFFF5F7FA);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _myPlants = [];
  bool _isLoading = true;
  GardenFilter _selectedFilter = GardenFilter.all;
  String _searchQuery = '';

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchMyGarden();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyGarden() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final url = Uri.parse('${Config.apiUrl}/plants');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final rawPlants = jsonResponse['data'];
        final plants = rawPlants is List ? rawPlants : [];

        if (!mounted) return;
        setState(() {
          _myPlants = plants
              .asMap()
              .entries
              .where((entry) => entry.value is Map)
              .map((entry) => _normalizePlant(
                    Map<String, dynamic>.from(entry.value as Map),
                    entry.key,
                  ))
              .toList();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePlant(dynamic id) async {
    if (id == null) return;

    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('garden.confirmDeleteTitle')),
            content: Text(context.tr('garden.confirmDeleteMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  context.tr('garden.delete'),
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final url = Uri.parse('${Config.apiUrl}/plants/$id');
      final response = await http.delete(url);

      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _myPlants
              .removeWhere((plant) => plant['id'].toString() == id.toString());
        });
        TopToast.show(context, context.tr('garden.deleted'));
      } else {
        TopToast.show(
          context,
          context.tr('garden.deleteFailed'),
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    } catch (_) {
      if (!mounted) return;
      TopToast.show(
        context,
        context.tr('garden.deleteConnectionError'),
        backgroundColor: Colors.red,
        icon: Icons.wifi_off_rounded,
      );
    }
  }

  Map<String, dynamic> _normalizePlant(Map<String, dynamic> plant, int index) {
    final name = _stringValue(plant['name'] ?? plant['name_vi'],
        fallback: 'Cây không tên');
    final wateringInterval = _intValue(
      plant['wateringIntervalDays'] ?? plant['watering_interval_days'],
      fallback: _suggestWateringInterval(name),
    );
    final fertilizingInterval = _intValue(
      plant['fertilizingIntervalDays'] ?? plant['fertilizing_interval_days'],
      fallback: _suggestFertilizingInterval(name),
    );

    final nextWateringDate = _parseDate(
          plant['nextWateringDate'] ?? plant['next_watering_date'],
        ) ??
        _defaultNextWateringDate(name, index);
    final lastWatered = _parseDate(
          plant['lastWatered'] ?? plant['last_watered'],
        ) ??
        nextWateringDate.subtract(Duration(days: wateringInterval));
    final nextFertilizingDate = _parseDate(
          plant['nextFertilizingDate'] ?? plant['next_fertilizing_date'],
        ) ??
        _defaultNextFertilizingDate(name, index);

    final normalizedPlant = Map<String, dynamic>.from(plant)
      ..['name'] = name
      ..['name_vi'] = plant['name_vi'] ?? name
      ..['isInGarden'] = true
      ..['healthStatus'] = _stringValue(
        plant['healthStatus'] ?? plant['health_status'],
        fallback: _defaultHealthStatus(name, index),
      )
      ..['lastWatered'] = _dateToIso(lastWatered)
      ..['nextWateringDate'] = _dateToIso(nextWateringDate)
      ..['nextFertilizingDate'] = _dateToIso(nextFertilizingDate)
      ..['wateringIntervalDays'] = wateringInterval
      ..['fertilizingIntervalDays'] = fertilizingInterval;

    final logs = _normalizeLogs(
      plant['careLogs'] ?? plant['care_logs'] ?? plant['histories'],
      name,
    );
    normalizedPlant['careLogs'] =
        logs.isEmpty ? _defaultCareLogs(name, lastWatered) : logs;

    return normalizedPlant;
  }

  List<Map<String, dynamic>> _normalizeLogs(dynamic rawLogs, String plantName) {
    if (rawLogs is! List) return [];

    return rawLogs.whereType<Map>().map((log) {
      final item = Map<String, dynamic>.from(log);
      final rawDate = item['date'] ?? item['created_at'];
      final date = _parseDate(rawDate) ?? _today;
      final type = _stringValue(item['type'] ?? item['task_type']);
      final note = _stringValue(
        item['note'] ?? item['action'],
        fallback: _defaultLogNote(type, plantName),
      );

      return {
        'id': _stringValue(item['id'],
            fallback: 'log-${date.millisecondsSinceEpoch}'),
        'date': _dateToIso(date),
        'type': type.isEmpty ? 'note' : type,
        'note': note,
      };
    }).toList()
      ..sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
  }

  List<Map<String, dynamic>> _defaultCareLogs(
      String name, DateTime lastWatered) {
    final fertilizerDate = _today.subtract(const Duration(days: 5));
    return [
      _createCareLog(
        type: 'water',
        note: 'Đã tưới nước, kiểm tra độ ẩm đất',
        date: lastWatered.isAfter(_today) ? _today : lastWatered,
      ),
      _createCareLog(
        type: 'fertilize',
        note: 'Bón phân hữu cơ liều nhẹ cho $name',
        date: fertilizerDate,
      ),
    ];
  }

  Map<String, dynamic> _createCareLog({
    required String type,
    required String note,
    DateTime? date,
  }) {
    final logDate = date ?? _today;
    return {
      'id': 'log-${DateTime.now().microsecondsSinceEpoch}',
      'date': _dateToIso(logDate),
      'type': type,
      'note': note,
    };
  }

  String _defaultLogNote(String type, String plantName) {
    switch (type) {
      case 'water':
      case 'watering':
        return 'Đã tưới nước cho $plantName';
      case 'fertilize':
      case 'fertilizing':
        return 'Đã bón phân cho $plantName';
      default:
        return 'Cập nhật chăm sóc cho $plantName';
    }
  }

  DateTime _defaultNextWateringDate(String name, int index) {
    final normalized = name.toLowerCase();
    if (normalized.contains('sen')) return _today;
    if (normalized.contains('mai')) return _today.add(const Duration(days: 1));
    if (normalized.contains('hồng') || normalized.contains('hong')) {
      return _today.add(const Duration(days: 1));
    }

    if (index % 3 == 0) return _today;
    if (index % 3 == 1) return _today.add(const Duration(days: 1));
    return _today.add(const Duration(days: 2));
  }

  DateTime _defaultNextFertilizingDate(String name, int index) {
    final normalized = name.toLowerCase();
    if (normalized.contains('hồng') || normalized.contains('hong')) {
      return _today.add(const Duration(days: 2));
    }
    if (normalized.contains('mai')) return _today.add(const Duration(days: 7));
    if (normalized.contains('sen')) return _today.add(const Duration(days: 10));

    return index % 3 == 1
        ? _today.add(const Duration(days: 2))
        : _today.add(const Duration(days: 7));
  }

  String _defaultHealthStatus(String name, int index) {
    final normalized = name.toLowerCase();
    if (normalized.contains('hồng') || normalized.contains('hong')) {
      return 'warning';
    }
    return index % 5 == 4 ? 'warning' : 'healthy';
  }

  int _suggestWateringInterval(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('sen')) return 1;
    if (normalized.contains('mai')) return 2;
    return 3;
  }

  int _suggestFertilizingInterval(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('hồng') || normalized.contains('hong')) return 14;
    return 30;
  }

  List<Map<String, dynamic>> get _visiblePlants {
    final query = _searchQuery.trim().toLowerCase();

    return _myPlants.where((plant) {
      final name = _stringValue(plant['name']).toLowerCase();
      final matchesSearch = query.isEmpty || name.contains(query);
      final matchesFilter = _matchesFilter(plant);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  bool _matchesFilter(Map<String, dynamic> plant) {
    switch (_selectedFilter) {
      case GardenFilter.all:
        return true;
      case GardenFilter.needWater:
        return _needsWater(plant);
      case GardenFilter.fertilizeSoon:
        return _isFertilizeSoon(plant);
      case GardenFilter.healthy:
        return plant['healthStatus'] == 'healthy';
    }
  }

  _GardenStats get _stats {
    final needWater = _myPlants.where(_needsWater).length;
    final fertilizeSoon = _myPlants.where(_isFertilizeSoon).length;
    final healthy =
        _myPlants.where((plant) => plant['healthStatus'] == 'healthy').length;
    final needCare = _myPlants
        .where((plant) => _needsWater(plant) || _isFertilizeSoon(plant))
        .length;

    return _GardenStats(
      total: _myPlants.length,
      needWater: needWater,
      fertilizeSoon: fertilizeSoon,
      healthy: healthy,
      needCare: needCare,
    );
  }

  bool _needsWater(Map<String, dynamic> plant) {
    final nextWatering = _parseDate(plant['nextWateringDate']);
    if (nextWatering == null) return false;
    return !nextWatering.isAfter(_today);
  }

  bool _isFertilizeSoon(Map<String, dynamic> plant) {
    final nextFertilizing = _parseDate(plant['nextFertilizingDate']);
    if (nextFertilizing == null) return false;
    return _daysUntil(nextFertilizing) <= 3;
  }

  String _careStatus(Map<String, dynamic> plant) {
    if (_needsWater(plant)) return 'need_water';
    if (_isFertilizeSoon(plant)) return 'fertilize_soon';
    return 'normal';
  }

  void _markWatered(Map<String, dynamic> plant) {
    final wateringInterval =
        _intValue(plant['wateringIntervalDays'], fallback: 2);
    final nextWateringDate = _today.add(Duration(days: wateringInterval));
    final newLog = _createCareLog(
      type: 'water',
      note: 'Đã tưới nước hôm nay',
      date: _today,
    );

    setState(() {
      _myPlants = _myPlants.map((item) {
        if (_plantKey(item) != _plantKey(plant)) return item;

        final logs = _careLogsOf(item);
        return Map<String, dynamic>.from(item)
          ..['lastWatered'] = _dateToIso(_today)
          ..['nextWateringDate'] = _dateToIso(nextWateringDate)
          ..['careLogs'] = [newLog, ...logs];
      }).toList();
    });

    TopToast.show(context, context.tr('garden.waterUpdated'));
  }

  void _mergeUpdatedPlant(Map<String, dynamic> updatedPlant) {
    setState(() {
      _myPlants = _myPlants.map((plant) {
        if (_plantKey(plant) != _plantKey(updatedPlant)) return plant;
        return Map<String, dynamic>.from(plant)..addAll(updatedPlant);
      }).toList();
    });
  }

  Future<void> _openDetail(Map<String, dynamic> plant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_plant_id', _stringValue(plant['id']));
    await prefs.setString('active_plant_name', _stringValue(plant['name']));

    if (!mounted) return;

    final imagePath = _resolvedImageUrl(plant);
    final detailData = Map<String, dynamic>.from(plant)
      ..['name_vi'] = plant['name']
      ..['isInGarden'] = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LibraryDetailScreen(
          imagePath: imagePath,
          plantData: detailData,
          hideAddButton: true,
          onCareUpdated: _mergeUpdatedPlant,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlants = _visiblePlants;
    final stats = _stats;

    return Scaffold(
      backgroundColor: _softBackground,
      appBar: AppBar(
        title: Text(
          context.tr('garden.title'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: context.tr('garden.reload'),
            icon: const Icon(Icons.refresh, color: _primaryGreen),
            onPressed: _fetchMyGarden,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryGreen))
          : RefreshIndicator(
              color: _primaryGreen,
              onRefresh: _fetchMyGarden,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _buildDashboard(stats),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  if (_myPlants.isEmpty)
                    _buildEmptyState(
                      icon: Icons.local_florist_outlined,
                      title: context.tr('garden.emptyTitle'),
                      message: context.tr('garden.emptyMessage'),
                    )
                  else if (visiblePlants.isEmpty)
                    _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.tr('garden.noResultTitle'),
                      message: context.tr('garden.noResultMessage'),
                    )
                  else
                    ...visiblePlants.map(_buildPlantCard),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboard(_GardenStats stats) {
    final careText = stats.needCare == 0
        ? context.tr('garden.healthyToday')
        : context.tr(
            'garden.needCareToday',
            params: <String, String>{'count': stats.needCare.toString()},
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('garden.hello'),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            careText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.25,
            children: [
              _buildStatTile(Icons.local_florist_rounded,
                  context.tr('garden.totalPlants'), stats.total.toString()),
              _buildStatTile(Icons.water_drop_rounded,
                  context.tr('garden.needWater'), stats.needWater.toString()),
              _buildStatTile(Icons.eco_rounded, context.tr('garden.fertilize'),
                  stats.fertilizeSoon.toString()),
              _buildStatTile(Icons.check_circle_rounded,
                  context.tr('garden.healthy'), stats.healthy.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _primaryGreen, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('garden.searchHint'),
        prefixIcon: const Icon(Icons.search_rounded, color: _primaryGreen),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: context.tr('garden.clearSearch'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = [
      _FilterOption(GardenFilter.all, 'garden.allFilter'),
      _FilterOption(GardenFilter.needWater, 'garden.needWater'),
      _FilterOption(GardenFilter.fertilizeSoon, 'garden.fertilizeSoon'),
      _FilterOption(GardenFilter.healthy, 'garden.healthy'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.tr(filter.labelKey)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedFilter = filter.value),
              selectedColor: _primaryGreen,
              backgroundColor: Colors.white,
              side: BorderSide(
                  color: selected ? _primaryGreen : Colors.grey.shade200),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlantCard(Map<String, dynamic> plant) {
    final status = _careStatus(plant);
    final badgeColor = _careStatusColor(status);
    final health = _stringValue(plant['healthStatus'], fallback: 'healthy');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 94,
                height: 132,
                child: _buildPlantImage(plant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _stringValue(plant['name'],
                              fallback: 'Cây không tên'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          tooltip: context.tr('garden.deletePlant'),
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 21),
                          color: Colors.redAccent,
                          onPressed: () => _deletePlant(plant['id']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(_careStatusLabel(status), badgeColor),
                  const SizedBox(height: 8),
                  _buildInfoLine(
                    icon: Icons.health_and_safety_outlined,
                    color: _healthStatusColor(health),
                    text: _healthStatusLabel(health),
                  ),
                  const SizedBox(height: 5),
                  _buildInfoLine(
                    icon: Icons.water_drop_outlined,
                    color: Colors.blue,
                    text: _dueLabel(
                      context.tr('garden.water'),
                      _parseDate(plant['nextWateringDate']),
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildInfoLine(
                    icon: Icons.eco_outlined,
                    color: Colors.green.shade700,
                    text: _dueLabel(
                      context.tr('garden.fertilize'),
                      _parseDate(plant['nextFertilizingDate']),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _markWatered(plant),
                          icon: const Icon(Icons.water_drop_rounded, size: 16),
                          label: Text(context.tr('garden.watered')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openDetail(plant),
                          icon: const Icon(Icons.article_outlined, size: 16),
                          label: Text(context.tr('garden.details')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryGreen,
                            side: const BorderSide(color: _primaryGreen),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoLine({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlantImage(Map<String, dynamic> plant) {
    final imageUrl = _resolvedImageUrl(plant);
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.green.shade50,
        child: const Icon(Icons.local_florist_rounded, color: _primaryGreen),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.green.shade50,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _resolvedImageUrl(Map<String, dynamic> plant) {
    final rawImage = _stringValue(plant['image'] ?? plant['image_url']);
    if (rawImage.isEmpty) return '';
    if (rawImage.startsWith('http')) return Config.getImageUrl(rawImage);

    final baseUrl = Config.apiUrl.replaceAll('/api', '');
    final normalizedPath = rawImage.startsWith('/') ? rawImage : '/$rawImage';
    return '$baseUrl$normalizedPath';
  }

  List<Map<String, dynamic>> _careLogsOf(Map<String, dynamic> plant) {
    final logs = plant['careLogs'];
    if (logs is! List) return [];

    return logs
        .whereType<Map>()
        .map((log) => Map<String, dynamic>.from(log))
        .toList();
  }

  String _plantKey(Map<String, dynamic> plant) {
    return _stringValue(plant['id'] ?? plant['plantId'] ?? plant['name']);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return DateUtils.dateOnly(value.toLocal());

    final raw = value.toString();
    if (raw.trim().isEmpty || raw == 'null') return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateUtils.dateOnly(parsed.toLocal());
  }

  String _dateToIso(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _daysUntil(DateTime date) {
    return DateUtils.dateOnly(date).difference(_today).inDays;
  }

  String _dueLabel(String label, DateTime? date) {
    if (date == null) return '$label: ${context.tr('garden.notScheduled')}';

    final days = _daysUntil(date);
    if (days <= 0) return '$label ${context.tr('garden.today')}';
    if (days == 1) return '$label ${context.tr('garden.afterOneDay')}';
    return '$label ${context.tr(
      'garden.afterDays',
      params: <String, String>{'count': days.toString()},
    )}';
  }

  String _careStatusLabel(String status) {
    switch (status) {
      case 'need_water':
        return context.tr('garden.needWaterToday');
      case 'fertilize_soon':
        return context.tr('garden.fertilizeSoon');
      case 'normal':
      default:
        return context.tr('garden.normal');
    }
  }

  Color _careStatusColor(String status) {
    switch (status) {
      case 'need_water':
        return const Color(0xFFE53935);
      case 'fertilize_soon':
        return const Color(0xFFF59E0B);
      case 'normal':
      default:
        return _primaryGreen;
    }
  }

  String _healthStatusLabel(String status) {
    switch (status) {
      case 'warning':
        return context.tr('garden.needsAttention');
      case 'danger':
        return context.tr('garden.hasIssue');
      case 'healthy':
      default:
        return context.tr('garden.healthy');
    }
  }

  Color _healthStatusColor(String status) {
    switch (status) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'danger':
        return const Color(0xFFE53935);
      case 'healthy':
      default:
        return _primaryGreen;
    }
  }

  int _intValue(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }
}

class _GardenStats {
  final int total;
  final int needWater;
  final int fertilizeSoon;
  final int healthy;
  final int needCare;

  const _GardenStats({
    required this.total,
    required this.needWater,
    required this.fertilizeSoon,
    required this.healthy,
    required this.needCare,
  });
}

class _FilterOption {
  final GardenFilter value;
  final String labelKey;

  const _FilterOption(this.value, this.labelKey);
}
