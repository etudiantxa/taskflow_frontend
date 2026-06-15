import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  bool _isLoading = true;
  int _total = 0;
  int _completed = 0;
  int _inProgress = 0;
  int _todo = 0;
  int _expired = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getAllTasks(limit: 500);
      final List<Task> tasks = (result['tasks'] as List).cast<Task>();
      
      setState(() {
        _total = tasks.length;
        _completed = tasks.where((t) => t.status == TaskStatus.completed).length;
        _inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
        _todo = tasks.where((t) => t.status == TaskStatus.todo).length;
        _expired = tasks.where((t) => t.status == TaskStatus.expired).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Insights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(),
                const SizedBox(height: 30),
                const Text("Statistiques détaillées", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildStatItem("À faire", _todo, const Color(0xFF60A5FA), Icons.list_alt),
                    _buildStatItem("En cours", _inProgress, const Color(0xFF2563EB), Icons.trending_up),
                    _buildStatItem("Terminées", _completed, const Color(0xFF10B981), Icons.check_circle_outline),
                    _buildStatItem("Expirées", _expired, const Color(0xFFEF4444), Icons.error_outline),
                  ],
                ),
              ],
            ),
          ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_task'),
        backgroundColor: const Color(0xFF2563EB),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildOverviewCard() {
    double completionRate = _total == 0 ? 0 : (_completed / _total) * 100;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Productivité globale", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("${completionRate.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Text("Vous avez terminé $_completed tâches sur $_total", style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
          _navItem(Icons.calendar_month, "Calendar", false, () => Navigator.pushReplacementNamed(context, '/calendar')),
          const SizedBox(width: 40),
          _navItem(Icons.bar_chart_rounded, "Insights", true, () {}),
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
