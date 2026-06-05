import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:cham_soc_cay_trong/config.dart';
import 'package:cham_soc_cay_trong/custom_dialog.dart';
import 'package:cham_soc_cay_trong/library_detail_screen.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/top_toast_util.dart';
import 'package:cham_soc_cay_trong/local_notification_util.dart';

enum CareTaskType {
  watering,
  fertilizing,
  pruning,
  spraying,
  repotting,
  note,
}

class CareScheduleScreen extends StatefulWidget {
  const CareScheduleScreen({super.key});

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen> {
  static const Color _primaryGreen = Color(0xFF25BB57);
  static const Color _darkText = Color(0xFF202124);

  bool _isLoading = true;
  List _todayTasks = [];
  List _upcomingTasks = [];

  Timer? _notificationTimer;
  final Set<int> _notifiedTaskIds = {};
  final Map<int, DateTime> _taskDueDates = {};
  late DateTime _screenOpenedTime;

  @override
  void initState() {
    super.initState();
    _screenOpenedTime = DateTime.now();
    LocalNotificationUtil.initialize().then((_) {
      if (mounted) {
        _checkAndShowNotifications();
      }
    });
    _fetchSchedules();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _checkAndShowNotifications();
    });
  }

  void _checkAndShowNotifications() {
    if (!mounted) return;
    final now = DateTime.now();
    final allTasks = [..._todayTasks, ..._upcomingTasks];

    for (var task in allTasks) {
      final id = task['id'];
      if (id == null) continue;

      final dueDate = _parseTaskDate(task['next_due_at']);
      if (dueDate == null) continue;

      // Nếu lịch hẹn bị thay đổi thời gian, reset trạng thái đã thông báo
      if (_taskDueDates[id] != dueDate) {
        _taskDueDates[id] = dueDate;
        _notifiedTaskIds.remove(id);
      }

      if (_notifiedTaskIds.contains(id)) continue;

      // Chỉ hiển thị thông báo nếu lịch hẹn nằm trong phạm vi hiển thị
      // (Bắt đầu từ 1 phút trước khi mở trang đến hiện tại)
      final isRelevantTime = dueDate.isAfter(_screenOpenedTime.subtract(const Duration(minutes: 1)));
      final isDue = now.isAfter(dueDate) || now.isAtSameMomentAs(dueDate);

      if (isRelevantTime && isDue) {
        _notifiedTaskIds.add(id);

        String type = (task['task_type'] ?? '').toString();
        String plantName = task['plant']?['name'] ?? 'Cây không tên';
        String translatedTask = _translateTask(type);

        TopToast.show(
          context,
          'Đến giờ: $translatedTask cho $plantName!',
          backgroundColor: _getColor(type),
          icon: _getIcon(type),
          duration: const Duration(seconds: 6),
        );

        LocalNotificationUtil.showNotification(
          id: id,
          title: 'Lịch chăm sóc cây',
          body: 'Đến giờ: $translatedTask cho $plantName!',
        );
      }
    }
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${Config.apiUrl}/schedules');
      final response = await http.get(url, headers: Config.apiHeaders);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (mounted) {
          setState(() {
            _todayTasks = jsonResponse['data']['today'] ?? [];
            _upcomingTasks = jsonResponse['data']['upcoming'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask(int id) async {
    try {
      final url = Uri.parse('${Config.apiUrl}/schedules/$id/complete');
      final response = await http.post(url, headers: Config.apiHeaders);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('careSchedule.completed')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
            ),
          );
          _fetchSchedules(); // Tải lại danh sách
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'careSchedule.error',
                params: <String, String>{'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
          ),
        );
      }
    }
  }

  Future<void> _editTask(dynamic task) async {
    DateTime? currentDate = _parseTaskDate(task['next_due_at']);
    if (currentDate == null) return;

    final firstDate = DateTime.now().subtract(const Duration(days: 365));
    final lastDate = DateTime.now().add(const Duration(days: 365 * 5));
    final pickedDateTime = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EditNoteDateTimeSheet(
        initialDateTime: currentDate,
        firstDate: firstDate,
        lastDate: lastDate,
        primaryColor: _primaryGreen,
        darkText: _darkText,
        plantName: task['plant']?['name'] ?? 'Cây không tên',
        note: _careTaskNote(task, CareTaskType.note),
      ),
    );
    if (pickedDateTime == null) return;

    try {
      final url = Uri.parse('${Config.apiUrl}/schedules/${task['id']}');
      final response = await http.put(
        url,
        headers: Config.jsonHeaders,
        body: jsonEncode({
          'next_due_at': pickedDateTime.toUtc().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật thời gian ghi chú'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
            ),
          );
          _fetchSchedules();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi cập nhật'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(int id) async {
    final bool confirm = await PremiumDialog.showPremiumConfirmDialog(
      context: context,
      title: 'Xác nhận xoá',
      message: 'Bạn có chắc chắn muốn xoá ghi chú này không?',
      confirmText: 'Xoá',
      cancelText: 'Huỷ',
      isDanger: true,
    );

    if (confirm != true) return;

    try {
      final url = Uri.parse('${Config.apiUrl}/schedules/$id');
      final response = await http.delete(url, headers: Config.apiHeaders);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xoá ghi chú'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
            ),
          );
          _fetchSchedules();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi xoá ghi chú'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 90, left: 16, right: 16),
          ),
        );
      }
    }
  }

  CareTaskType? _parseTaskType(String task) {
    switch (task) {
      case 'water':
      case 'watering':
      case 'mist':
        return CareTaskType.watering;
      case 'fertilize':
      case 'fertilizing':
        return CareTaskType.fertilizing;
      case 'prune':
      case 'pruning':
        return CareTaskType.pruning;
      case 'spray':
      case 'spraying':
        return CareTaskType.spraying;
      case 'repot':
      case 'repotting':
        return CareTaskType.repotting;
      case 'note':
      case 'reminder':
        return CareTaskType.note;
    }
    return null;
  }

  String _translateTask(String task) {
    if (task == 'water') return 'Tưới nước';
    if (task == 'watering') return 'Tưới nước';
    if (task == 'mist') return 'Tưới phun sương';
    if (task == 'fertilize') return 'Bón phân';
    if (task == 'fertilizing') return 'Bón phân';
    if (task == 'prune') return 'Cắt tỉa';
    if (task == 'pruning') return 'Cắt tỉa';
    if (task == 'spray') return 'Phun thuốc';
    if (task == 'spraying') return 'Phun thuốc';
    if (task == 'repot') return 'Thay đất';
    if (task == 'repotting') return 'Thay đất';
    if (task == 'note') return 'Ghi chú';
    if (task == 'reminder') return 'Nhắc việc';
    return task;
  }

  IconData _getIcon(String task) {
    CareTaskType? type = _parseTaskType(task);
    if (type == CareTaskType.watering) return Icons.water_drop_outlined;
    if (type == CareTaskType.fertilizing) return Icons.eco_outlined;
    if (type == CareTaskType.pruning) return Icons.content_cut;
    if (type == CareTaskType.spraying) return Icons.bug_report_outlined;
    if (type == CareTaskType.repotting) return Icons.local_florist_outlined;
    if (type == CareTaskType.note) return Icons.sticky_note_2_outlined;
    return Icons.check_circle_outline;
  }

  Color _getColor(String task) {
    CareTaskType? type = _parseTaskType(task);
    if (type == CareTaskType.watering) return Colors.blue;
    if (type == CareTaskType.fertilizing) return Colors.green;
    if (type == CareTaskType.pruning) return Colors.orange;
    if (type == CareTaskType.spraying) return Colors.purple;
    if (type == CareTaskType.repotting) return Colors.brown;
    if (type == CareTaskType.note) return Colors.teal;
    return Colors.grey;
  }

  DateTime? _parseTaskDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  bool _isRecommendedWateringTime(TimeOfDay time) {
    int minutes = time.hour * 60 + time.minute;
    int morningStart = 6 * 60;
    int morningEnd = 8 * 60;
    int afternoonStart = 16 * 60 + 30;
    int afternoonEnd = 18 * 60;

    return (minutes >= morningStart && minutes <= morningEnd) ||
        (minutes >= afternoonStart && minutes <= afternoonEnd);
  }

  TimeOfDay _wateringDisplayTime(DateTime date) {
    TimeOfDay storedTime = TimeOfDay.fromDateTime(date);
    if (_isRecommendedWateringTime(storedTime)) return storedTime;
    return const TimeOfDay(hour: 6, minute: 30);
  }

  String _formatTimeOfDay(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: false,
    );
  }

  String _formatCareTaskTimeLabel(
    BuildContext context,
    CareTaskType? type,
    DateTime? date,
  ) {
    if (date == null) return '';

    final dateText = _formatDate(date);

    switch (type) {
      case CareTaskType.watering:
        final timeText = _formatTimeOfDay(context, _wateringDisplayTime(date));
        final isToday = DateUtils.isSameDay(date, DateTime.now());
        return isToday ? 'Hôm nay, $timeText' : '$timeText - $dateText';
      case CareTaskType.fertilizing:
        return 'Sáng sớm hoặc chiều mát - $dateText';
      case CareTaskType.pruning:
        return 'Trong ngày - $dateText';
      case CareTaskType.spraying:
        return 'Chiều mát, ít gió - $dateText';
      case CareTaskType.repotting:
        return 'Trong ngày - $dateText';
      case CareTaskType.note:
        return '${_formatTimeOfDay(context, TimeOfDay.fromDateTime(date))} - $dateText';
      case null:
        return dateText;
    }
  }

  String? _careTaskNote(dynamic task, CareTaskType? type) {
    final note = task['note'];
    if (note is String && note.trim().isNotEmpty) return note.trim();

    switch (type) {
      case CareTaskType.fertilizing:
        return 'Tránh bón khi nắng gắt hoặc đất quá khô';
      case CareTaskType.pruning:
        return 'Nên cắt tỉa khi cây khô ráo';
      case CareTaskType.spraying:
        return 'Tránh phun khi trời nắng gắt hoặc có gió mạnh';
      default:
        return null;
    }
  }

  Widget? _buildTrailing(
      dynamic task, CareTaskType? careTaskType, bool isToday) {
    if (careTaskType == CareTaskType.note) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isToday)
            InkWell(
              onTap: () => _completeTask(task['id']),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.green),
              ),
            ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') {
                _editTask(task);
              } else if (value == 'delete') {
                _deleteTask(task['id']);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_calendar, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Chỉnh sửa ngày giờ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Xoá ghi chú', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.grey),
          ),
        ],
      );
    }

    if (isToday) {
      return InkWell(
        onTap: () => _completeTask(task['id']),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Icon(Icons.check, size: 20, color: Colors.green),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        title: Text(context.tr('careSchedule.title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  context.tr('careSchedule.todayTasks'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (_todayTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(context.tr('careSchedule.noTodayTasks'),
                        style: const TextStyle(color: Colors.grey)),
                  )
                else
                  ..._todayTasks.map(
                    (task) => _buildTaskCard(task, isToday: true),
                  ),
                const SizedBox(height: 24),
                Text(
                  context.tr('careSchedule.upcoming'),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (_upcomingTasks.isEmpty)
                  Text(context.tr('careSchedule.noUpcomingTasks'),
                      style: const TextStyle(color: Colors.grey))
                else
                  ..._upcomingTasks.map(
                    (task) => _buildTaskCard(task, isToday: false),
                  ),
              ],
            ),
    );
  }

  Widget _buildTaskCard(dynamic task, {required bool isToday}) {
    String type = (task['task_type'] ?? '').toString();
    CareTaskType? careTaskType = _parseTaskType(type);
    DateTime? dueDate = _parseTaskDate(task['next_due_at']);
    String plantName = task['plant']?['name'] ?? 'Cây không tên';
    String title = "${_translateTask(type)} - $plantName";
    String time = _formatCareTaskTimeLabel(context, careTaskType, dueDate);
    String? note = _careTaskNote(task, careTaskType);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getColor(type).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(type), color: _getColor(type), size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    note,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        trailing: _buildTrailing(task, careTaskType, isToday),
      ),
    );
  }
}

class _EditNoteDateTimeSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primaryColor;
  final Color darkText;
  final String plantName;
  final String? note;

  const _EditNoteDateTimeSheet({
    required this.initialDateTime,
    required this.firstDate,
    required this.lastDate,
    required this.primaryColor,
    required this.darkText,
    required this.plantName,
    required this.note,
  });

  @override
  State<_EditNoteDateTimeSheet> createState() => _EditNoteDateTimeSheetState();
}

class _EditNoteDateTimeSheetState extends State<_EditNoteDateTimeSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDateTime);
    _selectedTime = TimeOfDay.fromDateTime(widget.initialDateTime);
  }

  DateTime get _selectedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteDatePickerSheet(
        initialDate: _selectedDate,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        primaryColor: widget.primaryColor,
        darkText: widget.darkText,
      ),
    );

    if (pickedDate == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(pickedDate));
  }

  Future<void> _pickTime() async {
    final pickedTime = await showModalBottomSheet<TimeOfDay>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteTimePickerSheet(
        initialTime: _selectedTime,
        primaryColor: widget.primaryColor,
        darkText: widget.darkText,
      ),
    );

    if (pickedTime == null || !mounted) return;
    setState(() => _selectedTime = pickedTime);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final note = widget.note?.trim();

    return SafeArea(
      top: false,
      child: Container(
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
                    Icons.edit_calendar_rounded,
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
                        'Chỉnh sửa ngày giờ',
                        style: TextStyle(
                          color: widget.darkText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ghi chú - ${widget.plantName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.darkText,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ngày',
                    value: _formatDate(_selectedDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.schedule_outlined,
                    label: 'Giờ',
                    value: _formatTime(_selectedTime),
                    onTap: _pickTime,
                  ),
                ),
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
                    onPressed: () => Navigator.pop(context, _selectedDateTime),
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
                    child: const Text('Cập nhật'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAF8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: widget.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
