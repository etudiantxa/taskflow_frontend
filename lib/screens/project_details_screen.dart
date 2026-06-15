import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/task.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Project Details",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.project.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.project.getStatusLabel(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "Client: ${widget.project.clientName}",
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 30),
            _buildProgressCard(),
            const SizedBox(height: 30),
            _buildSectionHeader("TEAM"),
            const SizedBox(height: 16),
            _buildTeamRow(),
            const SizedBox(height: 30),
            _buildSectionHeader("TASKS", action: "View all"),
            const SizedBox(height: 16),
            _buildTaskList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFB4C6FC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Color(0xFF1E3A8A), size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Progression Globale",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                "${(widget.project.progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.project.progress,
              backgroundColor: const Color(0xFF0F1419),
              color: const Color(0xFF2563EB),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text(
                "${widget.project.completedTasks}/${widget.project.totalTasks} tasks completed",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: () {},
            child: Text(
              action,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamRow() {
    return Row(
      children: [
        _buildOverlappingAvatars(),
      ],
    );
  }

  Widget _buildOverlappingAvatars() {
    return SizedBox(
      height: 40,
      width: 150,
      child: Stack(
        children: [
          Positioned(left: 0, child: _teamAvatar('https://i.pravatar.cc/150?u=a')),
          Positioned(left: 25, child: _teamAvatar('https://i.pravatar.cc/150?u=b')),
          Positioned(left: 50, child: _teamAvatar('https://i.pravatar.cc/150?u=c')),
          Positioned(left: 75, child: _teamAvatar('https://i.pravatar.cc/150?u=d')),
          Positioned(
            left: 100,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F36),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F1419), width: 2),
              ),
              child: const Center(
                child: Text(
                  "+2",
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamAvatar(String url) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0F1419), width: 2),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        _buildTaskItem(
          "Finaliser le rapport annuel",
          "HIGH",
          "Completed",
          const Color(0xFFEF4444),
          Icons.check_circle,
          const Color(0xFF2563EB),
        ),
        _buildTaskItem(
          "Réunion d'équipe",
          "MEDIUM",
          "In Progress",
          const Color(0xFFF59E0B),
          Icons.radio_button_checked,
          const Color(0xFF2563EB).withOpacity(0.4),
        ),
        _buildTaskItem(
          "Déjeuner Client",
          "LOW",
          "To Do",
          const Color(0xFF10B981),
          Icons.radio_button_off,
          Colors.grey[800]!,
        ),
      ],
    );
  }

  Widget _buildTaskItem(
    String title,
    String priority,
    String status,
    Color priorityColor,
    IconData statusIcon,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(color: priorityColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.grid_view_rounded, "Dashboard", false),
          _navItem(Icons.checklist_rounded, "Tasks", false),
          _navItem(Icons.calendar_today_outlined, "Calendar", false),
          _navItem(Icons.folder_rounded, "Projects", true),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
