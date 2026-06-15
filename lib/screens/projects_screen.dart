import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../services/session_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  User? _currentUser;
  bool _isLoading = false;

  final List<Project> _projects = [
    Project(
      id: '1',
      title: 'Refonte Site Web',
      clientName: 'Digital Ocean',
      description: 'Refonte complète du site corporate',
      dueDate: DateTime.now().add(const Duration(days: 30)),
      status: ProjectStatus.active,
      progress: 0.75,
      completedTasks: 12,
      totalTasks: 18,
    ),
    Project(
      id: '2',
      title: 'Application Mobile',
      clientName: 'FinTech Corp',
      description: 'Développement MVP iOS/Android',
      dueDate: DateTime.now().add(const Duration(days: 45)),
      status: ProjectStatus.onHold,
      progress: 0.32,
      completedTasks: 8,
      totalTasks: 25,
    ),
    Project(
      id: '3',
      title: 'Campagne Marketing',
      clientName: 'Internal Project',
      description: 'Lancement Q4',
      dueDate: DateTime.now().add(const Duration(days: 15)),
      status: ProjectStatus.active,
      progress: 0.90,
      completedTasks: 18,
      totalTasks: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await SessionService.getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildStatCards(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Projects", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("View all", style: TextStyle(color: Color(0xFF2563EB)))),
                ],
              ),
              const SizedBox(height: 10),
              _buildProjectList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_project'),
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
        } catch (_) {
          avatarImage = const NetworkImage('https://ui-avatars.com/api/?name=User');
        }
      }
    } else {
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${_currentUser?.nom ?? "User"}&background=random');
    }

    return Row(
      children: [
        const Icon(Icons.grid_view_rounded, color: Color(0xFF2563EB), size: 28),
        const SizedBox(width: 12),
        const Text("TaskFlow Pro", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        CircleAvatar(radius: 18, backgroundImage: avatarImage),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(child: _statCard("Total Projects", "24", const Color(0xFF1A1F26), Colors.white70)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Completed", "18", const Color(0xFF1A1F26), const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _statCard("In Progress", "6", const Color(0xFF1A1F26), const Color(0xFF2563EB))),
      ],
    );
  }

  Widget _statCard(String label, String value, Color bgColor, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    return Column(
      children: _projects.map((p) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/project_details', arguments: p),
        child: _projectCard(p),
      )).toList(),
    );
  }

  Widget _projectCard(Project p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(p.getStatusLabel(), style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text("Client: ${p.clientName}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progress", style: TextStyle(color: Colors.grey, fontSize: 11)),
              Text("${(p.progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: p.progress,
              backgroundColor: const Color(0xFF0F1419),
              color: const Color(0xFF2563EB),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Colors.grey, size: 14),
              const SizedBox(width: 6),
              Text("${p.completedTasks}/${p.totalTasks} tâches", style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const Spacer(),
              _buildTeamAvatars(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatars() {
    return SizedBox(
      width: 80,
      height: 24,
      child: Stack(
        children: [
          Positioned(left: 0, child: _smallAvatar('https://i.pravatar.cc/150?u=1')),
          Positioned(left: 15, child: _smallAvatar('https://i.pravatar.cc/150?u=2')),
          Positioned(
            left: 30, 
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: const Color(0xFF0F1419), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A1F26), width: 1.5)),
              child: const Center(child: Text("+3", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallAvatar(String url) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1A1F26), width: 1.5),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
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
          _navItem(Icons.folder_outlined, "Projects", true, () {}),
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
