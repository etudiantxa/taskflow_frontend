import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Task> _allTasks = [];
  bool _isLoading = false;
  User? _currentUser;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await SessionService.getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.countUnreadNotifications();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getAllTasks(limit: 200);
      if (mounted) {
        setState(() {
          _allTasks = (result['tasks'] as List).cast<Task>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _allTasks.where((task) {
      return task.dueDate.year == day.year &&
          task.dueDate.month == day.month &&
          task.dueDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarCard(),
                    const SizedBox(height: 24),
                    _buildDayHeader(),
                    const SizedBox(height: 16),
                    _buildTaskList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_task');
          if (result == true) _loadData();
        },
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    ImageProvider avatarImage;
    if (_currentUser?.photo != null && _currentUser!.photo!.isNotEmpty) {
      if (_currentUser!.photo!.startsWith('http')) {
        avatarImage = NetworkImage(_currentUser!.photo!);
      } else {
        try {
          avatarImage = MemoryImage(base64Decode(_currentUser!.photo!));
        } catch (e) {
          avatarImage = const NetworkImage('https://ui-avatars.com/api/?name=User');
        }
      }
    } else {
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${_currentUser?.nom ?? "User"}&background=random');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          const Text(
            "Calendrier",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(radius: 18, backgroundImage: avatarImage),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay).capitalize(),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.grey),
                    onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.grey),
                    onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    const weekdays = ['LU', 'MA', 'ME', 'JE', 'VE', 'SA', 'DI'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((d) => Text(d, style: const TextStyle(color: Color(0xFF4B5563), fontSize: 11, fontWeight: FontWeight.bold))).toList(),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10),
          itemCount: daysInMonth + (firstWeekday - 1),
          itemBuilder: (context, i) {
            if (i < firstWeekday - 1) return const SizedBox.shrink();
            final day = i - (firstWeekday - 2);
            final date = DateTime(_focusedDay.year, _focusedDay.month, day);
            final isSelected = _selectedDay.year == date.year && _selectedDay.month == date.month && _selectedDay.day == date.day;
            final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
            final hasTasks = _getTasksForDay(date).isNotEmpty;

            return GestureDetector(
              onTap: () => setState(() => _selectedDay = date),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected ? Border.all(color: const Color(0xFF2563EB), width: 1) : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(color: isSelected ? Colors.white : (isToday ? const Color(0xFF2563EB) : Colors.white70), fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                    ),
                  ),
                  if (hasTasks && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDayHeader() {
    String dayLabel = DateFormat('EEEE, d MMMM', 'fr_FR').format(_selectedDay);
    bool isToday = _selectedDay.year == DateTime.now().year && _selectedDay.month == DateTime.now().month && _selectedDay.day == DateTime.now().day;
    
    return Row(
      children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          isToday ? "Aujourd'hui, ${DateFormat('d MMMM', 'fr_FR').format(_selectedDay)}" : dayLabel,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay);
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        child: const Column(
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 12),
            Text("Aucune tâche pour ce jour", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        final task = tasks[i];
        return _buildTaskItem(task);
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: task.getPriorityColor().withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(task.priority.name.toUpperCase(), style: TextStyle(color: task.getPriorityColor(), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey, size: 14),
                    const SizedBox(width: 6),
                    Text(DateFormat('HH:mm').format(task.dueDate), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: task.getStatusColor(), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(task.getStatusLabel(), style: TextStyle(color: task.getStatusColor(), fontSize: 12)),
                    const Spacer(),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF0F1419),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.task_alt, "Tasks", false, () => Navigator.pushReplacementNamed(context, '/dashboard')),
          _navItem(Icons.calendar_month, "Calendar", true, () {}),
          const SizedBox(width: 40),
          _navItem(Icons.folder_outlined, "Projects", false, () => Navigator.pushReplacementNamed(context, '/projects')),
          _navItem(Icons.person_outline, "Profile", false, () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
