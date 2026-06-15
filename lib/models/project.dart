import 'user.dart';

enum ProjectStatus { active, onHold, completed }

class Project {
  final String id;
  final String title;
  final String clientName;
  final String description;
  final DateTime dueDate;
  final ProjectStatus status;
  final String priority;
  final double progress; // percentage 0.0 to 1.0
  final int completedTasks;
  final int totalTasks;
  final List<User> teamMembers;

  Project({
    required this.id,
    required this.title,
    required this.clientName,
    required this.description,
    required this.dueDate,
    this.status = ProjectStatus.active,
    this.priority = 'Medium',
    this.progress = 0.0,
    this.completedTasks = 0,
    this.totalTasks = 0,
    this.teamMembers = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var membersList = json['teamMembers'] as List? ?? [];
    return Project(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Sans titre',
      clientName: json['clientName'] ?? 'N/A',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      status: _parseStatus(json['status'] ?? 'Active'),
      priority: json['priority'] ?? 'Medium',
      progress: (json['progress'] ?? 0.0).toDouble(),
      completedTasks: json['completedTasks'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      teamMembers: membersList.map((u) => User.fromJson(u)).toList(),
    );
  }

  static ProjectStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'active': return ProjectStatus.active;
      case 'on_hold':
      case 'onpause':
      case 'en pause': return ProjectStatus.onHold;
      case 'completed': return ProjectStatus.completed;
      default: return ProjectStatus.active;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case ProjectStatus.active: return 'Actif';
      case ProjectStatus.onHold: return 'En pause';
      case ProjectStatus.completed: return 'Terminé';
    }
  }
}
