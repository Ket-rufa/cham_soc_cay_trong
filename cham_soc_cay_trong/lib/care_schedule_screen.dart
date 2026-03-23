import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cham_soc_cay_trong/config.dart';

class CareScheduleScreen extends StatefulWidget {
  const CareScheduleScreen({super.key});

  @override
  State<CareScheduleScreen> createState() => _CareScheduleScreenState();
}

class _CareScheduleScreenState extends State<CareScheduleScreen> {
  bool _isLoading = true;
  List _todayTasks = [];
  List _upcomingTasks = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${Config.apiUrl}/schedules');
      final response = await http.get(url);

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
      final response = await http.post(url);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã hoàn thành thay đổi!'), backgroundColor: Colors.green),
          );
          _fetchSchedules(); // Tải lại danh sách
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _translateTask(String task) {
    if (task == 'water') return 'Tưới nước';
    if (task == 'fertilize') return 'Bón phân';
    if (task == 'prune') return 'Cắt tỉa';
    return task;
  }

  IconData _getIcon(String task) {
    if (task == 'water') return Icons.water_drop_outlined;
    if (task == 'fertilize') return Icons.eco_outlined;
    if (task == 'prune') return Icons.content_cut;
    return Icons.check_circle_outline;
  }

  Color _getColor(String task) {
    if (task == 'water') return Colors.blue;
    if (task == 'fertilize') return Colors.green;
    if (task == 'prune') return Colors.orange;
    return Colors.grey;
  }

  String _formatTaskTime(String dateStr, String type, bool isToday) {
    if (dateStr.isEmpty) return isToday ? "Hôm nay" : "";
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      String datePart = isToday ? "Hôm nay" : "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
      
      if (type == 'water' || type == 'mist') {
        int hour = dt.hour;
        String amPm = hour >= 12 ? 'PM' : 'AM';
        int hour12 = hour % 12;
        if (hour12 == 0) hour12 = 12;
        String timePart = "${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm";
        return "$datePart, $timePart";
      } else {
        return datePart;
      }
    } catch (_) {
      return isToday ? "Hôm nay" : dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F3),
      appBar: AppBar(
        title: const Text("Lịch chăm sóc"),
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
                const Text(
                  "Nhiệm vụ hôm nay",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (_todayTasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text("Hôm nay không có nhiệm vụ nào.", style: TextStyle(color: Colors.grey)),
                  )
                else
                  ..._todayTasks.map((task) => _buildTaskCard(task, isToday: true)).toList(),
                
                const SizedBox(height: 24),
                
                const Text(
                  "Sắp tới",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (_upcomingTasks.isEmpty)
                  const Text("Chưa có nhiệm vụ sắp tới.", style: TextStyle(color: Colors.grey))
                else
                  ..._upcomingTasks.map((task) => _buildTaskCard(task, isToday: false)).toList(),
              ],
            ),
    );
  }

  Widget _buildTaskCard(dynamic task, {required bool isToday}) {
    String type = task['task_type'];
    String plantName = task['plant']?['name'] ?? 'Cây không tên';
    String title = "${_translateTask(type)} - $plantName";
    String time = _formatTaskTime(task['next_due_at'] ?? '', type, isToday);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getColor(type).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(type), color: _getColor(type), size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(time, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
        trailing: isToday 
          ? InkWell(
              onTap: () => _completeTask(task['id']),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Icon(Icons.check, size: 20, color: Colors.green),
              ),
            ) 
          : null,
      ),
    );
  }
}
