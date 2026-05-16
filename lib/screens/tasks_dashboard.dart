import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class TasksDashboard extends StatefulWidget {
  const TasksDashboard({Key? key}) : super(key: key);

  @override
  State<TasksDashboard> createState() => _TasksDashboardState();
}

class _TasksDashboardState extends State<TasksDashboard> {
  int _selectedIndex = 0;
  String _selectedPriority = 'All';
  TaskStatus? _selectedStatus;

  List<Task> _allTasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.countUnreadNotifications();
      setState(() => _unreadCount = count);
    } catch (e) {
      print('Erreur notifications: $e');
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      String? pFilter = _selectedPriority == 'All' ? null : _selectedPriority.toUpperCase();
      
      final result = await ApiService.getAllTasks(
        priority: pFilter,
        limit: 100,
      );

      List<Task> tasks = result['tasks'] as List<Task>;

      if (_selectedStatus != null) {
        tasks = tasks.where((t) => t.status == _selectedStatus).toList();
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        tasks = tasks.where((t) => t.title.toLowerCase().contains(query)).toList();
      }

      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isLoading = false;
      });
    }
  }

  void _shareTask(Task task) {
    final text = "📋 ${task.title}\n🔔 Priorité: ${task.getPriorityLabel()}\n⚙️ Statut: ${task.getStatusLabel()}\n📅 Échéance: ${DateFormat('dd MMM yyyy').format(task.dueDate)}\n\nPartagé via TaskFlow";
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
              child: Text(
                "ACTIVE TASKS",
                style: TextStyle(color: Color(0xFF4B5563), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User&background=random'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("My Tasks", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(DateFormat('EEEE, MMM dd').format(DateTime.now()), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Badge(
              label: Text(_unreadCount.toString()),
              isLabelVisible: _unreadCount > 0,
              child: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
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
          hintText: "Search by title...",
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
          filled: true,
          fillColor: const Color(0xFF1A1F26),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildPriorityFilters() {
    final ps = ['All Tasks', 'High', 'Medium', 'Low'];
    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ps.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedPriority == (ps[i] == 'All Tasks' ? 'All' : ps[i]);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPriority = ps[i] == 'All Tasks' ? 'All' : ps[i]);
              _loadTasks();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (ps[i] != 'All Tasks') ...[
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _getPriorityColor(ps[i]))),
                    const SizedBox(width: 8),
                  ],
                  Text(ps[i], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String name) {
    if (name == 'High') return const Color(0xFFEF4444);
    if (name == 'Medium') return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Widget _buildStatusFilters() {
    final ss = [
      {'l': 'All', 'v': null},
      {'l': 'To Do', 'v': TaskStatus.todo},
      {'l': 'In Progress', 'v': TaskStatus.inProgress},
      {'l': 'Completed', 'v': TaskStatus.completed}
    ];
    return Container(
      height: 36,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ss.length,
        itemBuilder: (context, i) {
          final isSelected = _selectedStatus == ss[i]['v'];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedStatus = ss[i]['v'] as TaskStatus?);
              _loadTasks();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB).withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF2A2F36)),
              ),
              child: Text(ss[i]['l'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_allTasks.isEmpty) return const Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _allTasks.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/task_details', arguments: _allTasks[i]).then((_) => _loadTasks()),
        child: _TaskCard(task: _allTasks[i], onShare: _shareTask),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF0F1419),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.check_circle_outline, "Tâches", true, () {}),
          _navItem(Icons.calendar_today_outlined, "Calendrier", false, () {}),
          _navItem(Icons.folder_open_outlined, "Projets", false, () {}),
          _navItem(Icons.person_outline, "Profil", false, () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], size: 22),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: task.getPriorityColor(), width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(task.getPriorityLabel(), style: TextStyle(color: task.getPriorityColor(), fontSize: 10, fontWeight: FontWeight.w900)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: task.getStatusColor().withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(task.getStatusLabel(), style: TextStyle(color: task.getStatusColor(), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 15),
                GestureDetector(onTap: () => onShare(task), child: const Icon(Icons.share_outlined, color: Colors.grey, size: 18)),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(task.description, style: const TextStyle(color: Colors.grey, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
