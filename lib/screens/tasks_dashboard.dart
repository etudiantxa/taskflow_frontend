import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class TasksDashboard extends StatefulWidget {
  const TasksDashboard({Key? key}) : super(key: key);

  @override
  State<TasksDashboard> createState() => _TasksDashboardState();
}

class _TasksDashboardState extends State<TasksDashboard> {
  String _selectedPriority = 'All';
  TaskStatus? _selectedStatus;

  List<Task> _allTasks = [];
  User? _currentUser;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUnreadCount();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String? pFilter = _selectedPriority == 'All' ? null : _selectedPriority.toUpperCase();
      final result = await ApiService.getAllTasks(priority: pFilter, limit: 100);
      List<Task> tasks = (result['tasks'] as List).cast<Task>();

      if (_selectedStatus != null) {
        tasks = tasks.where((t) => t.status == _selectedStatus).toList();
      } else {
        tasks = tasks.where((t) => t.status != TaskStatus.cancelled).toList();
      }

      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        tasks = tasks.where((t) => t.title.toLowerCase().contains(query)).toList();
      }

      tasks.sort((a, b) {
        if (a.status == TaskStatus.expired && b.status != TaskStatus.expired) return -1;
        if (a.status != TaskStatus.expired && b.status == TaskStatus.expired) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareTask(Task task) {
    final text = "📋 ${task.title}\n🔔 Priorité: ${task.getPriorityLabel()}\n⚙️ Statut: ${task.getStatusLabel()}\n📅 Échéance: ${DateFormat('dd MMM yyyy').format(task.dueDate)}";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildPriorityFilters(),
            _buildStatusFilters(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 25, 16, 10),
              child: Text("TASKS", style: TextStyle(color: Color(0xFF4B5563), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed('/add_task');
          if (result == true) _loadTasks();
        },
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
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
        } catch (_) {
          avatarImage = const NetworkImage('https://ui-avatars.com/api/?name=User');
        }
      }
    } else {
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${_currentUser?.nom ?? "User"}&background=random');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: avatarImage),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("My Tasks", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Manage your productivity", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Badge(
              label: Text(_unreadCount.toString()),
              isLabelVisible: _unreadCount > 0,
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications').then((_) => _loadUnreadCount()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => _loadTasks(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Rechercher...",
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          filled: true,
          fillColor: const Color(0xFF1A1F26),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    final ps = ['All', 'High', 'Medium', 'Low'];
    return Container(
      height: 38, margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ps.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedPriority == ps[i];
          return GestureDetector(
            onTap: () { setState(() => _selectedPriority = ps[i]); _loadTasks(); },
            child: Container(
              margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20)),
              child: Text(ps[i], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    final ss = [{'l': 'All', 'v': null}, {'l': 'To Do', 'v': TaskStatus.todo}, {'l': 'In Progress', 'v': TaskStatus.inProgress}, {'l': 'Completed', 'v': TaskStatus.completed}, {'l': 'Expired', 'v': TaskStatus.expired}];
    return Container(
      height: 36, margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ss.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedStatus == ss[i]['v'];
          return GestureDetector(
            onTap: () { setState(() => _selectedStatus = ss[i]['v'] as TaskStatus?); _loadTasks(); },
            child: Container(
              margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB).withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2A2F36))),
              child: Text(ss[i]['l'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    if (_allTasks.isEmpty) return const Center(child: Text("Aucune tâche", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), itemCount: _allTasks.length,
      itemBuilder: (context, i) {
        final task = _allTasks[i];
        return Dismissible(
          key: Key(task.id), direction: DismissDirection.endToStart,
          onDismissed: (_) async { await ApiService.deleteTask(int.parse(task.id)); setState(() => _allTasks.removeAt(i)); },
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: Colors.white)),
          child: GestureDetector(onTap: () => Navigator.of(context).pushNamed('/task_details', arguments: task).then((_) => _loadTasks()), child: _TaskCard(task: task, onShare: _shareTask)),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF0F1419), shape: const CircularNotchedRectangle(), notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.task_alt, "Tasks", true, () {}),
          _navItem(Icons.calendar_month, "Calendar", false, () => Navigator.pushReplacementNamed(context, '/calendar')),
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

class _TaskCard extends StatelessWidget {
  final Task task;
  final Function(Task) onShare;
  const _TaskCard({required this.task, required this.onShare});
  @override
  Widget build(BuildContext context) {
    bool isExpired = task.status == TaskStatus.expired;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: isExpired ? Colors.red : task.getPriorityColor(), width: 4))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text(isExpired ? "EXPIRÉE" : task.getPriorityLabel(), style: TextStyle(color: isExpired ? Colors.red : task.getPriorityColor(), fontSize: 10, fontWeight: FontWeight.w900)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: task.getStatusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(task.getStatusLabel(), style: TextStyle(color: task.getStatusColor(), fontSize: 9, fontWeight: FontWeight.bold))), const SizedBox(width: 15), GestureDetector(onTap: () => onShare(task), child: const Icon(Icons.share_outlined, color: Colors.grey, size: 18))]),
            const SizedBox(height: 12),
            Text(task.title, style: TextStyle(color: isExpired ? Colors.grey : Colors.white, fontSize: 17, fontWeight: FontWeight.bold, decoration: isExpired ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 20),
            Row(children: [Icon(Icons.calendar_today, size: 14, color: isExpired ? Colors.red : Colors.grey), const SizedBox(width: 8), Text("Due: ${DateFormat('dd MMM').format(task.dueDate)}", style: TextStyle(color: isExpired ? Colors.red : Colors.grey, fontSize: 12))])
          ],
        ),
      ),
    );
  }
}
