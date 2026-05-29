import 'dart:convert';

import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/custom_dialog.dart';
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
      final response = await http.get(url, headers: Config.apiHeaders);

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

    final bool confirm = await PremiumDialog.showPremiumConfirmDialog(
      context: context,
      title: context.tr('garden.confirmDeleteTitle'),
      message: context.tr('garden.confirmDeleteMessage'),
      confirmText: context.tr('garden.delete'),
      cancelText: context.tr('common.cancel'),
      isDanger: true,
    );

    if (!confirm) return;

    try {
      final url = Uri.parse('${Config.apiUrl}/plants/$id');
      final response = await http.delete(url, headers: Config.apiHeaders);

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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          context.tr('garden.title'),
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        backgroundColor: _softBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: context.tr('garden.reload'),
              icon: const Icon(Icons.refresh_rounded,
                  color: _primaryGreen, size: 26),
              onPressed: _fetchMyGarden,
            ),
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF4CAF50),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('garden.hello'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    careText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.25,
                    children: [
                      _buildStatTile(
                        Icons.local_florist_rounded,
                        context.tr('garden.totalPlants'),
                        stats.total.toString(),
                        const Color(0xFFE8F5E9),
                      ),
                      _buildStatTile(
                        Icons.water_drop_rounded,
                        context.tr('garden.needWater'),
                        stats.needWater.toString(),
                        const Color(0xFFE3F2FD),
                      ),
                      _buildStatTile(
                        Icons.eco_rounded,
                        context.tr('garden.fertilize'),
                        stats.fertilizeSoon.toString(),
                        const Color(0xFFFFF3E0),
                      ),
                      _buildStatTile(
                        Icons.check_circle_rounded,
                        context.tr('garden.healthy'),
                        stats.healthy.toString(),
                        const Color(0xFFE0F2F1),
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

  Widget _buildStatTile(
      IconData icon, String label, String value, Color iconBg) {
    Color iconColor;
    if (icon == Icons.local_florist_rounded) {
      iconColor = const Color(0xFF2E7D32);
    } else if (icon == Icons.water_drop_rounded) {
      iconColor = Colors.blue.shade700;
    } else if (icon == Icons.eco_rounded) {
      iconColor = Colors.orange.shade700;
    } else {
      iconColor = Colors.teal.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: context.tr('garden.searchHint'),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _primaryGreen, size: 22),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: context.tr('garden.clearSearch'),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
          ),
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
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(context.tr(filter.labelKey)),
              selected: selected,
              onSelected: (_) => setState(() => _selectedFilter = filter.value),
              selectedColor: _primaryGreen,
              backgroundColor: Colors.white,
              elevation: selected ? 3 : 0,
              shadowColor: _primaryGreen.withOpacity(0.3),
              side: BorderSide(
                  color: selected ? Colors.transparent : Colors.grey.shade200),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.green.shade50.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant Image
              Hero(
                tag: 'plant-img-${_plantKey(plant)}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 100,
                    height: 136,
                    child: _buildPlantImage(plant),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Plant Info
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        // Mini Red Round Button for Deleting
                        GestureDetector(
                          onTap: () => _deletePlant(plant['id']),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(_careStatusLabel(status), badgeColor),
                    const SizedBox(height: 10),
                    _buildInfoLine(
                      icon: Icons.health_and_safety_rounded,
                      color: _healthStatusColor(health),
                      text: _healthStatusLabel(health),
                    ),
                    _buildInfoLine(
                      icon: Icons.water_drop_rounded,
                      color: Colors.blue,
                      text: _dueLabel(
                        context.tr('garden.water'),
                        _parseDate(plant['nextWateringDate']),
                      ),
                    ),
                    _buildInfoLine(
                      icon: Icons.eco_rounded,
                      color: Colors.green.shade700,
                      text: _dueLabel(
                        context.tr('garden.fertilize'),
                        _parseDate(plant['nextFertilizingDate']),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF2E7D32).withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _markWatered(plant),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.water_drop_rounded,
                                      size: 15),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr('garden.watered'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () => _openDetail(plant),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryGreen,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('garden.details'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 10),
                            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

    return _buildNetworkPlantImage(imageUrl, plant);
  }

  Widget _buildNetworkPlantImage(
    String imageUrl,
    Map<String, dynamic> plant, {
    bool allowProxyFallback = true,
  }) {
    debugPrint(
      '[GardenImage] Load ${_stringValue(plant['name'])}: $imageUrl',
    );

    return Image.network(
      imageUrl,
      headers: Config.getImageHeaders(imageUrl),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.green.shade50,
          child: const Center(
            child: CircularProgressIndicator(
              color: _primaryGreen,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (_, error, ___) {
        debugPrint('[GardenImage] Failed $imageUrl | $error');
        final proxyUrl =
            allowProxyFallback && Config.canUseProxyFallback(imageUrl)
                ? Config.getImageProxyUrl(imageUrl)
                : "";
        if (proxyUrl.isNotEmpty && proxyUrl != imageUrl) {
          return _buildNetworkPlantImage(
            proxyUrl,
            plant,
            allowProxyFallback: false,
          );
        }
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.green.shade50,
          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
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
    return Config.getPlantImageUrl(plant);
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
