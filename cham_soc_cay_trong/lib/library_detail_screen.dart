import 'dart:convert';

import 'package:cham_soc_cay_trong/config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LibraryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  final String imagePath;
  final bool hideAddButton;
  final ValueChanged<Map<String, dynamic>>? onCareUpdated;

  const LibraryDetailScreen({
    super.key,
    required this.plantData,
    required this.imagePath,
    this.hideAddButton = false,
    this.onCareUpdated,
  });

  @override
  State<LibraryDetailScreen> createState() => _LibraryDetailScreenState();
}

class _LibraryDetailScreenState extends State<LibraryDetailScreen> {
  static const Color _primaryGreen = Color(0xFF25BB57);
  static const Color _softBackground = Color(0xFFF5F7FA);
  static const Color _darkText = Color(0xFF202124);

  final TextEditingController _noteController = TextEditingController();

  late Map<String, dynamic> _plantData;
  bool _isSaving = false;
  bool _isSavedInGarden = false;
  bool _showNoteForm = false;
  late DateTime _selectedNoteDate;
  late TimeOfDay _selectedNoteTime;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  String get _plantName => _value(
        'name_vi',
        fallback: _value('name', fallback: 'Chi tiết cây'),
      );

  bool get _isGardenPlant {
    return widget.hideAddButton ||
        _isSavedInGarden ||
        _boolValue(_plantData['isInGarden']) ||
        _boolValue(_plantData['is_in_garden']);
  }

  @override
  void initState() {
    super.initState();
    _plantData = Map<String, dynamic>.from(widget.plantData);
    _selectedNoteDate = _today;
    _selectedNoteTime = TimeOfDay.fromDateTime(DateTime.now());
    _ensureCareDefaults();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveToGarden() async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/plants'),
        body: {
          'name': _plantName,
          'location': 'Sân vườn',
          'image_url': widget.imagePath,
        },
        headers: {'Accept': 'application/json'},
      );

      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isSavedInGarden = true;
          _plantData['isInGarden'] = true;
          _ensureCareDefaults();
        });
        _showSnackBar('Đã thêm vào Vườn');
      } else {
        _showSnackBar('Lỗi lưu cây: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi mạng: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _ensureCareDefaults() {
    final initialCareStatus = _stringValue(
      _plantData['careStatus'] ?? _plantData['care_status'],
    );
    final defaultNextWatering = initialCareStatus == 'need_water'
        ? _today
        : _today.add(const Duration(days: 1));
    final defaultNextFertilizing = initialCareStatus == 'fertilize_soon'
        ? _today.add(const Duration(days: 2))
        : _today.add(const Duration(days: 7));
    final nextWatering = _parseDate(_plantData['nextWateringDate']) ??
        _parseDate(_plantData['next_watering_date']) ??
        defaultNextWatering;
    final nextFertilizing = _parseDate(_plantData['nextFertilizingDate']) ??
        _parseDate(_plantData['next_fertilizing_date']) ??
        defaultNextFertilizing;
    final wateringInterval = _intValue(
      _plantData['wateringIntervalDays'] ??
          _plantData['watering_interval_days'],
      fallback: _suggestWateringInterval(),
    );
    final fertilizingInterval = _intValue(
      _plantData['fertilizingIntervalDays'] ??
          _plantData['fertilizing_interval_days'],
      fallback: _suggestFertilizingInterval(),
    );
    final lastWatered = _parseDate(_plantData['lastWatered']) ??
        _parseDate(_plantData['last_watered']) ??
        nextWatering.subtract(Duration(days: wateringInterval));

    _plantData['healthStatus'] = _stringValue(
      _plantData['healthStatus'] ?? _plantData['health_status'],
      fallback: _defaultHealthStatus(),
    );
    _plantData['lastWatered'] = _dateToIso(lastWatered);
    _plantData['nextWateringDate'] = _dateToIso(nextWatering);
    _plantData['nextFertilizingDate'] = _dateToIso(nextFertilizing);
    _plantData['wateringIntervalDays'] = wateringInterval;
    _plantData['fertilizingIntervalDays'] = fertilizingInterval;
    _plantData['pruningSchedule'] = _stringValue(
      _plantData['pruningSchedule'] ?? _plantData['pruning_schedule'],
      fallback: _defaultPruningSchedule(),
    );
    _plantData['pestCheckSchedule'] = _stringValue(
      _plantData['pestCheckSchedule'] ?? _plantData['pest_check_schedule'],
      fallback: 'Mỗi tuần',
    );
    _plantData['careLogs'] = _careLogsOf(_plantData);
  }

  void _markWateredToday() {
    final wateringInterval =
        _intValue(_plantData['wateringIntervalDays'], fallback: 2);
    final nextDate = _today.add(Duration(days: wateringInterval));
    _applyCareUpdate(
      updates: {
        'lastWatered': _dateToIso(_today),
        'nextWateringDate': _dateToIso(nextDate),
      },
      log: _createCareLog(
        type: 'water',
        note: 'Đã tưới nước',
        date: _today,
      ),
      message: 'Đã cập nhật tưới nước',
    );
  }

  void _markFertilized() {
    final interval =
        _intValue(_plantData['fertilizingIntervalDays'], fallback: 30);
    final nextDate = _today.add(Duration(days: interval));
    _applyCareUpdate(
      updates: {'nextFertilizingDate': _dateToIso(nextDate)},
      log: _createCareLog(
        type: 'fertilize',
        note: 'Đã bón phân',
        date: _today,
      ),
      message: 'Đã cập nhật bón phân',
    );
  }

  Future<void> _addNote() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      _showSnackBar('Vui lòng nhập ghi chú', isError: true);
      return;
    }

    final log = _createCareLog(
      type: 'note',
      note: note,
      date: _selectedNoteDate,
      time: _selectedNoteTime,
    );

    _applyCareUpdate(
      updates: const {},
      log: log,
      message: 'Đã thêm ghi chú',
    );

    await _createScheduleFromNote(note: note);

    _resetNoteForm();
  }

  Future<void> _createScheduleFromNote({required String note}) async {
    final plantId = _stringValue(_plantData['id'] ?? _plantData['plant_id']);
    if (plantId.isEmpty) return;

    try {
      final dueAt = DateTime(
        _selectedNoteDate.year,
        _selectedNoteDate.month,
        _selectedNoteDate.day,
        _selectedNoteTime.hour,
        _selectedNoteTime.minute,
      );
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/schedules'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plant_id': plantId,
          'task_type': 'note',
          'note': note,
          'next_due_at': dueAt.toUtc().toIso8601String(),
          'frequency_days': 0,
        }),
      );

      if (!mounted) return;
      if (response.statusCode != 200 && response.statusCode != 201) {
        _showSnackBar(
          'Đã lưu ghi chú nhưng chưa tạo được lịch chăm sóc',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Đã lưu ghi chú nhưng chưa kết nối được lịch chăm sóc',
        isError: true,
      );
    }
  }

  Future<void> _pickNoteDate() async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNoteDatePickerSheet(
        initialDate: _selectedNoteDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );

    if (pickedDate == null || !mounted) return;
    setState(() => _selectedNoteDate = DateUtils.dateOnly(pickedDate));
  }

  Future<void> _pickNoteTime() async {
    final pickedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildNoteTimePickerSheet(_selectedNoteTime),
    );

    if (pickedTime == null || !mounted) return;
    setState(() => _selectedNoteTime = pickedTime);
  }

  void _resetNoteForm({bool hideForm = true, bool showForm = false}) {
    final now = DateTime.now();
    _noteController.clear();
    setState(() {
      _selectedNoteDate = _today;
      _selectedNoteTime = TimeOfDay.fromDateTime(now);
      if (showForm) {
        _showNoteForm = true;
      } else if (hideForm) {
        _showNoteForm = false;
      }
    });
  }

  void _applyCareUpdate({
    required Map<String, dynamic> updates,
    required Map<String, dynamic> log,
    required String message,
  }) {
    setState(() {
      final logs = _careLogsOf(_plantData);
      _plantData = Map<String, dynamic>.from(_plantData)
        ..addAll(updates)
        ..['isInGarden'] = true
        ..['careLogs'] = [log, ...logs];
    });

    widget.onCareUpdated?.call(Map<String, dynamic>.from(_plantData));
    _showSnackBar(message);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = _isGardenPlant ? 28.0 : 110.0;

    return Scaffold(
      backgroundColor: _softBackground,
      appBar: AppBar(
        title: Text(
          _plantName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: _isGardenPlant ? null : _buildBottomAddToGardenBar(),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
        children: [
          _buildPlantHero(),
          const SizedBox(height: 14),
          _buildQuickInfoCard(),
          const SizedBox(height: 14),
          _buildCareStatusCard(),
          const SizedBox(height: 14),
          _buildCareActionButtons(),
          const SizedBox(height: 14),
          _buildCareScheduleCard(),
          const SizedBox(height: 14),
          _buildIntroductionCard(),
          if (_hasLivingConditionData()) ...[
            const SizedBox(height: 14),
            _buildCard(
              'Điều kiện sống',
              Icons.wb_sunny_outlined,
              [
                _line('Ánh sáng', 'light'),
                _line('Nước', 'water'),
                _line('Nhiệt độ', 'temp'),
                _line('Độ khó', 'difficulty'),
              ].join('\n'),
            ),
          ],
          if (_hasSoilData()) ...[
            const SizedBox(height: 14),
            _buildCard(
              'Đất & Phân bón',
              Icons.landscape_outlined,
              [
                _line('Đất', 'soil'),
                _line('Phân bón', 'fertilizer'),
              ].join('\n'),
            ),
          ],
          if (_hasCareTipData()) ...[
            const SizedBox(height: 14),
            _buildCard(
              'Chăm sóc & Cắt tỉa',
              Icons.content_cut,
              [
                _line('Cắt tỉa', 'pruning'),
                _line('Chăm sóc', 'care_tips'),
              ].join('\n'),
            ),
          ],
          if (_hasPropagationData()) ...[
            const SizedBox(height: 14),
            _buildCard(
              'Nhân giống & Mùa vụ',
              Icons.spa_outlined,
              [
                _line('Nhân giống', 'propagation'),
                _line('Mùa trồng', 'planting_time'),
                _line('Chịu đựng', 'hardiness'),
              ].join('\n'),
            ),
          ],
          const SizedBox(height: 14),
          _buildPestPreventionCard(),
          const SizedBox(height: 14),
          _buildCareLogCard(),
        ],
      ),
    );
  }

  Widget _buildBottomAddToGardenBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveToGarden,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_circle_outline_rounded),
            label: Text(_isSaving ? 'Đang lưu...' : 'Thêm vào Vườn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 204,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeaderImage(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black45, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _plantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ),
                  if (_isGardenPlant) _buildHeroGardenBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    final imageUrl = _resolvedImageUrl(widget.imagePath);
    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.green.shade100,
        child: const Icon(
          Icons.local_florist_rounded,
          color: _primaryGreen,
          size: 72,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.green.shade100,
        child: const Icon(
          Icons.broken_image_outlined,
          color: _primaryGreen,
          size: 56,
        ),
      ),
    );
  }

  Widget _buildHeroGardenBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Đã có',
        style: TextStyle(
          color: _primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildQuickInfoCard() {
    final scientificName = _value('scientific_name', fallback: 'Chưa rõ');
    final family = _value('family', fallback: 'Chưa rõ');
    final genus = _value('genus', fallback: 'Chưa rõ');
    final description = _value(
      'description',
      fallback: 'Chưa có mô tả ngắn cho cây này.',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plantName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildDifficultyChip(),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(Icons.family_restroom_outlined, 'Họ: $family'),
              _buildInfoChip(Icons.eco_outlined, 'Chi: $genus'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip() {
    final difficulty = _value('difficulty', fallback: 'Đang cập nhật');
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        difficulty,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primaryGreen),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareStatusCard() {
    final health =
        _stringValue(_plantData['healthStatus'], fallback: 'healthy');
    final status = _careStatus();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Trạng thái chăm sóc',
            Icons.health_and_safety_outlined,
            trailing: _buildStatusBadge(
              _careStatusLabel(status),
              _careStatusColor(status),
            ),
          ),
          const Divider(height: 24),
          _buildCareMetric(
            Icons.check_circle_outline_rounded,
            'Tình trạng sức khỏe',
            _healthStatusLabel(health),
            _healthStatusColor(health),
          ),
          const SizedBox(height: 10),
          _buildCareMetric(
            Icons.water_drop_outlined,
            'Tưới nước',
            _dueLabel(
              dueTodayLabel: 'Cần tưới hôm nay',
              futurePrefix: 'Tưới sau',
              date: _parseDate(_plantData['nextWateringDate']),
            ),
            _careStatusColor(status == 'need_water' ? status : 'normal'),
          ),
          const SizedBox(height: 10),
          _buildCareMetric(
            Icons.eco_outlined,
            'Bón phân',
            _dueLabel(
              dueTodayLabel: 'Sắp bón phân',
              futurePrefix: 'Bón phân sau',
              date: _parseDate(_plantData['nextFertilizingDate']),
            ),
            status == 'fertilize_soon'
                ? _careStatusColor(status)
                : _primaryGreen,
          ),
          const SizedBox(height: 10),
          _buildCareMetric(
            Icons.speed_outlined,
            'Độ khó chăm sóc',
            _value('difficulty', fallback: 'Đang cập nhật'),
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildCareMetric(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _darkText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCareActionButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Hành động nhanh', Icons.flash_on_outlined),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markWateredToday,
                  icon: const Icon(Icons.water_drop_rounded, size: 18),
                  label: const Text('Đã tưới'),
                  style: _primaryButtonStyle(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _markFertilized,
                  icon: const Icon(Icons.eco_rounded, size: 18),
                  label: const Text('Đã bón phân'),
                  style: _outlineButtonStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                if (_showNoteForm) {
                  _resetNoteForm();
                } else {
                  _resetNoteForm(hideForm: false, showForm: true);
                }
              },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Thêm ghi chú'),
              style: TextButton.styleFrom(
                foregroundColor: _primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_showNoteForm) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú chăm sóc...',
                filled: true,
                fillColor: const Color(0xFFF8FAF8),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildNoteDateTimeButton(
                    icon: Icons.calendar_today_outlined,
                    label: _formatDate(_selectedNoteDate),
                    onPressed: _pickNoteDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildNoteDateTimeButton(
                    icon: Icons.schedule_outlined,
                    label: _formatTime(_selectedNoteTime),
                    onPressed: _pickNoteTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetNoteForm,
                    style: _outlineButtonStyle(),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addNote,
                    style: _primaryButtonStyle(),
                    child: const Text('Lưu ghi chú'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteDateTimeButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkText,
        backgroundColor: const Color(0xFFF8FAF8),
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildNoteDatePickerSheet({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return NoteDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      primaryColor: _primaryGreen,
      darkText: _darkText,
    );
  }

  Widget _buildNoteTimePickerSheet(TimeOfDay initialTime) {
    return NoteTimePickerSheet(
      initialTime: initialTime,
      primaryColor: _primaryGreen,
      darkText: _darkText,
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _primaryGreen,
      side: const BorderSide(color: _primaryGreen),
      padding: const EdgeInsets.symmetric(vertical: 12),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildCareScheduleCard() {
    final wateringInterval =
        _intValue(_plantData['wateringIntervalDays'], fallback: 2);
    final fertilizingInterval =
        _intValue(_plantData['fertilizingIntervalDays'], fallback: 30);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Lịch chăm sóc đề xuất', Icons.event_note_outlined),
          const Divider(height: 24),
          _buildScheduleRow(
            Icons.water_drop_outlined,
            'Tưới nước',
            '$wateringInterval ngày/lần',
            Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildScheduleRow(
            Icons.eco_outlined,
            'Bón phân',
            '$fertilizingInterval ngày/lần',
            _primaryGreen,
          ),
          const SizedBox(height: 10),
          _buildScheduleRow(
            Icons.content_cut,
            'Cắt tỉa',
            _value('pruningSchedule', fallback: _defaultPruningSchedule()),
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 10),
          _buildScheduleRow(
            Icons.search_rounded,
            'Kiểm tra sâu bệnh',
            _value('pestCheckSchedule', fallback: 'Mỗi tuần'),
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: _darkText,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntroductionCard() {
    return _buildCard(
      'Giới thiệu',
      Icons.info_outline,
      [
        _line('Tên khoa học', 'scientific_name'),
        _line('Họ', 'family'),
        _line('Chi', 'genus'),
        if (_hasData('description')) _value('description'),
      ].join('\n'),
    );
  }

  Widget _buildPestPreventionCard() {
    final pests = _pestProfile();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(color: Colors.orange.shade50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Phòng ngừa sâu bệnh', Icons.bug_report_outlined),
          const Divider(height: 24),
          _buildBulletGroup('Sâu bệnh thường gặp', pests.common),
          const SizedBox(height: 12),
          _buildBulletGroup('Dấu hiệu nhận biết', pests.symptoms),
          const SizedBox(height: 12),
          _buildBulletGroup('Cách xử lý', pests.treatment),
          const SizedBox(height: 12),
          _buildBulletGroup('Phòng ngừa', pests.prevention),
        ],
      ),
    );
  }

  Widget _buildBulletGroup(String title, List<String> items) {
    final cleanItems = items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != 'null')
        .toList();
    if (cleanItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 6),
        ...cleanItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareLogCard() {
    final logs = _careLogsOf(_plantData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Nhật ký chăm sóc', Icons.history_rounded),
          const Divider(height: 24),
          if (logs.isEmpty)
            Text(
              'Chưa có hoạt động chăm sóc nào.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...logs.map(_buildCareLogItem),
        ],
      ),
    );
  }

  Widget _buildCareLogItem(Map<String, dynamic> log) {
    final type = _stringValue(log['type'], fallback: 'note');
    final date = _parseDate(log['date']);
    final time = _parseTime(log['time']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _logColor(type).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_logIcon(type), color: _logColor(type), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _stringValue(log['note'], fallback: 'Cập nhật chăm sóc'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _darkText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatLogDateTime(date, time),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
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

  Widget _buildCard(
    String title,
    IconData icon,
    String content, {
    Color color = Colors.white,
  }) {
    final cleanContent =
        content.split('\n').map((line) => line.trim()).where((line) {
      if (line.isEmpty) return false;
      if (line.endsWith(':')) return false;
      if (line.endsWith(': null')) return false;
      if (line.toLowerCase().contains(': null')) return false;
      return true;
    }).join('\n');

    if (cleanContent.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(title, icon),
          const Divider(height: 24),
          Text(
            cleanContent,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(
    String title,
    IconData icon, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _primaryGreen, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _darkText,
              height: 1.2,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _careLogsOf(Map<String, dynamic> plant) {
    final rawLogs =
        plant['careLogs'] ?? plant['care_logs'] ?? plant['histories'];
    if (rawLogs is! List) return [];

    return rawLogs.whereType<Map>().map((log) {
      final item = Map<String, dynamic>.from(log);
      final rawType = item['type'] ?? item['task_type'];
      final type = _stringValue(rawType, fallback: 'note');
      final date = _parseDate(item['date'] ?? item['created_at']) ?? _today;
      final time = _parseTime(item['time']) ?? _parseTime(item['created_at']);
      final note = _stringValue(
        item['note'] ?? item['action'],
        fallback: _defaultLogNote(type),
      );

      return {
        'id': _stringValue(
          item['id'],
          fallback: 'log-${date.millisecondsSinceEpoch}',
        ),
        'date': _dateToIso(date),
        if (time != null) 'time': _timeToText(time),
        'type': type,
        'note': note,
      };
    }).toList()
      ..sort((a, b) {
        final dateCompare =
            b['date'].toString().compareTo(a['date'].toString());
        if (dateCompare != 0) return dateCompare;
        final aTime = a['time']?.toString() ?? '';
        final bTime = b['time']?.toString() ?? '';
        return bTime.compareTo(aTime);
      });
  }

  Map<String, dynamic> _createCareLog({
    required String type,
    required String note,
    DateTime? date,
    TimeOfDay? time,
  }) {
    final logDate = date ?? _today;
    return {
      'id': 'log-${DateTime.now().microsecondsSinceEpoch}',
      'date': _dateToIso(logDate),
      if (time != null) 'time': _timeToText(time),
      'type': type,
      'note': note,
    };
  }

  _PestProfile _pestProfile() {
    final raw = _plantData['pests'];
    if (raw is Map) {
      return _PestProfile(
        common: _stringList(raw['common']),
        symptoms: _stringList(raw['symptoms']),
        treatment: _stringList(raw['treatment']),
        prevention: _stringList(raw['prevention']),
      ).withDefaults(_defaultPestProfile());
    }

    final common = _splitListText(_stringValue(raw));
    return _PestProfile(
      common: common.isEmpty ? _defaultCommonPests() : common,
      symptoms: const [
        'Lá bị xoăn, héo hoặc biến dạng bất thường',
        'Lá có đốm vàng, vệt nâu hoặc mặt dưới lá có chấm nhỏ',
        'Hoa kém phát triển, nụ rụng sớm hoặc cây chậm lớn',
      ],
      treatment: const [
        'Cắt bỏ lá, cành hoặc hoa đã bị hại nặng',
        'Kiểm tra kỹ mặt dưới lá và các kẽ cành trước khi xử lý',
        'Dùng dung dịch sinh học hoặc phương pháp an toàn theo đúng liều',
      ],
      prevention: const [
        'Giữ tán cây thông thoáng và dọn lá rụng quanh gốc',
        'Tránh tưới quá nhiều làm đất bí và rễ yếu',
        'Kiểm tra cây định kỳ mỗi tuần, nhất là sau mưa hoặc nắng gắt',
      ],
    );
  }

  _PestProfile _defaultPestProfile() {
    return _PestProfile(
      common: _defaultCommonPests(),
      symptoms: const [
        'Lá bị xoăn hoặc xuất hiện đốm vàng',
        'Đọt non yếu, hoa hoặc nụ kém phát triển',
        'Có mảng trắng, chấm nhỏ hoặc vết cắn trên lá',
      ],
      treatment: const [
        'Cắt bỏ phần bị hại và tiêu hủy xa khu vực trồng',
        'Kiểm tra mặt dưới lá, kẽ cành và vùng gốc',
        'Ưu tiên dung dịch sinh học, dầu neem hoặc biện pháp an toàn',
      ],
      prevention: const [
        'Giữ cây thông thoáng, đủ sáng và không quá ẩm',
        'Không tưới trực tiếp lên hoa vào chiều tối',
        'Theo dõi cây mỗi tuần để xử lý sớm khi có dấu hiệu lạ',
      ],
    );
  }

  List<String> _defaultCommonPests() {
    final name = _plantName.toLowerCase();
    if (name.contains('mai')) {
      return const ['Sâu ăn lá', 'Bọ trĩ', 'Rệp sáp'];
    }
    if (name.contains('hồng') || name.contains('hong')) {
      return const ['Bọ trĩ', 'Nhện đỏ', 'Rệp sáp'];
    }
    return const ['Sâu ăn lá', 'Bọ trĩ', 'Rệp sáp'];
  }

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
    }
    return _splitListText(_stringValue(value));
  }

  List<String> _splitListText(String value) {
    if (value.trim().isEmpty) return [];
    return value
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty && item != 'null')
        .toList();
  }

  String _defaultLogNote(String type) {
    switch (type) {
      case 'water':
      case 'watering':
        return 'Đã tưới nước';
      case 'fertilize':
      case 'fertilizing':
        return 'Đã bón phân';
      default:
        return 'Cập nhật chăm sóc';
    }
  }

  String _careStatus() {
    final wateringDate = _parseDate(_plantData['nextWateringDate']);
    final fertilizingDate = _parseDate(_plantData['nextFertilizingDate']);
    if (wateringDate != null && !wateringDate.isAfter(_today)) {
      return 'need_water';
    }
    if (fertilizingDate != null && _daysUntil(fertilizingDate) <= 3) {
      return 'fertilize_soon';
    }

    final explicitStatus = _stringValue(
      _plantData['careStatus'] ?? _plantData['care_status'],
    );
    if (explicitStatus == 'need_water' ||
        explicitStatus == 'fertilize_soon' ||
        explicitStatus == 'normal') {
      return explicitStatus;
    }
    return 'normal';
  }

  String _careStatusLabel(String status) {
    switch (status) {
      case 'need_water':
        return 'Cần tưới hôm nay';
      case 'fertilize_soon':
        return 'Sắp bón phân';
      case 'normal':
      default:
        return 'Đang ổn';
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
        return 'Cần chú ý';
      case 'danger':
        return 'Có vấn đề';
      case 'healthy':
      default:
        return 'Khỏe mạnh';
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

  IconData _logIcon(String type) {
    switch (type) {
      case 'water':
      case 'watering':
        return Icons.water_drop_rounded;
      case 'fertilize':
      case 'fertilizing':
        return Icons.eco_rounded;
      default:
        return Icons.sticky_note_2_outlined;
    }
  }

  Color _logColor(String type) {
    switch (type) {
      case 'water':
      case 'watering':
        return Colors.blue;
      case 'fertilize':
      case 'fertilizing':
        return _primaryGreen;
      default:
        return Colors.orange;
    }
  }

  String _dueLabel({
    required String dueTodayLabel,
    required String futurePrefix,
    required DateTime? date,
  }) {
    if (date == null) return 'Chưa lên lịch';

    final days = _daysUntil(date);
    if (days <= 0) return dueTodayLabel;
    if (days == 1) return '$futurePrefix 1 ngày';
    return '$futurePrefix $days ngày';
  }

  int _daysUntil(DateTime date) {
    return DateUtils.dateOnly(date).difference(_today).inDays;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) => _timeToText(time);

  String _formatLogDateTime(DateTime? date, TimeOfDay? time) {
    final dateLabel = date == null ? 'Hôm nay' : _formatDate(date);
    if (time == null) return dateLabel;
    return '$dateLabel lúc ${_formatTime(time)}';
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

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    if (value is TimeOfDay) return value;
    if (value is DateTime) return TimeOfDay.fromDateTime(value.toLocal());

    final raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;

    final parsedDate = DateTime.tryParse(raw);
    if (parsedDate != null &&
        (raw.contains('T') || raw.contains(RegExp(r'\s')))) {
      return TimeOfDay.fromDateTime(parsedDate.toLocal());
    }

    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeToText(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateToIso(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _resolvedImageUrl(String rawPath) {
    final rawImage = rawPath.trim();
    if (rawImage.isEmpty || rawImage == 'null') return '';
    if (rawImage.startsWith('http')) return Config.getImageUrl(rawImage);

    final baseUrl = Config.apiUrl.replaceAll('/api', '');
    final normalizedPath = rawImage.startsWith('/') ? rawImage : '/$rawImage';
    return '$baseUrl$normalizedPath';
  }

  bool _hasLivingConditionData() {
    return _hasData('light') ||
        _hasData('water') ||
        _hasData('temp') ||
        _hasData('difficulty');
  }

  bool _hasSoilData() {
    return _hasData('soil') || _hasData('fertilizer');
  }

  bool _hasCareTipData() {
    return _hasData('care_tips') || _hasData('pruning');
  }

  bool _hasPropagationData() {
    return _hasData('propagation') ||
        _hasData('planting_time') ||
        _hasData('hardiness');
  }

  String _line(String label, String key) {
    final value = _value(key);
    return value.isEmpty ? '' : '$label: $value';
  }

  bool _hasData(String key) {
    final value = _value(key);
    return value.isNotEmpty && value != 'null';
  }

  String _value(String key, {String fallback = ''}) {
    return _stringValue(_plantData[key], fallback: fallback);
  }

  int _suggestWateringInterval() {
    final name = _plantName.toLowerCase();
    final water = _value('water').toLowerCase();
    if (name.contains('sen') || water.contains('giữ ẩm')) return 1;
    if (name.contains('mai')) return 2;
    if (water.contains('ít') || water.contains('khô')) return 5;
    return 3;
  }

  int _suggestFertilizingInterval() {
    final name = _plantName.toLowerCase();
    if (name.contains('hồng') || name.contains('hong')) return 14;
    if (name.contains('mai')) return 30;
    return 30;
  }

  String _defaultPruningSchedule() {
    final name = _plantName.toLowerCase();
    if (name.contains('mai')) return 'Sau Tết';
    if (_hasData('pruning')) return _value('pruning');
    return 'Sau khi hoa tàn hoặc khi cành mọc dày';
  }

  String _defaultHealthStatus() {
    final status = _stringValue(_plantData['careStatus']);
    if (status == 'need_water') return 'warning';
    return 'healthy';
  }

  int _intValue(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }
}

class NoteDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primaryColor;
  final Color darkText;

  const NoteDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.primaryColor,
    required this.darkText,
  });

  @override
  State<NoteDatePickerSheet> createState() => NoteDatePickerSheetState();
}

class NoteDatePickerSheetState extends State<NoteDatePickerSheet> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  DateTime get _firstDate => DateUtils.dateOnly(widget.firstDate);
  DateTime get _lastDate => DateUtils.dateOnly(widget.lastDate);
  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate);
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: widget.primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn ngày ghi chú',
                      style: TextStyle(
                        color: widget.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gắn ngày cho hoạt động chăm sóc',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isDateEnabled(_today)
                    ? () {
                        setState(() {
                          _selectedDate = _today;
                          _visibleMonth = DateTime(_today.year, _today.month);
                        });
                      }
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: widget.primaryColor,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Hôm nay'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.primaryColor.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weekdayLabel(_selectedDate.weekday),
                        style: TextStyle(
                          color: widget.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatFullDate(_selectedDate),
                        style: TextStyle(
                          color: widget.darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: widget.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _monthTitle(_visibleMonth),
                  style: TextStyle(
                    color: widget.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildMonthButton(
                icon: Icons.chevron_left_rounded,
                enabled: _canGoToPreviousMonth,
                onPressed: () => _goToMonth(-1),
              ),
              const SizedBox(width: 6),
              _buildMonthButton(
                icon: Icons.chevron_right_rounded,
                enabled: _canGoToNextMonth,
                onPressed: () => _goToMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _WeekdayCell('T2'),
              _WeekdayCell('T3'),
              _WeekdayCell('T4'),
              _WeekdayCell('T5'),
              _WeekdayCell('T6'),
              _WeekdayCell('T7'),
              _WeekdayCell('CN'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) => _buildDateCell(index),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.primaryColor,
                    side: BorderSide(color: widget.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Chọn ngày'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canGoToPreviousMonth {
    final previousMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    final previousMonthLastDay = DateTime(
      previousMonth.year,
      previousMonth.month + 1,
      0,
    );
    return !DateUtils.dateOnly(previousMonthLastDay).isBefore(_firstDate);
  }

  bool get _canGoToNextMonth {
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    return !DateUtils.dateOnly(nextMonth).isAfter(_lastDate);
  }

  void _goToMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  Widget _buildMonthButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? widget.primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled ? widget.primaryColor : Colors.grey.shade400,
          size: 23,
        ),
      ),
    );
  }

  Widget _buildDateCell(int index) {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final firstWeekdayOffset = firstOfMonth.weekday - DateTime.monday;
    final day = index - firstWeekdayOffset + 1;
    final daysInMonth = DateUtils.getDaysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );

    if (day < 1 || day > daysInMonth) {
      return const SizedBox.shrink();
    }

    final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
    final isSelected = _isSameDate(date, _selectedDate);
    final isToday = _isSameDate(date, _today);
    final enabled = _isDateEnabled(date);

    return InkWell(
      onTap: enabled
          ? () => setState(() => _selectedDate = DateUtils.dateOnly(date))
          : null,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? widget.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? widget.primaryColor
                : isToday
                    ? widget.primaryColor.withValues(alpha: 0.55)
                    : Colors.transparent,
          ),
        ),
        child: Text(
          '$day',
          style: TextStyle(
            color: !enabled
                ? Colors.grey.shade300
                : isSelected
                    ? Colors.white
                    : widget.darkText,
            fontSize: 14,
            fontWeight:
                isSelected || isToday ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  bool _isDateEnabled(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return !normalized.isBefore(_firstDate) && !normalized.isAfter(_lastDate);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _monthTitle(DateTime date) => 'Tháng ${date.month}, ${date.year}';

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ hai';
      case DateTime.tuesday:
        return 'Thứ ba';
      case DateTime.wednesday:
        return 'Thứ tư';
      case DateTime.thursday:
        return 'Thứ năm';
      case DateTime.friday:
        return 'Thứ sáu';
      case DateTime.saturday:
        return 'Thứ bảy';
      default:
        return 'Chủ nhật';
    }
  }
}

class _WeekdayCell extends StatelessWidget {
  final String label;

  const _WeekdayCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class NoteTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final Color primaryColor;
  final Color darkText;

  const NoteTimePickerSheet({
    required this.initialTime,
    required this.primaryColor,
    required this.darkText,
  });

  @override
  State<NoteTimePickerSheet> createState() => NoteTimePickerSheetState();
}

class NoteTimePickerSheetState extends State<NoteTimePickerSheet> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: widget.primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn giờ ghi chú',
                      style: TextStyle(
                        color: widget.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Đặt thời điểm chăm sóc cây',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.primaryColor.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimePreviewBox(_hour),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildTimePreviewBox(_minute),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildWheel(
                  label: 'Giờ',
                  controller: _hourController,
                  count: 24,
                  selectedValue: _hour,
                  onChanged: (value) => setState(() => _hour = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWheel(
                  label: 'Phút',
                  controller: _minuteController,
                  count: 60,
                  selectedValue: _minute,
                  onChanged: (value) => setState(() => _minute = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickTimeChip('Sáng', 7, 0),
              _buildQuickTimeChip('Trưa', 12, 0),
              _buildQuickTimeChip('Chiều', 16, 30),
              _buildQuickTimeChip('Tối', 19, 0),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.primaryColor,
                    side: BorderSide(color: widget.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TimeOfDay(hour: _hour, minute: _minute),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text('Chọn giờ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreviewBox(int value) {
    return Container(
      width: 74,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: TextStyle(
          color: widget.darkText,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildWheel({
    required String label,
    required FixedExtentScrollController controller,
    required int count,
    required int selectedValue,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: 42,
              magnification: 1.08,
              useMagnifier: true,
              selectionOverlay: Center(
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ),
              onSelectedItemChanged: onChanged,
              children: List.generate(count, (index) {
                final isSelected = index == selectedValue;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: isSelected ? widget.primaryColor : widget.darkText,
                      fontSize: isSelected ? 23 : 19,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimeChip(String label, int hour, int minute) {
    final isSelected = _hour == hour && _minute == minute;
    return InkWell(
      onTap: () {
        _hourController.animateToItem(
          hour,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
        _minuteController.animateToItem(
          minute,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
        setState(() {
          _hour = hour;
          _minute = minute;
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.primaryColor
              : widget.primaryColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.primaryColor.withValues(alpha: isSelected ? 1 : 0.16),
          ),
        ),
        child: Text(
          '$label ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: isSelected ? Colors.white : widget.primaryColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PestProfile {
  final List<String> common;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;

  const _PestProfile({
    required this.common,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
  });

  _PestProfile withDefaults(_PestProfile defaults) {
    return _PestProfile(
      common: common.isEmpty ? defaults.common : common,
      symptoms: symptoms.isEmpty ? defaults.symptoms : symptoms,
      treatment: treatment.isEmpty ? defaults.treatment : treatment,
      prevention: prevention.isEmpty ? defaults.prevention : prevention,
    );
  }
}
